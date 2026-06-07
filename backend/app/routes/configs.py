from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from typing import List
from datetime import datetime
from backend.app.database import get_session
from backend.app.models import RemoteConfig, RemoteConfigBase

router = APIRouter(prefix="/api/configs", tags=["Remote Configurations"])

@router.post("/", response_model=RemoteConfig, status_code=status.HTTP_201_CREATED)
def create_config(config: RemoteConfigBase, session: Session = Depends(get_session)):
    # Ensure config key is globally unique within the project scope
    statement = select(RemoteConfig).where(
        RemoteConfig.key == config.key,
        RemoteConfig.project_id == config.project_id
    )
    if session.exec(statement).first():
        raise HTTPException(status_code=400, detail="Config key already exists in this project")
        
    db_config = RemoteConfig.from_orm(config)
    session.add(db_config)
    session.commit()
    session.refresh(db_config)
    return db_config

@router.get("/", response_model=List[RemoteConfig])
def read_configs(project_id: int, session: Session = Depends(get_session)):
    statement = select(RemoteConfig).where(RemoteConfig.project_id == project_id)
    return session.exec(statement).all()

@router.patch("/{config_id}", response_model=RemoteConfig)
def update_config(config_id: int, updated_fields: RemoteConfigBase, session: Session = Depends(get_session)):
    db_config = session.get(RemoteConfig, config_id)
    if not db_config:
        raise HTTPException(status_code=404, detail="Configuration not found")
        
    # Dynamically extract and update fields sent in the request body
    config_data = updated_fields.dict(exclude_unset=True)
    for key, value in config_data.items():
        setattr(db_config, key, value)
        
    db_config.updated_at = datetime.utcnow()
    
    session.add(db_config)
    session.commit()
    session.refresh(db_config)
    
    # TODO: Trigger WebSocket Broadcast here in Phase 3!
    return db_config

@router.delete("/{config_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_config(config_id: int, session: Session = Depends(get_session)):
    db_config = session.get(RemoteConfig, config_id)
    if not db_config:
        raise HTTPException(status_code=404, detail="Configuration not found")
        
    session.delete(db_config)
    session.commit()
    # TODO: Trigger WebSocket Broadcast here
    return None