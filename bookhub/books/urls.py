from django.urls import path
from .views import BookSearchView, BookDownloadView, BookReadView

urlpatterns = [
    path('search/', BookSearchView.as_view(), name='book-search'),  # New search URL
    path('download/', BookDownloadView.as_view(), name='book-download'),
    path('books/read/<int:book_id>/', BookReadView.as_view(), name='read-book'),  
]