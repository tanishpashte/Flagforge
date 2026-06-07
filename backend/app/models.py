import enum
from typing import Optional, List, Dict, Any
from datetime import datetime
from sqlmodel import SQLModel, Field, Relationship, Column, JSON

# ==========================================
# ENUMS
# ==========================================
class ConfigType(str, enum.Enum):
    STRING = "string"
    NUMBER = "number"
    BOOLEAN = "boolean"

# ==========================================
# PROJECT MODEL
# ==========================================
class ProjectBase(SQLModel):
    name: str = Field(index=True, unique=True)
    description: Optional[str] = None

class Project(ProjectBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    flags: List["FeatureFlag"] = Relationship(back_populates="project", sa_relationship_kwargs={"cascade": "all, delete-orphan"})
    configs: List["RemoteConfig"] = Relationship(back_populates="project", sa_relationship_kwargs={"cascade": "all, delete-orphan"})

# ==========================================
# FEATURE FLAG MODEL
# ==========================================
class FeatureFlagBase(SQLModel):
    key: str = Field(index=True)
    description: Optional[str] = None
    is_enabled: bool = Field(default=False)
    rollout_percentage: int = Field(default=100) # 0 to 100 for hashing
    
    # Store dynamic rules as a JSON structure e.g., {"groups": ["beta"]}
    targeting_rules: Dict[str, Any] = Field(default_factory=dict, sa_column=Column(JSON))
    project_id: int = Field(foreign_key="project.id", index=True)

class FeatureFlag(FeatureFlagBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    project: Project = Relationship(back_populates="flags")

# ==========================================
# REMOTE CONFIG MODEL
# ==========================================
class RemoteConfigBase(SQLModel):
    key: str = Field(index=True)
    description: Optional[str] = None
    value_type: ConfigType = Field(default=ConfigType.STRING)
    value: str = Field(description="Stored as a string representation of the target type")
    project_id: int = Field(foreign_key="project.id", index=True)

class RemoteConfig(RemoteConfigBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    project: Project = Relationship(back_populates="configs")