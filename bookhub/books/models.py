from django.db import models
from django.conf import settings

class Book(models.Model):
    """📚 Model for storing downloaded book information"""
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    author = models.CharField(max_length=255)
    file_path = models.FileField(upload_to='books/epub/')
    created_at = models.DateTimeField(auto_now_add=True)
