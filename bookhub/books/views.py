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
                        # title = title_author_td.find('a').text.strip() if title_author_td.find('a') else title_author_td.find('a').text.strip()
                        
                        b_tag = title_author_td.find('b')
                        
                        if b_tag:
                            
                            first_a_tag = b_tag.find('a')


                            if b_tag.text:
                                
                                title = b_tag.text.strip()
                            else:
                                title= first_a_tag.text.strip()
                        
                        


                        # Extract author
                        author = columns[1].text.strip() if len(columns) > 1 else 'Unknown'

                        # Extract publisher, year, language
                        publisher = columns[2].text.strip() if len(columns) > 2 else 'Unknown'
                        year = columns[3].text.strip() if len(columns) > 3 else 'Unknown'
                        language = columns[4].text.strip() if len(columns) > 4 else 'Unknown'

                        # Extract file size and file type
                        file_size_td = columns[6]
                        file_size_match = re.search(r'([\d.]+)\s?(KB|MB|GB|kB)', file_size_td.text.strip())
                        file_size = "Unknown"  # Default value in case the file size is not found
                        if file_size_match:
                            file_size = file_size_match.group(0)  # Keep the original size with its unit (e.g., "1.5 MB")
                        

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
                            first_a_tag = download_td.find('a') 

                            if first_a_tag:
                                # Extract the 'href' attribute from the first 'a' tag
                                libgen_link = first_a_tag.get('href')
                            else:
                                libgen_link = None

                        
                        # Filter for ePub files only
                        if file_type.lower() == 'epub':
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

class UserLibraryView(APIView):
    
    @staticmethod
    def get_base_dir():
        """
        Determine storage path based on the platform.
        """
        # if os.name == 'nt':  # Windows
        #     base_dir = 'D:/offline_books'
        # else:  # Android or other environments
        """Determine storage path for user_books folder."""
        base_dir = Path.home() / "Downloads/user_books"
        base_dir.mkdir(parents=True, exist_ok=True)
        return str(base_dir)

    def get(self, request):
        """
        Retrieve all books stored in the user's offline library.
        """
        base_dir = self.get_base_dir()
        books = []

        try:
            # Check if the base directory exists
            if not os.path.exists(base_dir):
                raise FileNotFoundError(f"Base directory {base_dir} not found.")
            
            for file_name in os.listdir(base_dir):
                if file_name.endswith('.epub'):
                    book_info = {
                        'title': os.path.splitext(file_name)[0],
                        'file_name': file_name,
                        'path': file_name,  # Return just the file name
                    }
                    books.append(book_info)
                    print(f"Book found: {book_info['title']}")  # Print book details in terminal

        except FileNotFoundError as e:
            logger.error(f"Error: {e}")
            return Response({'message': 'No books available in the offline library.'}, status=200)
        except Exception as e:
            logger.error(f"Error reading offline books: {e}")
            return Response({'error': f'An error occurred: {str(e)}'}, status=500)

        if not books:
            logger.info("No books found in the library.")
            return Response({'message': 'No books available in the offline library.'}, status=200)

        logger.info(f"Books found: {len(books)}")  # Log the number of books found
        return Response({'library': books}, status=200)



# class BookReadView(APIView):
#     """📖 Allows users to read an ePub book with lazy loading and pagination."""

#     def get(self, request, *args, **kwargs):
#         book_id = kwargs.get('book_id')
#         title = request.query_params.get('title')  # New: Fetch title from query params

#         if not book_id and not title:
#             return Response({'error': 'Book ID or title is required.'}, status=400)

#         try:
#             # Attempt to fetch by ID
#             book = None
#             if book_id:
#                 book = Book.objects.filter(id=book_id).first()

#             # Fallback: Fetch by title
#             if not book and title:
#                 book = Book.objects.filter(title__iexact=title).first()

#             if not book:
#                 return Response({'error': 'Book not found.'}, status=404)

#             local_path = book.local_path
#             if not os.path.exists(local_path):
#                 return Response({'error': 'Book file not found on disk.'}, status=404)

#             with open(local_path, 'rb') as f:
#                 return HttpResponse(f.read(), content_type='application/epub+zip')

#         except Exception as e:
#             logger.exception(f"Error in BookReadView: {e}")
#             return Response({'error': 'Failed to read book.'}, status=500)

#         # Validate book file exists
#         book_file_path = os.path.join(settings.MEDIA_ROOT, book.local_path)
#         if not book.local_path or not os.path.exists(book_file_path):
#             return Response({'error': 'The requested book file is missing or inaccessible.'}, status=404)

#         # Extract chapters if not already done
#         if not book.chapters.exists():
#             save_chapters_to_db(book.id)  # Use the imported function

#         # Chapter-level pagination
#         chapter_page = int(request.GET.get('chapter', 1))
#         chapters_per_page = int(request.GET.get('chapters_per_page', 1))

#         # Calculate the range of chapters to return
#         start_index = (chapter_page - 1) * chapters_per_page
#         end_index = start_index + chapters_per_page

#         total_chapters = book.chapters.count()
#         chapters = book.chapters.all()[start_index:end_index]

#         # Handle out-of-range pagination
#         if not chapters.exists():
#             return Response({'error': 'No chapters available for the given page.'}, status=404)

#         # Serialize chapters
#         chapter_data = [
#             {
#                 'title': chapter.title,
#                 'content': chapter.content,
#                 'order': chapter.order,
#                 'current_page': chapter_page,
#                 'total_pages': (total_chapters // chapters_per_page) + (1 if total_chapters % chapters_per_page else 0),
#             }
#             for chapter in chapters
#         ]

#         return Response({'chapters': chapter_data}, status=200)




# class BookReadView(APIView):
#     """📖 Reads an ePub book with chapter-based lazy loading and pagination."""

#     def get(self, request, *args, **kwargs):
#         book_name = kwargs.get('book_id')  # Use book_name instead of book_id as we are reading directly from files
#         offline_books_dir = os.path.join(settings.MEDIA_ROOT, 'offline_books')

#         if not book_name:
#             return Response({'error': 'Book name is required.'}, status=400)

#         book_path = os.path.join(offline_books_dir, book_name)
#         if not os.path.exists(book_path):
#             return Response({'error': 'Book not found in offline library.'}, status=404)

#         # Check cache for extracted chapters
#         cached_chapters = cache.get(book_name)
#         if not cached_chapters:
#             try:
#                 cached_chapters = extract_epub(book_path)
#                 cache.set(book_name, cached_chapters, timeout=3600)  # Cache chapters for 1 hour
#             except Exception as e:
#                 return Response({'error': f'Failed to extract book content: {e}'}, status=500)

#         # Pagination logic
#         chapter_page = int(request.GET.get('page', 1))
#         chapters_per_page = int(request.GET.get('chapters_per_page', 1))
#         total_chapters = len(cached_chapters)

#         start_index = (chapter_page - 1) * chapters_per_page
#         end_index = start_index + chapters_per_page

#         if start_index >= total_chapters:
#             return Response({'error': 'No more chapters available.'}, status=404)

#         paginated_chapters = cached_chapters[start_index:end_index]

#         return Response({
#             'chapters': paginated_chapters,
#             'current_page': chapter_page,
#             'total_pages': (total_chapters + chapters_per_page - 1) // chapters_per_page,
#         }, status=200)


class BookDeleteView(APIView):
    """ Deletes a downloaded book"""

    permission_classes = [permissions.IsAuthenticated]

    def delete(self,request,book_id):
        user= request.user
        try:
            book = get_object_or_404(Book, id=book_id, user=user)
        except:
            return Response({'error': 'Book not found.'}, status=status.HTTP_404_NOT_FOUND)


        try:
            #delete local file if it exists
            if book.local_path and os.path.exists(book.local_path):
                os.remove(book.local_path)

            #delete book record from db
            book.delete()

            return Response({'message': 'Book deleted successfully'},status=200)
        
        except Exception as e:
            return Response({'error':f"An error ocurred while deleting the book:{str(e)}"},status=500)
        
