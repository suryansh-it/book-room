from django.urls import path
from .views import RegisterView, LoginView, UserLibraryView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('books/library/', UserLibraryView.as_view(), name='user_library'),

]