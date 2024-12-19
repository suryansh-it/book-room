from django.urls import re_path
from .consumer import DownloadProgressConsumer

# Define WebSocket routes
websocket_urlpatterns = [
    re_path(r'ws/progress/', DownloadProgressConsumer.as_asgi()),
]