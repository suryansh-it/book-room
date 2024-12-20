from django.db import models
from django.conf import settings
from users.models import CustomUser

# Download the book from Library Genesis using requests.
# Save the file to the local storage system (media/ folder) using Django’s FileField.
# Track download status using Celery so the user can be notified when the download is complete.
# Store book metadata (title, author, file path) in the PostgreSQL database.


class Book(models.Model):
    """Model to store book details and the binary file in the database."""
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name="books")
    title = models.CharField(max_length=255)
    author = models.CharField(max_length=255)
    publisher = models.CharField(max_length=255, null=True, blank=True)
    year = models.CharField(max_length=4, null=True, blank=True)
    file_type = models.CharField(max_length=10, default='EPUB')
    content = models.BinaryField(null=True, blank=True)  # Binary field to store the file content
    file_size = models.CharField(max_length=50, null=True, blank=True)
    download_date = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.title} by {self.author}'