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
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.chrome.options import Options
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from time import sleep
from .serializers import BookSerializer




# Use requests to send an HTTP request to Library Genesis.
# Extract book information (title, author, download link, etc.) from the response.
# Return the response to the frontend in JSON format.


# Configure logging
logging.basicConfig(level=logging.ERROR, format='%(asctime)s - %(levelname)s - %(message)s')

# from rest_framework.views import APIView
# from rest_framework.response import Response
# from bs4 import BeautifulSoup
# import requests
# from requests.adapters import HTTPAdapter
# from urllib3.util.retry import Retry
# from django.core.cache import cache
# import logging
# import re


class BookSearchView(APIView):
    """🔍 Allows users to search for books on Library Genesis with robust error handling."""

    SITE_MIRRORS = [        
        
        'https://libgen.li',  # Updated mirror URL base
        'https://libgen.is',
    ]
    TIMEOUT = 10  # Timeout for each request (in seconds)
    RETRY_COUNT = 3  # Number of retries for each mirror

    def get(self, request):
        query = request.query_params.get('q', '').strip()  # Extract query parameter
        if not query:
            return Response({'error': 'Search query is required'}, status=400)

                # Filter books that match the search query and are of type 'epub'
        books = Book.objects.filter(
            file_type='epub',  # Only ePub files
            title__icontains=query  # Case-insensitive search in the title
        )

        # Serialize the filtered books
        serializer = BookSerializer(books, many=True)

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
                # Ensure `columns` contains all <td> elements in the row
                
                if len(columns) > 8:  # Ensure there are enough columns
                    try:
                        # Extract title from the first <td>
                        title_author_td = columns[0]
                        title = title_author_td.find('a').text.strip() if title_author_td.find('a') else 'N/A'

                        # Extract author
                        author = columns[1].text.strip() if len(columns) > 1 else 'Unknown'

                        # Extract publisher, year, language
                        publisher = columns[2].text.strip() if len(columns) > 2 else 'Unknown'
                        year = columns[3].text.strip() if len(columns) > 3 else 'Unknown'
                        language = columns[4].text.strip() if len(columns) > 4 else 'Unknown'

                        # Extract file size and file type
                        file_size_td = columns[6]
                        file_size_match = re.search(r'([\d.]+)\s?(KB|MB|GB)', file_size_td.text.strip())
                        file_size = 0.0
                        if file_size_match:
                            file_size_value = float(file_size_match.group(1))  # Extract numeric part
                            file_size_unit = file_size_match.group(2)  # Extract unit (KB, MB, GB)
                            if file_size_unit == 'KB':
                                file_size = file_size_value / 1024  # Convert KB to MB
                            elif file_size_unit == 'GB':
                                file_size = file_size_value * 1024  # Convert GB to MB
                            else:
                                file_size = file_size_value  # MB remains as is

                        file_type_td = columns[7]
                        file_type = file_type_td.text.strip() if len(columns) > 7 else 'Unknown'

                        # Extract the libgen download link
                        
                        download_td = columns[8]
                        nobr_tag = download_td.find('nobr')
                        
                        if nobr_tag:
                            # Find the first 'a' tag within the 'nobr' tag 
                            first_a_tag = nobr_tag.find('a') 

                            if first_a_tag:
                                # Extract the 'href' attribute from the first 'a' tag
                                libgen_link = first_a_tag.get('href')
                            else:
                                libgen_link = None
                        else:
                            libgen_link = None

                        # libgen_link = None
                        # nobr = download_td.find('nobr')
                        # download_links = nobr.find_all('a')
                        # for link in download_links:
                        #     # Check if the 'data-original-title' attribute equals 'libgen' (case-insensitive)
                        #     if link.get('data-original-title', '').strip().lower() == 'libgen':
                        #         libgen_link = link.get('href')  # Extract the href attribute
                        #         break  # Stop after finding the first libgen link

                        # Construct the book info dictionary
                        book_info = {
                            'title': title,
                            'author': author,
                            'publisher': publisher,
                            'year': year,
                            'language': language,
                            'file_type': file_type,
                            'file_size': file_size,  # Always in MB
                            'download_link': libgen_link
                        }

                        print("Parsed Book Info:", book_info)
                        books.append(book_info)  # Only append if parsing succeeds
                    except Exception as e:
                        logging.error(f"Error parsing book info: {e}")
                        continue

        except Exception as e:
            logging.error(f"Error while parsing response: {e}", exc_info=True)
            return Response({'error': 'Failed to parse search results'}, status=500)

        # Cache the results
        cache.set(cache_key, books, timeout=3600)  # Cache for 1 hour
        logging.info("Search results cached successfully")

        return Response({'results': books}, status=200)


logger = logging.getLogger(__name__)

class BookDownloadView(APIView):
    """
    Handles the download of an ePub book from Library Genesis.

    This view fetches an intermediate page, triggers the final download,
    saves the book to the database, and schedules further processing with a Celery task.
    """
    @staticmethod
    def fetch_and_download_book(libgen_link):
        """
        Fetch the intermediate page, locate the 'GET' button, and download the ePub file.

        Args:
            libgen_link (str): The URL of the intermediate page with the 'GET' button.

        Returns:
            str: The local path of the downloaded file.

        Raises:
            Exception: If any step in the process fails.
        """
        try:
            # Start a session for HTTP requests
            session = requests.Session()

            # Full intermediate page URL
            intermediate_url = f"https://libgen.li{libgen_link}"

            # Fetch the intermediate page
            logger.info(f"Fetching intermediate page: {intermediate_url}")
            response = session.get(intermediate_url, timeout=10)
            if response.status_code != 200:
                logger.error(f"Failed to fetch intermediate page: {response.status_code}")
                raise Exception("Failed to fetch intermediate page")

            # Parse the intermediate page to find the 'GET' button
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Find the 'GET' button within the table
            table = soup.find('table', id='main')
            if table:
                get_button = table.find('a', string='GET')
                if get_button:
                    final_download_url = get_button['href']
                else:
                    logger.error("GET button not found on intermediate page")
                    raise Exception("GET button not found")
            else:
                logger.error("Table with ID 'main' not found on intermediate page")
                raise Exception("Table with ID 'main' not found")
            
            # Extract the final download URL
            logger.info(f"Final download URL: {final_download_url}")

            final_url = f"https://libgen.li/{final_download_url}"

            # Download the ePub file
            download_response = session.get(final_url, stream=True)
            if download_response.status_code == 200:
                # Define the local download directory
                download_dir = os.path.join(settings.MEDIA_ROOT, 'offline_books')
                os.makedirs(download_dir, exist_ok=True)

                # Sanitize and create the filename
                sanitized_filename = os.path.basename(final_download_url.split('?')[0])
                local_path = os.path.join(download_dir, sanitized_filename)

                # Save the downloaded file locally
                logger.info(f"Saving file to: {local_path}")
                with open(local_path, 'wb') as f:
                    for chunk in download_response.iter_content(chunk_size=1024):
                        if chunk:
                            f.write(chunk)

                return local_path
            else:
                logger.error(f"Failed to download file: {download_response.status_code}")
                raise Exception("Failed to download file")

        except Exception as e:
            logger.error(f"Error in fetch_and_download_book: {str(e)}")
            raise

    def post(self, request):
        """
        Handles the book download request.

        Extracts the required information from the request and initiates the download process.
        """
        libgen_link = request.data.get('libgen_link', '').strip()
        title = request.data.get('title', '').strip()
        author = request.data.get('author', '').strip()

        if not libgen_link or not title:
            return Response({'error': 'Download URL and title are required'}, status=400)

        try:
            # Download the book using the extracted libgen link
            local_path = self.fetch_and_download_book(libgen_link)

            # Create a new book entry in the database
            sanitized_filename = os.path.basename(local_path)
            book = Book.objects.create(
                user=request.user,
                title=title,
                author=author,
                content=f'offline_books/{sanitized_filename}',
                file_type='epub',
                file_size=f'{os.path.getsize(local_path) / 1024:.2f} KB'
            )

            # Schedule post-download processing (e.g., metadata extraction) with Celery
            download_book.delay(libgen_link, local_path)

            return Response({
                'message': 'Book downloaded successfully',
                'book_id': book.id,
                'file_path': book.content.url if hasattr(book.content, 'url') else book.content
            }, status=201)

        except Exception as e:
            return Response({'error': f'An error occurred: {str(e)}'}, status=500)


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
        
