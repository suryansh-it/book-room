from django.shortcuts import render
import requests
from rest_framework.views import APIView
from rest_framework.response import Response

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