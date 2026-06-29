import asyncio
from fastapi import WebSocket


class ConnectionManager:
    """Manages active WebSocket connections grouped by project_id."""

    def __init__(self):
        self.active_connections: dict[int, set[WebSocket]] = {}
        self.connection_contexts: dict[WebSocket, dict] = {}

    async def connect(self, websocket: WebSocket, project_id: int, context: dict = None):
        """Accepts a WebSocket connection and registers it under the given project_id."""
        from fastapi.websockets import WebSocketState
        if websocket.application_state == WebSocketState.CONNECTING:
            await websocket.accept()
        if project_id not in self.active_connections:
            self.active_connections[project_id] = set()
        self.active_connections[project_id].add(websocket)
        self.connection_contexts[websocket] = context or {}

    async def disconnect(self, websocket: WebSocket, project_id: int):
        """Removes a WebSocket connection from the project's tracking set."""
        if project_id in self.active_connections:
            self.active_connections[project_id].discard(websocket)
            if not self.active_connections[project_id]:
                del self.active_connections[project_id]
        if websocket in self.connection_contexts:
            del self.connection_contexts[websocket]

    async def broadcast_to_project(self, project_id: int, message: dict):
        """Broadcasts a JSON message to all active WebSockets connected to a specific project_id."""
        if project_id not in self.active_connections:
            return

        # Create a snapshot list of connections to avoid modification issues during iteration
        connections = list(self.active_connections[project_id])
        if not connections:
            return

        from sqlmodel import Session, select
        from backend.app.database import engine
        from backend.app.models import FeatureFlag
        from backend.app.targeting import evaluate_targeting_rule

        # Fetch flag object if this is a flag update broadcast
        flag_obj = None
        if message.get("type") == "flag" and message.get("action") == "update":
            with Session(engine) as session:
                flag_obj = session.exec(
                    select(FeatureFlag).where(
                        FeatureFlag.key == message["key"],
                        FeatureFlag.project_id == project_id
                    )
                ).first()

        # Send to all connections concurrently, evaluating targeting rules for each connection
        tasks = []
        for websocket in connections:
            if message.get("type") == "flag" and message.get("action") == "update" and flag_obj is not None:
                context = self.connection_contexts.get(websocket, {})
                evaluated_state = evaluate_targeting_rule(flag_obj, context)
                conn_message = {**message, "is_enabled": evaluated_state}
            else:
                conn_message = message
            tasks.append(websocket.send_json(conn_message))

        await asyncio.gather(*tasks, return_exceptions=True)


# Instantiate the global connection manager
manager = ConnectionManager()
