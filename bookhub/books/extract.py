# EbookLib will help parse EPUB files.
# lxml is needed for HTML parsing.

from ebooklib import epub
from lxml import etree
import zipfile
import io
import ebooklib

def extract_epub(epub_binary):
        """Extract and parse the content of an EPUB file."""
    # Create a file-like object from the binary content of the EPUB
        epub_file= io.BytesIO(epub_binary)

        #parse the epub file
        book= epub.read_epub(epub_file)

        # Extract the content of the book (HTML files in the EPUB)
        content = []
        for item in book.get_items():
                if item.get_type() == ebooklib.ITEM_DOCUMENT:
                         # Parse the HTML content of each chapter
                        content.append(item.get_body_content())
    
        return content
                        