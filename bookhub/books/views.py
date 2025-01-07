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
    """⬇️ Downloads an ePub book from Library Genesis"""

    # Uncomment if you need authenticated access
    # permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        download_url = request.query_params.get('url', '').strip()
        title = request.query_params.get('title', '').strip()
        author = request.query_params.get('author', '').strip()

        if not download_url or not title or not author:
            return Response({'error': 'Title, author, and download URL are required'}, status=400)

        try:
            # Step 1: Fetch the intermediate page
            logger.info(f"Fetching intermediate page: {download_url}")
            page_response = requests.get(download_url, allow_redirects=True)
            if page_response.status_code != 200:
                logger.error(f"Failed to fetch intermediate page. HTTP status: {page_response.status_code}")
                return Response({'error': 'Failed to fetch book download page'}, status=500)

            # Step 2: Parse the HTML to find the "GET" link
            soup = BeautifulSoup(page_response.text, 'html.parser')
            get_link = soup.find('a', string="GET")  # Find the link with text "GET"

            if not get_link or not get_link.get('href'):
                logger.error("Direct GET download link not found on the intermediate page.")
                return Response({'error': 'Unable to locate the direct book download link'}, status=500)

            direct_link = get_link['href']
            if not direct_link.startswith('http'):
                base_url = download_url.rsplit('/', 1)[0]
                direct_link = f"{base_url}/{direct_link}"

            # Step 3: Send a GET request to the extracted direct link
            logger.info(f"Downloading file from: {direct_link}")
            file_response = requests.get(direct_link, stream=True)
            if file_response.status_code != 200:
                logger.error(f"Failed to download book. HTTP status: {file_response.status_code}")
                return Response({'error': 'Failed to download the book from the direct link'}, status=500)

            # Sanitize filename to avoid invalid characters
            def sanitize_filename(filename):
                return re.sub(r'[<>:"/\\|?*]', '_', filename)

            safe_title = sanitize_filename(title)
            safe_author = sanitize_filename(author)

            # Prepare file path
            local_dir = os.path.join(settings.MEDIA_ROOT, 'offline_books')
            os.makedirs(local_dir, exist_ok=True)
            local_path = os.path.join(local_dir, f"{safe_title.replace(' ', '_')}_{safe_author.replace(' ', '_')}.epub")

            # Save the file in chunks to handle large files
            with open(local_path, 'wb') as file:
                for chunk in file_response.iter_content(chunk_size=8192):  # Save in 8KB chunks
                    file.write(chunk)

            # Create a book entry in the database
            book = Book.objects.create(
                user=user,
                title=title,
                author=author,
                content=f'offline_books/{os.path.basename(local_path)}',  # Assuming you use a FileField
                file_type='epub',
                file_size=f'{os.path.getsize(local_path) / 1024:.2f} KB'  # Size in KB
            )

            # Trigger asynchronous task for further processing
            download_book.delay(download_url, local_path)

            # Return the response with book details
            return Response({
                'message': 'Book downloaded successfully',
                'book_id': book.id,
                'file_path': book.content.url if hasattr(book.content, 'url') else book.content
            }, status=201)

        except Exception as e:
            logger.error(f"Error downloading book: {str(e)}", exc_info=True)
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
        
