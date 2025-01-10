from django.shortcuts import render
import requests,os,logging, re 
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Book
from users.models import  CustomUser
from bookhub.celery import download_book
from django.core.cache import cache
from bs4 import BeautifulSoup
from rest_framework import status, permissions
from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from .utils import save_chapters_to_db
from django.conf import settings
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from urllib.parse import urlparse
from playwright.sync_api import sync_playwright

# Use requests to send an HTTP request to Library Genesis.
# Extract book information (title, author, download link, etc.) from the response.
# Return the response to the frontend in JSON format.


# Configure logging
logging.basicConfig(level=logging.ERROR, format='%(asctime)s - %(levelname)s - %(message)s')

from rest_framework.views import APIView
from rest_framework.response import Response
from bs4 import BeautifulSoup
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from django.core.cache import cache
import logging
import re


class BookSearchView(APIView):
    """🔍 Allows users to search for books on Library Genesis with robust error handling."""

    SITE_MIRRORS = [
        'https://libgen.li',  # Updated mirror URL base
    ]
    TIMEOUT = 10  # Timeout for each request (in seconds)
    RETRY_COUNT = 3  # Number of retries for each mirror

    def get(self, request):
        query = request.query_params.get('q', '').strip()  # Extract query parameter
        if not query:
            return Response({'error': 'Search query is required'}, status=400)

        # Generate a unique cache key
        cache_key = f'search_results_{query}_{hash(tuple(self.SITE_MIRRORS))}'
        cached_results = cache.get(cache_key)

        if cached_results:
            logging.info("Serving cached results")
            return Response({'results': cached_results}, status=200)

        books = []  # To store parsed book details
        session = requests.Session()

        # Configure retry mechanism
        retries = Retry(
            total=self.RETRY_COUNT,
            backoff_factor=1,
            status_forcelist=[500, 502, 503, 504]
        )
        session.mount('https://', HTTPAdapter(max_retries=retries))

        response = None

        # Iterate through mirrors
        for mirror in self.SITE_MIRRORS:
            url = (
                f"{mirror}/index.php?"
                f"req={query}&"
                "columns[]=t&columns[]=a&columns[]=s&columns[]=y&columns[]=p&columns[]=i&"
                "objects[]=f&objects[]=e&objects[]=s&objects[]=a&objects[]=p&objects[]=w&"
                "topics[]=l&topics[]=c&topics[]=f&topics[]=a&topics[]=m&topics[]=r&topics[]=s&"
                "res=100&filesuns=all"
            )
            try:
                logging.info(f"Trying mirror: {url}")
                response = session.get(url, timeout=self.TIMEOUT)
                if response.status_code == 200:
                    logging.info(f"Mirror succeeded: {mirror}")
                    break
            except requests.RequestException as e:
                logging.error(f"Error with mirror {mirror}: {e}")
                continue

        if not response or response.status_code != 200:
            logging.error("Failed to fetch data from all Library Genesis mirrors")
            return Response({'error': 'Unable to fetch results. Please try again later.'}, status=500)

        # Parse the response
        try:
            soup = BeautifulSoup(response.content, 'html.parser')
            table = soup.find('table', {'id': 'tablelibgen'})  # Look for table with ID 'tablelibgen'
            if not table:
                logging.error("No results table found on the page")
                return Response({'error': 'No results found'}, status=404)

            rows = table.find_all('tr')[1:]  # Skip header row
            for row in rows:
                columns = row.find_all('td')
                if len(columns) > 8:  # Ensure sufficient columns
                    file_type = columns[6].text.strip()
                    # if file_type.lower() == 'epub':  # Filter for ePub files only
                    book_info = {
                            'id': columns[0].text.strip(),
                            'author': columns[1].text.strip(),
                            'title': columns[2].a.text.strip() if columns[2].a else 'N/A',
                            'publisher': columns[3].text.strip(),
                            'year': columns[4].text.strip(),
                            'language': columns[5].text.strip(),
                            'file_type': columns[6].text.strip(),
                            'file_size': float(re.sub(r'[^0-9.]', '', columns[7].text.strip()) or 0),  # Ensure numeric value
                            'download_link': columns[8].a['href'] if columns[8].a else None
                        }
                    books.append(book_info)
        except Exception as e:
            logging.error(f"Error while parsing response: {e}", exc_info=True)
            return Response({'error': 'Failed to parse search results'}, status=500)

        # Cache the results
        cache.set(cache_key, books, timeout=3600)  # Cache for 1 hour
        logging.info("Search results cached successfully")

        return Response({'results': books}, status=200)


logger = logging.getLogger(__name__)


class BookDownloadView(APIView):
    """⬇️ Handles the download of an ePub book from Library Genesis"""

    def get(self, request):
        user = request.user
        # Extract query parameters from the request
        download_url = request.query_params.get('url', '').strip()
        title = request.query_params.get('title', '').strip()
        author = request.query_params.get('author', '').strip()

        # Validate the required inputs
        if not download_url or not title :
            return Response({'error': 'Title, and download URL are required'}, status=400)

        # Validate and sanitize the provided download URL
        parsed_url = urlparse(download_url)
        if not parsed_url.scheme or not parsed_url.netloc:
            logger.error(f"Malformed URL: {download_url}")
            return Response({'error': 'Invalid download URL provided'}, status=400)

        try:
            # Use Playwright to handle the intermediate page and extract the direct download link
            logger.info(f"Opening intermediate page and triggering download for URL: {download_url}")
            with sync_playwright() as p:
                browser = p.chromium.launch(headless=True)
                context = browser.new_context(accept_downloads=True)
                page = context.new_page()

                # Navigate to the provided URL
                page.goto(download_url)

                # Wait for the "GET" button to appear and click it to trigger download
                logger.info("Waiting for 'GET' button to appear on the page...")
                page.wait_for_selector('a:text("GET")', timeout=10000)
                logger.info("Clicking the 'GET' button to initiate download...")

                # Use expect_download to handle the file download
                with page.expect_download() as download_info:
                    page.click('a:text("GET")')  # Trigger the file download
                
                # Get the downloaded file from the Playwright context
                download = download_info.value
                download_path = download.path()

                # Sanitize the file name to avoid invalid characters
                def sanitize_filename(filename):
                    return re.sub(r'[<>:"/\\|?*]', '_', filename)

                safe_title = sanitize_filename(title)
                safe_author = sanitize_filename(author)

                # Create the local directory to store the file
                local_dir = os.path.join(settings.MEDIA_ROOT, 'offline_books')
                os.makedirs(local_dir, exist_ok=True)

                # Define the local file path
                local_path = os.path.join(
                    local_dir,
                    f"{safe_title.replace(' ', '_')}_{safe_author.replace(' ', '_')}.epub"
                )

                # Move the downloaded file to the desired location
                os.rename(download_path, local_path)

                browser.close()

            # Save the downloaded file details in the database
            logger.info("Saving downloaded book details to the database...")
            book = Book.objects.create(
                user=user,
                title=title,
                author=author,
                content=f'offline_books/{os.path.basename(local_path)}',  # Assuming a FileField is used
                file_type='epub',
                file_size=f'{os.path.getsize(local_path) / 1024:.2f} KB'  # Convert file size to KB
            )

            # Optional: Trigger an asynchronous task for further processing (e.g., metadata extraction)
            download_book.delay(download_url, local_path)

            # Return success response with book details
            return Response({
                'message': 'Book downloaded successfully',
                'book_id': book.id,
                'file_path': book.content.url if hasattr(book.content, 'url') else book.content
            }, status=201)

        except requests.exceptions.RequestException as e:
            # Handle HTTP request errors
            logger.error(f"HTTP request error: {str(e)}")
            return Response({'error': f'HTTP request failed: {str(e)}'}, status=500)
        except OSError as e:
            # Handle file-related errors
            logger.error(f"File handling error: {str(e)}")
            return Response({'error': f'File handling error: {str(e)}'}, status=500)
        except Exception as e:
            # Handle unexpected errors
            logger.error(f"Unexpected error: {str(e)}", exc_info=True)
            return Response({'error': f'An error occurred while downloading the book: {str(e)}'}, status=500)


# ePub Parser: Use python-epub-reader to parse and render ePub files.
# Book Reader API: Provide API endpoints for the user to read the book.
# Frontend UI: Use JavaScript to load the ePub file and present it on the user interface.


class BookReadView(APIView):
    """📖 Allows users to read an ePub book with lazy loading and pagination."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, book_id):
        user = request.user
        # Fetch the book and ensure it's owned by the logged-in user
        book = get_object_or_404(Book, id=book_id, user=user)

        # If chapters aren't already extracted, extract and save them
        if not book.chapters.exists():
            save_chapters_to_db(book)

        # Chapter-level pagination
        chapter_page = int(request.GET.get('chapter', 1))
        chapters_per_page = int(request.GET.get('chapters_per_page', 1))


        # Retrieve chapters based on pagination
        total_chapters = book.chapters.count()
        if chapter_page < 1 or chapters_per_page < 1:
            return Response({'error': 'Invalid chapter page or chapters per page value.'}, status=400)

        start_index = (chapter_page - 1) * chapters_per_page
        end_index = start_index + chapters_per_page

        # Handle out-of-bounds indices
        if start_index >= total_chapters:
            return Response({'error': 'Chapter page out of range.'}, status=404)

        chapter_queryset = book.chapters.all()[start_index:end_index]

        chapter_list=[]
        for chapter in chapter_queryset:
            # Lazy loading within a chapter
            section_page = int(request.GET.get('section', 1))
            section_size = int(request.GET.get('section_size', 500))  # Number of characters per section
            chapter_content = chapter.content

            # Calculate start and end indices for the section
            start = (section_page - 1) * section_size
            end = start + section_size
            section_content = chapter_content[start:end]

            chapter_list.append({
                "chapter_title": chapter.title,
                "section_content": section_content,
                "total_sections": (len(chapter_content) + section_size - 1) // section_size,  # Total sections in the chapter
                "current_section_page": section_page,
            })


        # Prepare the response
        response_data = {
            "book_title": book.title,
            "total_chapters": total_chapters,
            "current_chapter_page": chapter_page,
            "chapters": chapter_list,
            "total_chapter_pages": (total_chapters + chapters_per_page - 1) // chapters_per_page,
        }
        return Response(response_data, status=200)

        

class BookDeleteView(APIView):
    """ Deletes a downloaded book"""

    permission_classes = [permissions.IsAuthenticated]

    def delete(self,request,book_id):
        user= request.user
        book= get_object_or_404(Book,id=book_id,user=user)

        try:
            #delete local file if it exists
            if book.local_path and os.path.exists(book.local_path):
                os.remove(book.local_path)

            #delete book record from db
            book.delete()

            return Response({'message': 'Book deleted successfully'},status=200)
        
        except Exception as e:
            return Response({'error':f"An error ocurred while deleting the book:{str(e)}"},status=500)
        
