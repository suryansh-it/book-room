from django.urls import re_path
from .consumers import DownloadProgressConsumer

websocket_urlpatterns = [
    re_path(r'ws/progress/', DownloadProgressConsumer.as_asgi()),
]