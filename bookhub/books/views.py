from django.shortcuts import render
import requests,os,logging, re , platform
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Book
from users.models import  CustomUser
from bookhub.celery import download_book
from django.core.cache import cache
from bs4 import BeautifulSoup
from rest_framework import status, permissions
from django.http import HttpResponse, FileResponse
from django.shortcuts import get_object_or_404
from django.conf import settings
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from urllib.parse import urlparse
from time import sleep
from .serializers import BookSerializer
from django.http import StreamingHttpResponse
from requests.adapters import HTTPAdapter
from urllib3 import Retry
from urllib.parse import unquote
from rest_framework.permissions import IsAuthenticated
from .utils import extract_epub
from pathlib import Path
from urllib.parse import quote
from django.conf import settings
from django.utils.text import slugify


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

#modify it to include all the pages search results
# class BookSearchView(APIView):
#     """🔍 Allows users to search for books on Library Genesis with robust error handling."""

#     SITE_MIRRORS = [        
        
#         'https://libgen.li',  # Updated mirror URL base
#         'https://libgen.is',
#     ]
#     TIMEOUT = 10  # Timeout for each request (in seconds)
#     RETRY_COUNT = 3  # Number of retries for each mirror

#     def get(self, request):
#         query = request.query_params.get('q', '').strip()  # Extract query parameter
#         if not query:
#             return Response({'error': 'Search query is required'}, status=400)

#                 # Filter books that match the search query and are of type 'epub'
#         books = Book.objects.filter(
#             file_type='epub',  # Only ePub files
#             title__icontains=query  # Case-insensitive search in the title
#         )

#         # Serialize the filtered books
#         serializer = BookSerializer(books, many=True)

#         # Generate a unique cache key
#         cache_key = f'search_results_{query}_{hash(tuple(self.SITE_MIRRORS))}'
#         cached_results = cache.get(cache_key)

#         if cached_results:
#             logging.info("Serving cached results")
#             return Response({'results': cached_results}, status=200)

#         books = []  # To store parsed book details
#         session = requests.Session()

#         # Configure retry mechanism
#         retries = Retry(
#             total=self.RETRY_COUNT,
#             backoff_factor=1,
#             status_forcelist=[500, 502, 503, 504]
#         )
#         session.mount('https://', HTTPAdapter(max_retries=retries))

#         response = None

#         # Iterate through mirrors
#         for mirror in self.SITE_MIRRORS:
#             url = (
#                 f"{mirror}/index.php?"
#                 f"req={query}&"
#                 "columns[]=t&columns[]=a&columns[]=s&columns[]=y&columns[]=p&columns[]=i&"
#                 "objects[]=f&objects[]=e&objects[]=s&objects[]=a&objects[]=p&objects[]=w&"
#                 "topics[]=l&topics[]=c&topics[]=f&topics[]=a&topics[]=m&topics[]=r&topics[]=s&"
#                 "res=100&filesuns=all"
#             )
#             try:
#                 logging.info(f"Trying mirror: {url}")
#                 response = session.get(url, timeout=self.TIMEOUT)
#                 if response.status_code == 200:
#                     logging.info(f"Mirror succeeded: {mirror}")
#                     break
#             except requests.RequestException as e:
#                 logging.error(f"Error with mirror {mirror}: {e}")
#                 continue

#         if not response or response.status_code != 200:
#             logging.error("Failed to fetch data from all Library Genesis mirrors")
#             return Response({'error': 'Unable to fetch results. Please try again later.'}, status=500)

#         # Parse the response
#         try:
#             soup = BeautifulSoup(response.content, 'html.parser')
#             table = soup.find('table', {'id': 'tablelibgen'})  # Look for table with ID 'tablelibgen'
#             if not table:
#                 logging.error("No results table found on the page")
#                 return Response({'error': 'No results found'}, status=404)

#             rows = table.find_all('tr')[1:]  # Skip header row
#             for row in rows:
#                 columns = row.find_all('td')
#                 # Ensure `columns` contains all <td> elements in the row
                
#                 if len(columns) > 8:  # Ensure there are enough columns
#                     try:
#                         # Extract title from the first <td>
#                         title_author_td = columns[0]
#                         # title = title_author_td.find('a').text.strip() if title_author_td.find('a') else title_author_td.find('a').text.strip()
                        
#                         b_tag = title_author_td.find('b')
                        
#                         if b_tag:
                            
#                             first_a_tag = b_tag.find('a')


#                             if b_tag.text:
                                
#                                 title = b_tag.text.strip()
#                             else:
#                                 title= first_a_tag.text.strip()
                        
                        


#                         # Extract author
#                         author = columns[1].text.strip() if len(columns) > 1 else 'Unknown'

#                         # Extract publisher, year, language
#                         publisher = columns[2].text.strip() if len(columns) > 2 else 'Unknown'
#                         year = columns[3].text.strip() if len(columns) > 3 else 'Unknown'
#                         language = columns[4].text.strip() if len(columns) > 4 else 'Unknown'

#                         # Extract file size and file type
#                         file_size_td = columns[6]
#                         file_size_match = re.search(r'([\d.]+)\s?(KB|MB|GB|kB)', file_size_td.text.strip())
#                         file_size = "Unknown"  # Default value in case the file size is not found
#                         if file_size_match:
#                             file_size = file_size_match.group(0)  # Keep the original size with its unit (e.g., "1.5 MB")
                        

#                         file_type_td = columns[7]
#                         file_type = file_type_td.text.strip() if len(columns) > 7 else 'Unknown'

#                         # Extract the libgen download link
                        
#                         download_td = columns[8]
#                         nobr_tag = download_td.find('nobr')
                        
#                         if nobr_tag:
#                             # Find the first 'a' tag within the 'nobr' tag 
#                             first_a_tag = nobr_tag.find('a') 

#                             if first_a_tag:
#                                 # Extract the 'href' attribute from the first 'a' tag
#                                 libgen_link = first_a_tag.get('href')
#                             else:
#                                 libgen_link = None
#                         else:
#                             first_a_tag = download_td.find('a') 

#                             if first_a_tag:
#                                 # Extract the 'href' attribute from the first 'a' tag
#                                 libgen_link = first_a_tag.get('href')
#                             else:
#                                 libgen_link = None

                        
#                         # Filter for ePub files only
#                         if file_type.lower() == 'epub':
#                             # Construct the book info dictionary
#                             book_info = {
#                                 'title': title,
#                                 'author': author,
#                                 'publisher': publisher,
#                                 'year': year,
#                                 'language': language,
#                                 'file_type': file_type,
#                                 'file_size': file_size,  # Always in MB
#                                 'download_link': libgen_link
#                             }

#                             print("Parsed Book Info:", book_info)
#                             books.append(book_info)  # Only append if parsing succeeds
#                     except Exception as e:
#                         logging.error(f"Error parsing book info: {e}")
#                         continue

#         except Exception as e:
#             logging.error(f"Error while parsing response: {e}", exc_info=True)
#             return Response({'error': 'Failed to parse search results'}, status=500)

#         # Cache the results
#         cache.set(cache_key, books, timeout=3600)  # Cache for 1 hour
#         logging.info("Search results cached successfully")

#         return Response({'results': books}, status=200)




logger = logging.getLogger(__name__)




class BookSearchView(APIView):
    SITE_MIRRORS = [
        'https://libgen.li',
        'https://libgen.is',
    ]
    TIMEOUT = 10
    RETRY_COUNT = 3

    @staticmethod
    def fetch_books_from_page(url, session):
        """
        Fetch books from a single page of Library Genesis.
        """

        headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
                }



        try:
            response = session.get(url,headers=headers, timeout=10)
            if response.status_code != 200:
                logger.error(f"Failed to fetch search results: {response.status_code}")
                return None

            soup = BeautifulSoup(response.content, 'html.parser')
            table = soup.find('table', id='tablelibgen')
            if not table:
                logger.error("No results table found on the page")
                return None

            books = []
            rows = table.find_all('tr')[1:]  # Skip header row
            for row in rows:
                columns = row.find_all('td')
                if len(columns) > 8:
                    title = columns[0].find('b').text.strip() if columns[0].find('b') else 'Unknown'
                    author = columns[1].text.strip() if len(columns) > 1 else 'Unknown'
                    publisher = columns[2].text.strip() if len(columns) > 2 else 'Unknown'
                    year = columns[3].text.strip() if len(columns) > 3 else 'Unknown'
                    language = columns[4].text.strip() if len(columns) > 4 else 'Unknown'
                    file_size = re.search(r'([\d.]+)\s?(KB|MB|GB|kB)', columns[6].text.strip())
                    file_type = columns[7].text.strip() if len(columns) > 7 else 'Unknown'
                    libgen_link = columns[8].find('a')['href'] if columns[8].find('a') else None

                    if file_type.lower() == 'epub':
                        books.append({
                            'title': title,
                            'author': author,
                            'publisher': publisher,
                            'year': year,
                            'language': language,
                            'file_size': file_size.group(0) if file_size else 'Unknown',
                            'file_type': file_type,
                            'link': libgen_link
                        })
            return books

        except requests.exceptions.RequestException as e:
            logger.exception(f"Request Exception while fetching search results: {e}")
            return None

    def fetch_books_from_all_pages(self, search_query):
        """
        Fetch books from all pages of search results for the given query from Library Genesis mirrors.
        """
        session = requests.Session()
        retries = Retry(
            total=self.RETRY_COUNT,
            backoff_factor=1,
            status_forcelist=[500, 502, 503, 504]
        )
        session.mount('https://', HTTPAdapter(max_retries=retries))

        all_books = []

        for mirror in self.SITE_MIRRORS:
            base_url = (
                f"{mirror}/index.php?req={search_query}&"
                "columns[]=t&columns[]=a&columns[]=s&columns[]=y&columns[]=p&columns[]=i&"
                "objects[]=f&objects[]=e&objects[]=s&objects[]=a&objects[]=p&objects[]=w&"
                "topics[]=l&topics[]=c&topics[]=f&topics[]=a&topics[]=m&topics[]=r&topics[]=s&"
                "res=100&filesuns=all"
            )

            page = 1
            while True:
                # Construct the page-specific URL
                search_url = f"{base_url}&page={page}" if page > 1 else base_url
                logger.info(f"Fetching results from: {search_url}")

                try:
                    # Fetch books from the current page
                    books = self.fetch_books_from_page(search_url, session)
                    if not books:
                        logger.info(f"No books found on page {page}. Stopping.")
                        break  # Stop if no books are found (end of results)

                    all_books.extend(books)
                    page += 1  # Move to the next page

                     # Random delay between requests to mimic human behavior
                    time.sleep(random.uniform(1, 3))  # Random delay between 1 and 3 seconds

                except Exception as e:
                    logger.exception(f"Error fetching page {page}: {e}")
                    break

            if all_books:
                break  # Exit after successfully fetching books from a working mirror

        logger.info(f"Total books fetched: {len(all_books)}")
        return all_books



    def get(self, request):
        """
        API endpoint to search for books and fetch results from all pages.
        """
        search_query = request.query_params.get('q', '').strip()
        if not search_query:
            return Response({'error': 'Search query is required'}, status=400)

        try:
            books = self.fetch_books_from_all_pages(search_query)
            if not books:
                return Response({'error': 'No results found'}, status=404)
            return Response({'books': books}, status=200)
        except Exception as e:
            logger.exception(f"Error in BookSearchView.get: {e}")
            return Response({'error': f'An error occurred: {str(e)}'}, status=500)





logger = logging.getLogger(__name__)

import os


class BookDownloadView(APIView):
    """
    Handles the download of an ePub book from Library Genesis.
    """

    @staticmethod
    def fetch_and_download_book(libgen_link, title):
        """
        Fetch the intermediate page, locate the 'GET' button, and download the ePub file.
        """
        try:
            session = requests.Session()
            retries = Retry(total=5, backoff_factor=1, status_forcelist=[500, 502, 503, 504])
            session.mount('http://', HTTPAdapter(max_retries=retries))
            session.mount('https://', HTTPAdapter(max_retries=retries))

            intermediate_url = f"https://libgen.li{libgen_link}"
            logger.info(f"Fetching intermediate page: {intermediate_url}")
            response = session.get(intermediate_url, timeout=10)
            if response.status_code != 200:
                logger.error(f"Failed to fetch intermediate page: {response.status_code}")
                raise Exception("Failed to fetch intermediate page")

            soup = BeautifulSoup(response.content, 'html.parser')
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

            logger.info(f"Final download URL: {final_download_url}")

            final_url = f"https://libgen.li/{final_download_url}"

            # Follow redirects (important change)
            final_response = session.get(final_url, stream=True, allow_redirects=True, timeout=60)
            final_response.raise_for_status()

            def file_iterator(response, chunk_size=8192):
                for chunk in response.iter_content(chunk_size=chunk_size):
                    if chunk:
                        yield chunk

            content_disposition = final_response.headers.get('Content-Disposition')
            filename = None

            if content_disposition:
                filename_match = re.search(r"filename\*=UTF-8''(.+)", content_disposition)
                if filename_match:
                    filename = (filename_match.group(1))  # URL encode the filename
                else:
                    filename_match = re.search(r"filename=\"(.+)\"", content_disposition)
                    if filename_match:
                        filename = (filename_match.group(1))

            if not filename:
                # Fallback: Generate filename from title (improved)
                filename_parts = [re.sub(r'[\\/*?:"<>|]', "", part) for part in title.split()]  # Sanitize each word
                filename = f"{slugify('-'.join(filename_parts))}.epub"

                logger.warning(f"Content-Disposition header missing. Using fallback filename: {filename}")

            # Ensure the directory for saving the book exists
            media_download_dir = os.path.join('media', 'offline_books')  # Path for media files
            os.makedirs(media_download_dir, exist_ok=True)  # Ensure the directory exists

            local_path = os.path.join(media_download_dir, filename)

            with open(local_path, 'wb') as f:
                for chunk in file_iterator(final_response):
                    f.write(chunk)

            logger.info(f"Book saved to: {local_path}")

            return local_path

        except requests.exceptions.RequestException as e:
            logger.exception(f"Request Exception in fetch_and_download_book: {e}")
            raise
        except Exception as e:
            logger.exception(f"Error in fetch_and_download_book: {e}")
            raise

    def post(self, request):
        libgen_link = request.data.get('libgen_link', '').strip()
        title = request.data.get('title', '').strip()
        author = request.data.get('author', '').strip()

        if not libgen_link or not title or not author:
            return Response({'error': 'Download URL, title, and author are required'}, status=400)

        try:
            local_path = self.fetch_and_download_book(libgen_link, title)

            # Provide a URL for the frontend to download
            media_url =request.build_absolute_uri(f"{settings.MEDIA_URL}offline_books/{os.path.basename(local_path)}")  # Ensure URL is encoded

            # Save book information in the database
            sanitized_filename = os.path.basename(local_path)
            book = Book.objects.create(
                user=request.user,
                title=title,
                author=author,
                content=f'offline_books/{sanitized_filename}',
                file_type='epub',
                file_size=f'{os.path.getsize(local_path) / 1024:.2f} KB',
                local_path=local_path
            )
            download_book.delay(libgen_link, local_path)  # Celery task
            return Response({
                'message': 'Book downloaded successfully',
                'book_id': book.id,
                'file_url': media_url
            }, status=201)

        except Exception as e:
            logger.exception(f"Error in BookDownloadView.post: {e}")
            return Response({'error': f'An error occurred: {str(e)}'}, status=500)

# download_book.delay(libgen_link, local_path)  # Celery task
# ePub Parser: Use python-epub-reader to parse and render ePub files.
# Book Reader API: Provide API endpoints for the user to read the book.
# Frontend UI: Use JavaScript to load the ePub file and present it on the user interface.



# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)





class BookDeleteAllView(APIView):  # New view for deleting all books
    """Deletes all downloaded books for the user."""

    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request):
        user = request.user
        try:
            books = Book.objects.filter(user=user)  # Get all books for the user

            if not books.exists():
                return Response({'message': 'No books found for this user.'}, status=status.HTTP_204_NO_CONTENT)

            for book in books:
                try:
                    if book.local_path and os.path.exists(book.local_path):
                        os.remove(book.local_path)
                        logger.info(f"File deleted from: {book.local_path}")
                    book.delete()  # Delete the database record
                    logger.info(f"Book record deleted from DB (ID: {book.id})")

                except Exception as e:
                    logger.exception(f"Error deleting book {book.id}: {e}")  # Log individual errors
                    # Important: Don't stop deleting other books if one fails
                    # You might want to collect these errors and return them in the response

            return Response({'message': 'All books deleted successfully'}, status=status.HTTP_200_OK)

        except Exception as e:
            logger.exception(f"Error in BookDeleteAllView: {e}")
            return Response({'error': f"An error occurred: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
