from celery import Celery
import requests

app = Celery('bookhub', broker='redis://localhost:6379/0')

@app.task
def download_book(download_url, file_path):
    """📥 Background task for downloading ePub books"""
    response= requests.get(download_url, stream = True)
    with open(file_path,'wb') as file :
        for chunk in response.iter_content(chunk_size=81292):
            file.write(chunk)
    return 'Download Complete'
