import asyncio
from fastapi import WebSocket


class ConnectionManager:
    """Manages active WebSocket connections grouped by project_id."""

    def __init__(self):
        self.active_connections: dict[int, set[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, project_id: int):
        """Accepts a WebSocket connection and registers it under the given project_id."""
        from fastapi.websockets import WebSocketState
        if websocket.application_state == WebSocketState.CONNECTING:
            await websocket.accept()
        if project_id not in self.active_connections:
            self.active_connections[project_id] = set()
        self.active_connections[project_id].add(websocket)

    async def disconnect(self, websocket: WebSocket, project_id: int):
        """Removes a WebSocket connection from the project's tracking set."""
        if project_id in self.active_connections:
            self.active_connections[project_id].discard(websocket)
            if not self.active_connections[project_id]:
                del self.active_connections[project_id]

    async def broadcast_to_project(self, project_id: int, message: dict):
        """Broadcasts a JSON message to all active WebSockets connected to a specific project_id."""
        if project_id not in self.active_connections:
            return

        # Create a snapshot list of connections to avoid modification issues during iteration
        connections = list(self.active_connections[project_id])
        if not connections:
            return

        # Send to all connections concurrently, capturing exceptions so one failure doesn't block the rest
        tasks = [websocket.send_json(message) for websocket in connections]
        await asyncio.gather(*tasks, return_exceptions=True)


# Instantiate the global connection manager
manager = ConnectionManager()
