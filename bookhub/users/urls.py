from django.urls import path
from .views import RegisterView, LoginView, UserLibraryView

urlpatterns = [
    path('signup/', RegisterView.as_view(), name='signup'),
    path('login/', LoginView.as_view(), name='login'),
    path('library/', UserLibraryView.as_view(), name='user-library'),

]