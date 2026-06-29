from sqlmodel import SQLModel, create_engine, Session
from fastapi import Depends

sqlite_file_name = "flagforge.db"
sqlite_url = f"sqlite:///{sqlite_file_name}"

# check_same_thread=False is essential for FastAPI's multi-threaded worker paths
connect_args = {"check_same_thread": False}
engine = create_engine(sqlite_url, echo=False, connect_args=connect_args)

def init_db():
    SQLModel.metadata.create_all(engine)
    
    # Seed default data for E2E testing
    from backend.app.models import Project, FeatureFlag, RemoteConfig, ConfigType
    from sqlmodel import select
    
    with Session(engine) as session:
        # 1. Ensure Project 1 exists
        project = session.get(Project, 1)
        if not project:
            # Check if name "Default Project" is already taken
            statement = select(Project).where(Project.name == "Default Project")
            existing_by_name = session.exec(statement).first()
            if existing_by_name:
                existing_by_name.name = f"Default Project Legacy ({existing_by_name.id})"
                session.add(existing_by_name)
                try:
                    session.commit()
                except Exception:
                    session.rollback()

            project = Project(id=1, name="Default Project", description="Default development project")
            session.add(project)
            try:
                session.commit()
            except Exception:
                session.rollback()
                # If ID 1 conflict or name conflict, fetch existing
                statement = select(Project).where(Project.name == "Default Project")
                project = session.exec(statement).first()
                if not project:
                    project = session.exec(select(Project)).first()
            if project:
                session.refresh(project)
                
        # If we still don't have a project, let's get any project or use project.id if we found one
        project_id = project.id if project else 1
        
        # 2. Seed Feature Flags if they do not exist
        required_flags = [
            {"key": "dark_mode", "description": "Toggle dark mode in client app", "is_enabled": True},
            {"key": "premium_theme", "description": "Enable premium client theme", "is_enabled": False},
            {"key": "show_banner", "description": "Toggle dynamic top campaign banner", "is_enabled": True},
        ]
        
        for flag_data in required_flags:
            statement = select(FeatureFlag).where(
                FeatureFlag.key == flag_data["key"],
                FeatureFlag.project_id == project_id
            )
            existing_flag = session.exec(statement).first()
            if not existing_flag:
                new_flag = FeatureFlag(
                    key=flag_data["key"],
                    description=flag_data["description"],
                    is_enabled=flag_data["is_enabled"],
                    project_id=project_id
                )
                session.add(new_flag)
                
        # 3. Seed Remote Configs if they do not exist
        required_configs = [
            {
                "key": "banner_message",
                "description": "Welcome banner message",
                "value_type": ConfigType.STRING,
                "value": "Welcome to FlagForge Live Backend Sync!"
            },
            {
                "key": "theme_accent_color",
                "description": "Hex color code for application accent",
                "value_type": ConfigType.STRING,
                "value": "#89B4FA"
            }
        ]
        
        for config_data in required_configs:
            statement = select(RemoteConfig).where(
                RemoteConfig.key == config_data["key"],
                RemoteConfig.project_id == project_id
            )
            existing_config = session.exec(statement).first()
            if not existing_config:
                new_config = RemoteConfig(
                    key=config_data["key"],
                    description=config_data["description"],
                    value_type=config_data["value_type"],
                    value=config_data["value"],
                    project_id=project_id
                )
                session.add(new_config)
                
        session.commit()

def get_session():
    with Session(engine) as session:
        yield session

async def update_remote_config(key: str, value: str):
    from sqlmodel import select
    from backend.app.models import RemoteConfig
    from backend.app.ws_manager import manager
    from datetime import datetime
    
    with Session(engine) as session:
        statement = select(RemoteConfig).where(RemoteConfig.key == key)
        db_config = session.exec(statement).first()
        if not db_config:
            raise ValueError(f"Configuration with key '{key}' not found.")
            
        db_config.value = value
        db_config.updated_at = datetime.utcnow()
        session.add(db_config)
        session.commit()
        session.refresh(db_config)
        
        await manager.broadcast_to_project(db_config.project_id, {
            "type": "config",
            "key": db_config.key,
            "value_type": db_config.value_type,
            "value": db_config.value,
            "action": "update"
        })
        
        return db_config