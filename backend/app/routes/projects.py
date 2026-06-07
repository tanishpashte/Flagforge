from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from typing import List
from backend.app.database import get_session
from backend.app.models import Project, ProjectBase

router = APIRouter(prefix="/api/projects", tags=["Projects"])

@router.post("/", response_model=Project, status_code=status.HTTP_201_CREATED)
def create_project(project: ProjectBase, session: Session = Depends(get_session)):
    # Check if name already exists
    statement = select(Project).where(Project.name == project.name)
    existing = session.exec(statement).first()
    if existing:
        raise HTTPException(status_code=400, detail="Project name already exists")
    
    db_project = Project.from_orm(project)
    session.add(db_project)
    session.commit()
    session.refresh(db_project)
    return db_project

@router.get("/", response_model=List[Project])
def read_projects(session: Session = Depends(get_session)):
    return session.exec(select(Project)).all()