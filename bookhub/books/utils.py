import zipfile
from bs4 import BeautifulSoup

def extract_epub(local_path):
    """
    Extracts the full text from an ePub file stored as a file path.
    Returns a list of dictionaries with chapter titles and content.
    """
    chapters = []

    try:
        with zipfile.ZipFile(local_path) as epub_zip:
            # Open and parse the content
            for file in epub_zip.namelist():
                if file.endswith('.xhtml') or file.endswith('.html'):
                    with epub_zip.open(file) as f:
                        soup = BeautifulSoup(f, 'html.parser')
                        title = soup.title.string if soup.title else 'Untitled Chapter'
                        content = soup.get_text()
                        chapters.append({'title': title, 'content': content})
    except Exception as e:
        raise ValueError(f"Failed to extract ePub chapters: {e}")

    return chapters
