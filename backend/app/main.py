from contextlib import asynccontextmanager
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from backend.app.database import init_db
from backend.app.routes import projects, flags, configs
from backend.app.ws_manager import manager

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield

app = FastAPI(
    title="FlagForge API",
    description="Backend API for FlagForge Feature Flagging and Remote Configuration Service",
    version="0.1.0",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust this as needed for production environments
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(projects.router)
app.include_router(flags.router)
app.include_router(configs.router)

async def send_evaluated_flags(websocket: WebSocket, project_id: int):
    from sqlmodel import Session, select
    from backend.app.database import engine
    from backend.app.models import FeatureFlag
    from backend.app.targeting import evaluate_targeting_rule
    
    context = manager.connection_contexts.get(websocket, {})
    with Session(engine) as session:
        flags = session.exec(select(FeatureFlag).where(FeatureFlag.project_id == project_id)).all()
        for flag in flags:
            evaluated_val = evaluate_targeting_rule(flag, context)
            await websocket.send_json({
                "type": "flag",
                "key": flag.key,
                "is_enabled": evaluated_val,
                "action": "update"
            })

@app.websocket("/api/stream/{project_id}")
async def websocket_endpoint(websocket: WebSocket, project_id: int):
    import json
    
    # Parse query parameters for context
    user_id = websocket.query_params.get("user_id") or websocket.query_params.get("id")
    group = websocket.query_params.get("group")
    
    context = {}
    if user_id:
        context["id"] = user_id
    if group:
        context["group"] = group

    await websocket.accept()
    await manager.connect(websocket, project_id, context)
    try:
        # Immediately evaluate and send targeted flags
        await send_evaluated_flags(websocket, project_id)
        
        while True:
            data = await websocket.receive_text()
            try:
                payload = json.loads(data)
                if isinstance(payload, dict):
                    # Expect {"type": "context", "context": {...}} or just {...}
                    new_ctx = payload.get("context") if "context" in payload else payload
                    if isinstance(new_ctx, dict):
                        manager.connection_contexts[websocket].update(new_ctx)
                        await send_evaluated_flags(websocket, project_id)
            except Exception:
                pass
    except WebSocketDisconnect:
        pass
    finally:
        await manager.disconnect(websocket, project_id)

@app.get("/")
def read_root():
    return {
        "message": "Welcome to FlagForge API",
        "docs_url": "/docs",
        "status": "online"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}
