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
    local_path = models.CharField(max_length=500, blank=True, null=True)  # Path for offline storage


class Chapter(models.Model):
    book = models.ForeignKey(Book, related_name="chapters", on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    content = models.TextField()  # The raw text of the chapter
    chapter_number = models.IntegerField()
    order = models.PositiveIntegerField(default=0)  # Field for ordering chapters

    class Meta:
        ordering = ['order']  # Ensures chapters are retrieved in the correct order
        unique_together = ('book', 'order')  # Ensure unique ordering within a book

    
    def __str__(self):
        return f'{self.title} by {self.author}'
    
