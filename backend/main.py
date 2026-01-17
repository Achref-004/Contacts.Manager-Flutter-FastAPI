from fastapi import FastAPI, HTTPException, Depends, File, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.staticfiles import StaticFiles
from sqlalchemy import create_engine, Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship
from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime, timedelta
import jwt
import bcrypt
import os
import shutil
from pathlib import Path

# Configuration
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@postgres:5432/contacts_db")
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-this-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 jours

# Base de données
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Dossier pour les photos
UPLOAD_DIR = Path("uploads/photos")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

# Modèles SQLAlchemy
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    nom = Column(String, nullable=False)
    prenom = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    telephone = Column(String, nullable=False)
    password = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    contacts = relationship("Contact", back_populates="user", cascade="all, delete-orphan")

class Contact(Base):
    __tablename__ = "contacts"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    nom = Column(String, nullable=False)
    prenom = Column(String, nullable=False)
    email = Column(String, nullable=True)
    telephone = Column(String, nullable=False)
    adresse = Column(String, nullable=True)
    photo_path = Column(String, nullable=True)
    is_favorite = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", back_populates="contacts")

# Créer les tables
Base.metadata.create_all(bind=engine)

# Schémas Pydantic
class UserCreate(BaseModel):
    nom: str
    prenom: str
    email: EmailStr
    telephone: str
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    nom: str
    prenom: str
    email: str
    telephone: str
    created_at: datetime
    
    class Config:
        from_attributes = True

class ContactCreate(BaseModel):
    nom: str
    prenom: str
    email: Optional[str] = None
    telephone: str
    adresse: Optional[str] = None
    is_favorite: bool = False

class ContactUpdate(BaseModel):
    nom: Optional[str] = None
    prenom: Optional[str] = None
    email: Optional[str] = None
    telephone: Optional[str] = None
    adresse: Optional[str] = None
    is_favorite: Optional[bool] = None

class ContactResponse(BaseModel):
    id: int
    user_id: int
    nom: str
    prenom: str
    email: Optional[str]
    telephone: str
    adresse: Optional[str]
    photo_path: Optional[str]
    is_favorite: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

# FastAPI app
app = FastAPI(title="Contacts API")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Servir les fichiers statiques (photos)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

security = HTTPBearer()

# Dépendances
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    try:
        token = credentials.credentials
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: int = payload.get("user_id")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")
    return user

# Routes Authentification
@app.post("/api/auth/register", response_model=TokenResponse)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    # Vérifier si l'email existe
    if db.query(User).filter(User.email == user_data.email).first():
        raise HTTPException(status_code=400, detail="Email déjà utilisé")
    
    # Créer l'utilisateur
    hashed_pwd = hash_password(user_data.password)
    user = User(
        nom=user_data.nom,
        prenom=user_data.prenom,
        email=user_data.email,
        telephone=user_data.telephone,
        password=hashed_pwd
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Créer le token
    token = create_access_token({"user_id": user.id})
    
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user=UserResponse.from_orm(user)
    )

@app.post("/api/auth/login", response_model=TokenResponse)
def login(login_data: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == login_data.email).first()
    
    if not user or not verify_password(login_data.password, user.password):
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")
    
    token = create_access_token({"user_id": user.id})
    
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user=UserResponse.from_orm(user)
    )

@app.get("/api/auth/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return UserResponse.from_orm(current_user)

# Routes Contacts
@app.get("/api/contacts", response_model=List[ContactResponse])
def get_contacts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    search: Optional[str] = None
):
    query = db.query(Contact).filter(Contact.user_id == current_user.id)
    
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            (Contact.nom.ilike(search_term)) |
            (Contact.prenom.ilike(search_term)) |
            (Contact.telephone.like(search_term))
        )
    
    contacts = query.order_by(Contact.nom).all()
    return [ContactResponse.from_orm(c) for c in contacts]

@app.get("/api/contacts/{contact_id}", response_model=ContactResponse)
def get_contact(
    contact_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    contact = db.query(Contact).filter(
        Contact.id == contact_id,
        Contact.user_id == current_user.id
    ).first()
    
    if not contact:
        raise HTTPException(status_code=404, detail="Contact non trouvé")
    
    return ContactResponse.from_orm(contact)

@app.post("/api/contacts", response_model=ContactResponse, status_code=status.HTTP_201_CREATED)
def create_contact(
    contact_data: ContactCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Vérifier si le téléphone existe déjà
    existing = db.query(Contact).filter(
        Contact.user_id == current_user.id,
        Contact.telephone == contact_data.telephone
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail="Ce numéro de téléphone existe déjà")
    
    contact = Contact(
        user_id=current_user.id,
        nom=contact_data.nom,
        prenom=contact_data.prenom,
        email=contact_data.email,
        telephone=contact_data.telephone,
        adresse=contact_data.adresse,
        is_favorite=contact_data.is_favorite
    )
    
    db.add(contact)
    db.commit()
    db.refresh(contact)
    
    return ContactResponse.from_orm(contact)

@app.put("/api/contacts/{contact_id}", response_model=ContactResponse)
def update_contact(
    contact_id: int,
    contact_data: ContactUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    contact = db.query(Contact).filter(
        Contact.id == contact_id,
        Contact.user_id == current_user.id
    ).first()
    
    if not contact:
        raise HTTPException(status_code=404, detail="Contact non trouvé")
    
    # Vérifier le téléphone si modifié
    if contact_data.telephone and contact_data.telephone != contact.telephone:
        existing = db.query(Contact).filter(
            Contact.user_id == current_user.id,
            Contact.telephone == contact_data.telephone,
            Contact.id != contact_id
        ).first()
        
        if existing:
            raise HTTPException(status_code=400, detail="Ce numéro de téléphone existe déjà")
    
    # Mise à jour
    update_data = contact_data.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(contact, key, value)
    
    db.commit()
    db.refresh(contact)
    
    return ContactResponse.from_orm(contact)

@app.delete("/api/contacts/{contact_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_contact(
    contact_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    contact = db.query(Contact).filter(
        Contact.id == contact_id,
        Contact.user_id == current_user.id
    ).first()
    
    if not contact:
        raise HTTPException(status_code=404, detail="Contact non trouvé")
    
    # Supprimer la photo si elle existe
    if contact.photo_path:
        photo_file = UPLOAD_DIR / contact.photo_path
        if photo_file.exists():
            photo_file.unlink()
    
    db.delete(contact)
    db.commit()

@app.post("/api/contacts/{contact_id}/photo")
def upload_photo(
    contact_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    contact = db.query(Contact).filter(
        Contact.id == contact_id,
        Contact.user_id == current_user.id
    ).first()
    
    if not contact:
        raise HTTPException(status_code=404, detail="Contact non trouvé")
    
    # Vérifier le type de fichier
    allowed_types = ["image/jpeg", "image/jpg", "image/png", "image/webp"]
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=400, detail="Format d'image non supporté")
    
    # Supprimer l'ancienne photo
    if contact.photo_path:
        old_photo = UPLOAD_DIR / contact.photo_path
        if old_photo.exists():
            old_photo.unlink()
    
    # Sauvegarder la nouvelle photo
    file_extension = Path(file.filename).suffix
    filename = f"{current_user.id}_{contact_id}_{datetime.now().timestamp()}{file_extension}"
    file_path = UPLOAD_DIR / filename
    
    with file_path.open("wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    contact.photo_path = filename
    db.commit()
    
    return {"photo_path": filename}

@app.delete("/api/contacts/{contact_id}/photo", status_code=status.HTTP_204_NO_CONTENT)
def delete_photo(
    contact_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    contact = db.query(Contact).filter(
        Contact.id == contact_id,
        Contact.user_id == current_user.id
    ).first()
    
    if not contact:
        raise HTTPException(status_code=404, detail="Contact non trouvé")
    
    if contact.photo_path:
        photo_file = UPLOAD_DIR / contact.photo_path
        if photo_file.exists():
            photo_file.unlink()
        
        contact.photo_path = None
        db.commit()

# Routes de test
@app.get("/")
def root():
    return {"message": "API Contacts - Bienvenue"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)