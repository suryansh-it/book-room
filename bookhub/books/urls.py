from django.urls import path
from .views import BookSearchView, BookDownloadView,  BookDeleteView, UserLibraryView

urlpatterns = [
    path('search/', BookSearchView.as_view(), name='book-search'),  # New search URL
    path('download/', BookDownloadView.as_view(), name='book-download'),
    # path('read/<int:book_id>/', BookReadView.as_view(), name='read-book'), 
    path('delete/<int:book_id>/', BookDeleteView.as_view(), name='delete-book'), 
    # path('userlibrary/', UserLibraryView.as_view(), name='user-library'),
]