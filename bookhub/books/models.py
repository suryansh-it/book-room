from django.db import models
from django.conf import settings


# Download the book from Library Genesis using requests.
# Save the file to the local storage system (media/ folder) using Django’s FileField.
# Track download status using Celery so the user can be notified when the download is complete.
# Store book metadata (title, author, file path) in the PostgreSQL database.


class Book(models.Model):
    """📚 Model for storing downloaded book information"""
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    author = models.CharField(max_length=255)
    file_path = models.FileField(upload_to='books/epub/')
    created_at = models.DateTimeField(auto_now_add=True)
