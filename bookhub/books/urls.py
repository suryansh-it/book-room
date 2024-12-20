from django.urls import path
from .views import BookSearchView, BookDownloadView

urlpatterns = [
    path('search/', BookSearchView.as_view(), name='book-search'),  # New search URL
    path('download/', BookDownloadView.as_view(), name='book-download'),  
]