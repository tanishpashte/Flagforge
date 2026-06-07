from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from typing import List
from datetime import datetime
from backend.app.database import get_session
from backend.app.models import FeatureFlag, FeatureFlagBase
from backend.app.ws_manager import manager

router = APIRouter(prefix="/api/flags", tags=["Feature Flags"])

@router.post("/", response_model=FeatureFlag, status_code=status.HTTP_201_CREATED)
def create_flag(flag: FeatureFlagBase, session: Session = Depends(get_session)):
    # Ensure flag key is unique within the project scope
    statement = select(FeatureFlag).where(
        FeatureFlag.key == flag.key, 
        FeatureFlag.project_id == flag.project_id
    )
    if session.exec(statement).first():
        raise HTTPException(status_code=400, detail="Flag key already exists in this project")
        
    db_flag = FeatureFlag.from_orm(flag)
    session.add(db_flag)
    session.commit()
    session.refresh(db_flag)
    return db_flag

@router.patch("/{flag_id}/toggle", response_model=FeatureFlag)
async def toggle_flag(flag_id: int, session: Session = Depends(get_session)):
    db_flag = session.get(FeatureFlag, flag_id)
    if not db_flag:
        raise HTTPException(status_code=404, detail="Flag not found")
    
    # Flip the switch!
    db_flag.is_enabled = not db_flag.is_enabled
    db_flag.updated_at = datetime.utcnow()
    
    session.add(db_flag)
    session.commit()
    session.refresh(db_flag)
    
    await manager.broadcast_to_project(db_flag.project_id, {
        "type": "flag",
        "key": db_flag.key,
        "is_enabled": db_flag.is_enabled,
        "action": "update"
    })
    return db_flag