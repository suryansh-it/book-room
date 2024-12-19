import json
from channels.generic.websocket import AsyncWebsocketConsumer

class DownloadProgressConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        # Accept WebSocket connection
        await self.accept()

    async def disconnect(self, close_code):
        # Handle disconnection
        pass

    async def send_progress(self, event):
        # Send real-time progress updates to the client
        await self.send(text_data=json.dumps(event))