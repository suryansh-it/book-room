from django.shortcuts import render
import requests,os
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
# Use requests to send an HTTP request to Library Genesis.
# Extract book information (title, author, download link, etc.) from the response.
# Return the response to the frontend in JSON format.

class BookSearchView(APIView):
    """🔍 Allows users to search for books on Library Genesis"""

    def get(self, request):
        query = request.query_params.get('q', '')       # Extract query parameter
        if not query:
            return Response({'error': 'Search query is required'}, status=400)
        
        # Check if results are already cached
        cache_key = f'search_results_{query}'       # Unique cache key for this query
        cached_results = cache.get(cache_key)       # Check if the data is in the cache
        
        if cached_results:
            return Response({'results': cached_results}, status=200)


         # Call Library Genesis
        url = f'http://libgen.is/search.php?req={query}&open=0&res=100&view=simple&phrase=1&column=def'
        response = requests.get(url)
        
        if response.status_code != 200:
            return Response({'error': 'Failed to fetch data from Library Genesis'}, status=500)
        
        soup = BeautifulSoup(response.content, 'html.parser')

        # Extract book details (this might require parsing the response if it's HTML)
        # assuming we get a JSON response
        # Sample response handling (You may need BeautifulSoup to parse HTML)
        books = []  # Placeholder: This would be populated by scraping the website
        for book in books:
            books.append({
                'title': book['title'],
                'author': book['author'],
                'download_url': book['download_url'],
                'file_size': book['size'],
                'file_type': book['type']
            })


        try:
            table = soup.find('table', {'class': 'c'})  # Library Genesis table with class 'c'
            rows = table.find_all('tr')[1:]  # Skip the header row

            for row in rows:
                columns = row.find_all('td')
                if len(columns) > 0:
                    book_info = {
                        'id': columns[0].text.strip(),  # Book ID
                        'author': columns[1].text.strip(),  # Author
                        'title': columns[2].a.text.strip() if columns[2].a else 'N/A',  # Title
                        'publisher': columns[3].text.strip(),  # Publisher
                        'year': columns[4].text.strip(),  # Year
                        'language': columns[6].text.strip(),  # Language
                        'file_type': columns[8].text.strip(),  # File type (like EPUB, PDF)
                        'file_size': columns[7].text.strip(),  # File size
                        'download_link': columns[9].a['href'] if columns[9].a else None  # Direct download link
                    }
                    books.append(book_info)
        except Exception as e:
            return Response({'error': f'Error while parsing: {str(e)}'}, status=500)
        

# Some rows may have missing elements, so we use .a.text.strip() only if the element exists.
# If it doesn't exist, we return N/A or None for the download link.

        cache.set(cache_key, books, timeout=3600)  # Cache for 1 hour

        return Response({'results': books}, status=200)             
    


class BookDownloadView(APIView):
    """⬇️ Downloads an ePub book from Library Genesis"""

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user= request.user  # Get the logged-in user
        download_url = request.query_params.get('url','') #to get query parameters for get
        title = request.query_params.get('title','')
        author = request.query_params.get('author','')

        
        if not download_url or not title or not author:
            return Response({'error': 'Title, author, and download URL are required'}, status=400)
        
        try:
            response = requests.get(download_url, stream=True)
            if response.status_code != 200:
                return Response({'error': 'Failed to download book from the provided URL'}, status=500)

            # Read binary content from the downloaded file
            file_content = response.content
            file_size = len(file_content)  # Get size of the file in bytes
            file_type = 'epub'  # Assuming ePub format for now

            # Save metadata and file binary content to the database
            book = Book.objects.create(
                user=user,
                title=title,
                author=author,
                file=file_content,
                file_type=file_type,
                file_size=f'{file_size / 1024:.2f} KB'  # Convert bytes to KB
            )

            # Save book locally in a dedicated folder
            local_path = os.path.join(settings.MEDIA_ROOT, 'offline_books', f'{book.id}.epub')
            os.makedirs(os.path.dirname(local_path), exist_ok=True)
            # saves the downloaded book as a local file in a designated folder (offline_books) under MEDIA_ROOT.

            with open(local_path, 'wb') as f:
                f.write(file_content)

            # Update the book object with the local path
            book.local_path = local_path
            book.save()

            download_book.delay(download_url)  # If any further async operations are needed

            return Response({'message': 'Book downloaded successfully', 'book_id': book.id}, status=201)

        except Exception as e:
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
        start_index = (chapter_page - 1) * chapters_per_page
        end_index = start_index + chapters_per_page
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
        
