from rest_framework import serializers
from .models import Book, Chapter

class ChapterSerializer(serializers.ModelSerializer):
    """
    Serializer for the Chapter model.
    """
    class Meta:
        model = Chapter
        fields = ['id', 'title', 'content', 'chapter_number', 'order']


class BookSerializer(serializers.ModelSerializer):
    """
    Serializer for the Book model.
    Includes nested chapters.
    """
    chapters = ChapterSerializer(many=True, read_only=True)  # Nested chapters

    class Meta:
        model = Book
        fields = [
            'id',
            'user',
            'title',
            'author',
            'publisher',
            'year',
            'file_type',
            'content',
            'file_size',
            'download_date',
            'local_path',
            'chapters'
        ]
        read_only_fields = ['download_date', 'file_size']  # Fields that are not editable
