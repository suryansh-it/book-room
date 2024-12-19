from django.urls import re_path
from .consumer import DownloadProgressConsumer

websocket_urlpatterns = [
    re_path(r'ws/progress/', DownloadProgressConsumer.as_asgi()),
]