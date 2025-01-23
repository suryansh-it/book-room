import zipfile
from bs4 import BeautifulSoup
from .models import Book, Chapter
from django.shortcuts import get_object_or_404
# This function will extract the full text from an ePub file stored as binary content.
book = get_object_or_404(Book)
local_path = book.local_path

def extract_epub(local_path):
    """
    Extracts the full text from an ePub file stored as binary content.
    Returns a dictionary with the chapter titles and their corresponding content.
    """
    chapters = []


    with zipfile.ZipFile(local_path) as epub_zip:
        # Locate the content.opf file (ePub manifest)
        opf_path = None
        for file in epub_zip.namelist():
            if "content.opf" in file:
                opf_path = file
                break

        if not opf_path:
            raise ValueError("Invalid ePub file: Missing content.opf")
        

        # Parse the content.opf file to get the spine (order of chapters)
        opf_content = epub_zip.read(opf_path)
        soup = BeautifulSoup(opf_content, "xml")
        spine = [itemref["idref"] for itemref in soup.find_all("itemref")]

        # Retrieve each chapter in order
        manifest = {item["id"]: item["href"] for item in soup.find_all("item")}
        base_path = "/".join(opf_path.split("/")[:-1])  # To resolve relative paths

        for idref in spine:
            chapter_path = f"{base_path}/{manifest[idref]}"
            chapter_content = epub_zip.read(chapter_path).decode("utf-8")
            chapter_soup = BeautifulSoup(chapter_content, "html.parser")
            title = chapter_soup.title.string if chapter_soup.title else "Untitled"
            content = chapter_soup.get_text(separator="\n")
            chapters.append({"title": title, "content": content})

    return chapters


#function takes the full content (if extracted as a single string) and splits it into chapters.

def split_into_chapters(full_content):
    """
    Splits the book content into chapters based on a delimiter.
    For ePub, this is usually handled in the extract_epub function, so this is optional.
    """
    # Example: Split by "Chapter" keyword
    return full_content.split("Chapter")


# save extracted chapters to the database

def save_chapters_to_db(book_instance):
    """
    Extracts chapters from an ePub book and saves them to the database.
    """
    try:
        chapters = extract_epub(book_instance.content)
        for index, chapter in enumerate(chapters, start=1):
            Chapter.objects.create(
                book=book_instance,
                title=chapter["title"],
                content=chapter["content"],
                order=index   # Assign sequential order
            )
    except Exception as e:
        print(f"Error extracting chapters: {e}")
        raise ValueError("Failed to extract chapters from the book.")
