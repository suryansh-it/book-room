from django.shortcuts import render
import requests
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Book
# Use requests to send an HTTP request to Library Genesis.
# Extract book information (title, author, download link, etc.) from the response.
# Return the response to the frontend in JSON format.

class BookSearchView(APIView):
    """🔍 Allows users to search for books on Library Genesis"""

    def get(self, request):
        query = request.query_params.get('q', '')
        if not query:
            return Response({'error': 'Search query is required'}, status=400)
        
        url = f'http://libgen.is/search.php?req={query}&open=0&res=100&view=simple&phrase=1&column=def'
        response = requests.get(url)
        
        # Extract book details (this might require parsing the response if it's HTML)
        # For now, we're assuming we get a JSON response
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
        
        return Response({'results': books}, status=200)             
    


class BookDownloadView(APIView):
    """⬇️ Downloads an ePub book from Library Genesis"""

    def post(self, request):
        download_url = request.data.get('download_url')
        title = request.data.get('title')
        author = request.data.get('author')
        
        if not download_url or not title or not author:
            return Response({'error': 'Title, author, and download URL are required'}, status=400)
        
        response = requests.get(download_url, stream=True)


        # Save file locally
        file_path = f'media/books/epub/{title}.epub'
        with open(file_path, 'wb') as file:
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)
        
        # Save metadata to the database
        book = Book.objects.create(
            user=request.user,
            title=title,
            author=author,
            file_path=file_path
        )
        
        return Response({'message': 'Book downloaded successfully', 'book_id': book.id}, status=201)



# ePub Parser: Use python-epub-reader to parse and render ePub files.
# Book Reader API: Provide API endpoints for the user to read the book.
# Frontend UI: Use JavaScript to load the ePub file and present it on the user interface.


class BookReadView(APIView):
    """📖 Allows users to read an ePub book in the app"""

    def get(self, request, book_id):
        book = Book.objects.get(id=book_id, user=request.user)
        file_path = book.file_path.path

        # Read the ePub file and extract text
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
        
        return Response({'content': content}, status=200)
