<div align="center">

# Contacts Manager

### Flutter + FastAPI contact management platform

**A cross-platform address book with JWT authentication, contact photos and direct communication actions, backed by a FastAPI REST service and PostgreSQL persistence.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569D?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.0.0-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104.1-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)](https://python.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-4169E1?logo=postgresql&logoColor=white)](https://postgresql.org)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white)](https://docs.docker.com)
[![License](https://img.shields.io/badge/License-ISC-blue.svg)](LICENSE)

</div>

---

## Table of Contents

- [Project Overview](#project-overview)
- [Business Context and Problem Statement](#business-context-and-problem-statement)
- [Project Objectives](#project-objectives)
- [Main Features](#main-features)
- [System Architecture](#system-architecture)
- [Part I - Flutter Mobile Application](#part-i---flutter-mobile-application)
- [Part II - FastAPI Backend](#part-ii---fastapi-backend)
- [Part III - Data Layer, Authentication and File Storage](#part-iii---data-layer-authentication-and-file-storage)
- [Technology Stack](#technology-stack)
- [Database Architecture](#database-architecture)
- [API Reference](#api-reference)
- [Security and Access Control](#security-and-access-control)
- [Installation and Configuration](#installation-and-configuration)
- [Environment Variables](#environment-variables)
- [Running the Application](#running-the-application)
- [Docker Deployment](#docker-deployment)
- [Project Structure](#project-structure)
- [Testing and Validation](#testing-and-validation)
- [Current Limitations](#current-limitations)
- [Future Improvements](#future-improvements)
- [License](#license)

---

## Project Overview

Contacts Manager is a complete contact management solution built around a two-tier architecture: a **Flutter** client that ships to Android, iOS, Web, Windows, macOS and Linux from a single codebase, and a **FastAPI** REST service that exposes authentication, contact management and photo storage over HTTP/JSON.

The repository contains the Flutter application (`contacts_app/`) and the Python API (`backend/`), together with a containerised PostgreSQL deployment for the API and its database.

The product is designed around a simple operational need: a personal and professional address book that is available on every device, isolated per user, and able to act on a contact directly (call, WhatsApp, email, locate) without leaving the application.


---

## Business Context and Problem Statement

Contact lists are usually trapped in one of three places: a phone's address book, a shared spreadsheet, or a messaging application. Each of them fails in a predictable way:

- **No cross-device availability.** A contact saved on a work phone is not reachable from a laptop or the web.
- **No structured storage.** A spreadsheet has no schema, no validation, and no way to guarantee that a phone number or an email address is well formed.
- **No data ownership model.** A shared file is visible to everyone who opens it, so personal directories leak and sensitive entries cannot be separated.
- **Slow contact retrieval.** Finding a single person in a large flat list means scrolling, not searching.
- **High-friction communication.** Even after locating a contact, the user must still copy the number and switch applications.

Contacts Manager addresses these points by providing:

- A single codebase that runs on mobile, desktop and web, with a consistent user experience.
- A REST API that validates every field at the boundary and guarantees referential ownership.
- A per-user isolation model enforced server-side, so one user can never read or modify another user's directory.
- Instant, incremental search over name and telephone number.
- One-tap communication actions that hand off to the operating system: call, WhatsApp, email and map search.
- Contact photos captured with the device camera or picked from the gallery, stored and served by the API.

---

## Project Objectives

1. Provide a complete, working contact directory that runs identically on all six supported Flutter platforms.
2. Enforce **user data isolation at the API layer**, so that every read and write is scoped to the authenticated account.
3. Guarantee **data integrity** on contact records through server-side validation, uniqueness rules and foreign keys.
4. Keep credentials safe by never storing or transmitting a plain-text password, and by using short-lived, verifiable bearer tokens.
5. Reduce the friction between "finding a contact" and "contacting them" with direct, native actions.
6. Support rich contact records (photo, email, address, favourite flag) without compromising list performance.
7. Provide a reproducible deployment path through Docker Compose for both the API and its database.

---

## Main Features

The table below lists the capabilities **confirmed to exist in this repository**.

| Area | Confirmed capabilities |
| --- | --- |
| **Authentication** | Account registration, login, current-user retrieval, JWT issuance, token persistence across app restarts, explicit logout |
| **Contact management** | Create, read, update and delete contacts; per-user directory listing; alphabetical grouping; favourite flag |
| **Search** | Incremental search on full name and telephone number, executed client-side on the loaded directory |
| **Data integrity** | Unique e-mail per account, unique telephone number per user, mandatory first name / last name / telephone, optional e-mail and address |
| **Contact photos** | Capture with the camera or pick from the gallery, upload to the API, replace, delete, and display as a circular avatar with graceful fallback to initials |
| **Communication actions** | Direct call, WhatsApp deep link, e-mail composition and Google Maps address search through `url_launcher` |
| **Session UX** | Splash-free session restore, greeting header, confirmation dialog on logout, contextual error feedback via snackbars |
| **Cross-platform** | Android, iOS, Web, Windows, macOS and Linux from one Flutter codebase |
| **Deployment** | Multi-stage-ready `Dockerfile` and a `docker-compose.yml` stack with PostgreSQL, health checks and a persistent volume |

---

## System Architecture

```text
┌───────────────────────────────────────────────────────┐
│                   FLUTTER CLIENT                      │
│                                                       │
│  Login · Sign up · Contacts list · Contact detail    │
│  Add contact · Edit contact                          │
│                                                       │
│  ApiService (singleton)  ·  SharedPreferences store  │
└───────────────────────────┬───────────────────────────┘
                            │  HTTP / JSON
                            │  Authorization: Bearer <JWT>
                            │  Multipart/form-data (photos)
                            ▼
┌───────────────────────────────────────────────────────┐
│                   FASTAPI SERVICE                     │
│                                                       │
│  Pydantic schemas  ·  JWT verification dependency    │
│  Ownership filtering (user_id)  ·  CORS middleware   │
│  Static mount: /uploads  ·  OpenAPI at /docs         │
└───────────────────────────┬───────────────────────────┘
                            │  SQLAlchemy 2.x ORM
                            │  psycopg2 driver
                            ▼
┌───────────────────────────────────────────────────────┐
│                    POSTGRESQL 15                      │
│                                                       │
│  public.users      public.contacts                    │
│  (1 ── n relation, ON DELETE CASCADE)                 │
└───────────────────────────────────────────────────────┘

              ┌────────────────────────────────┐
              │  Filesystem: uploads/photos/    │
              │  served read-only via /uploads  │
              └────────────────────────────────┘
```

**Request lifecycle — every protected call follows the same path:**

1. The Flutter client attaches `Authorization: Bearer <token>` to the request.
2. FastAPI resolves `get_current_user`, which decodes the token, checks its signature and expiry, then loads the matching row from `users`.
3. The route handler queries the ORM with an explicit `user_id == current_user.id` filter.
4. The response is serialised through a Pydantic response model and returned as JSON.

---

## Part I - Flutter Mobile Application

### Purpose and Architecture

The Flutter application is the only user-facing component. It follows a deliberately small structure: two immutable data models, one service object that owns all network communication, and a set of pages that consume the service.

### Project configuration

| Setting | Value |
| --- | --- |
| Package name | `contacts_app` |
| Version | `1.0.0+1` |
| Dart SDK constraint | `>=3.0.0 <4.0.0` |
| Application label (iOS) | `Contacts App` |
| Primary theme colour | `#7C6FDC` |
| Surface / field colour | `#F3F2FF` |

### Application layers

```text
lib/
├── main.dart            Entry point, dependency bootstrap, theme and routes
├── models/
│   ├── user.dart        User entity + JSON (de)serialisation
│   └── contact.dart     Contact entity, derived helpers (fullName, initials, firstLetter)
├── services/
│   └── api_service.dart Singleton HTTP client, token handling, error mapping
└── pages/
    ├── login.dart               Sign-in screen with fade-in animation
    ├── signup.dart              Account creation screen
    ├── contacts_list.dart       Alphabetical directory, search, favourites, pull-to-refresh
    ├── contact_detail_page.dart Hero header, quick actions, information tiles
    ├── add_contact_page.dart    Creation form with photo capture
    └── edit_contact_page.dart   Update form with photo replacement
```

### Screens

| Screen | Confirmed behaviour |
| --- | --- |
| **Login** | Validated e-mail and password (minimum 6 characters), password visibility toggle, loading state on the button, success and error snackbars, navigation to the directory on success |
| **Sign up** | Last name, first name, telephone, e-mail and password; the session token issued at registration is stored immediately, so the user lands already authenticated |
| **Contacts list** | Greeting header, live search field, alphabetical section headers, avatar initials, favourite star, pull-to-refresh, floating add button, logout confirmation dialog and a dedicated empty state |
| **Contact detail** | Gradient collapsing header with a `Hero` avatar, favourite toggle, one-tap call / WhatsApp / e-mail / map actions, information tiles, and edit and delete entry points |
| **Add contact** | Form validation (name ≥ 2 characters, telephone ≥ 8 characters, e-mail format when provided), live telephone formatting, photo source sheet (camera / gallery / remove) and upload on save |
| **Edit contact** | Pre-filled form, current photo preview, replacement or removal of the photo, and save that persists the update |

### Design decisions

- **Singleton service with an explicit `init()`.** `ApiService.instance.init()` runs before `runApp`, so the first frame already knows whether a valid session exists. The home widget is resolved once: authenticated users open the directory, anonymous users open the login screen.
- **Incremental search on a local list.** The full directory is loaded once and filtered in memory on each keystroke against the full name and the telephone number, which keeps typing instant on large directories.
- **Photo fallback.** When no photo is available — or the network image fails to load — the avatar renders the contact's initials, so the list never shows a broken or empty tile.
- **Consistent visual identity.** A single purple accent (`#7C6FDC`) is used for buttons, icons, headers and section letters, on a light lavender surface (`#F3F2FF`) that keeps forms and cards visually separated from the white scaffold.

### The `ApiService` contract

| Method | Endpoint | Result |
| --- | --- | --- |
| `register(...)` | `POST /api/auth/register` | Stores the token, returns the `User` |
| `login(email, password)` | `POST /api/auth/login` | Stores the token, returns the `User` |
| `logout()` | — | Clears the in-memory session and the persisted token |
| `getContacts({search})` | `GET /api/contacts` | Returns `List<Contact>` |
| `getContact(id)` | `GET /api/contacts/{id}` | Returns a `Contact` |
| `createContact(contact)` | `POST /api/contacts` | Returns the created `Contact` |
| `updateContact(contact)` | `PUT /api/contacts/{id}` | Returns the updated `Contact` |
| `deleteContact(id)` | `DELETE /api/contacts/{id}` | No content |
| `uploadPhoto(id, file)` | `POST /api/contacts/{id}/photo` | Returns the stored photo path |
| `deletePhoto(id)` | `DELETE /api/contacts/{id}/photo` | No content |
| `getPhotoUrl(path)` | `GET /uploads/photos/{path}` | Builds the absolute URL of a stored photo |


---

## Part II - FastAPI Backend

### Service architecture

The API is a single-module FastAPI application (`backend/main.py`) that combines the HTTP layer, the authentication logic, the ORM models and the file handling. The design keeps the surface area small and the behaviour explicit.

### Middleware and application setup

| Component | Configuration |
| --- | --- |
| CORS | `allow_origins=["*"]`, `allow_credentials=True`, all methods and headers |
| Static files | `uploads/` is mounted and served at `/uploads` |
| Authentication scheme | `HTTPBearer` — the token is read from the `Authorization: Bearer` header |
| Interactive documentation | Available at `/docs` (Swagger UI) and `/redoc` (ReDoc) |
| Schema creation | `Base.metadata.create_all()` runs at import time |

### Route summary

| Method | Path | Responsibility | Access |
| --- | --- | --- | --- |
| `POST` | `/api/auth/register` | Create an account and return a token | Public |
| `POST` | `/api/auth/login` | Verify credentials and return a token | Public |
| `GET` | `/api/auth/me` | Return the authenticated profile | Bearer token |
| `GET` | `/api/contacts` | List the user's contacts, optional `?search=` | Bearer token |
| `GET` | `/api/contacts/{contact_id}` | Return one contact | Bearer token + owner |
| `POST` | `/api/contacts` | Create a contact | Bearer token |
| `PUT` | `/api/contacts/{contact_id}` | Update a contact | Bearer token + owner |
| `DELETE` | `/api/contacts/{contact_id}` | Delete a contact and its photo | Bearer token + owner |
| `POST` | `/api/contacts/{contact_id}/photo` | Upload or replace the contact photo | Bearer token + owner |
| `DELETE` | `/api/contacts/{contact_id}/photo` | Remove the contact photo | Bearer token + owner |
| `GET` | `/uploads/photos/{filename}` | Serve a stored photo | Public |
| `GET` | `/` | Service banner | Public |
| `GET` | `/health` | Health probe | Public |

### Validation rules enforced by the API

- **Registration** — the e-mail must be valid and not already registered; the password is hashed with bcrypt before it is stored.
- **Creation** — `nom`, `prenom` and `telephone` are mandatory; `email` and `adresse` are optional; the telephone number must not already exist for the same user.
- **Update** — the same telephone uniqueness rule applies, excluding the record being updated; only the fields present in the payload are modified.
- **Photo upload** — the MIME type must be one of `image/jpeg`, `image/jpg`, `image/png` or `image/webp`.
- **Ownership** — reading, updating, deleting and photo operations all require `contact.user_id == current_user.id`. A contact belonging to another account returns `404`, never `403`, so the existence of another user's record is not disclosed.

### Error contract

| Status | Meaning | Example message |
| --- | --- | --- |
| `400` | Business rule violated | `Email déjà utilisé`, `Ce numéro de téléphone existe déjà` |
| `401` | Missing, invalid or expired token | `Invalid token`, `Token expired`, `User not found` |
| `404` | Resource absent or not owned by the caller | `Contact non trouvé` |
| `422` | Pydantic schema validation failed | Field-level validation details |

---

## Part III - Data Layer, Authentication and File Storage

### Authentication lifecycle

1. The client submits credentials to `POST /api/auth/login`.
2. The API looks up the user by e-mail and compares the submitted password against the stored bcrypt hash with `bcrypt.checkpw`.
3. On success, a JWT is issued containing the `user_id` claim and an expiry seven days in the future, signed with `HS256`.
4. The client persists the token under the `auth_token` key in `SharedPreferences`.
5. Every subsequent request sends the token in the `Authorization: Bearer <token>` header.
6. `get_current_user` decodes the token, rejects an invalid signature or an expired token, and loads the corresponding user row. A token pointing at a deleted account is therefore rejected as well.
7. `logout()` clears the token both in memory and from `SharedPreferences`, and the client returns to the login screen.

### Token specification

| Property | Value |
| --- | --- |
| Algorithm | `HS256` |
| Signing key | `SECRET_KEY` environment variable |
| Payload | `user_id` (integer) and `exp` (expiry timestamp) |
| Lifetime | 7 days (`ACCESS_TOKEN_EXPIRE_MINUTES = 60 × 24 × 7`) |
| Transport | `Authorization: Bearer <token>` |

### Password storage

Passwords are hashed with **bcrypt** using a per-password random salt (`bcrypt.gensalt()`) and are never returned by any endpoint. The `UserResponse` schema exposes only the identifier, name, e-mail, telephone and creation date.

### Contact photo storage

- Photos are written to `backend/uploads/photos/`, which is created automatically at start-up.
- The stored file name combines the user id, the contact id and a timestamp — `{user_id}_{contact_id}_{timestamp}{extension}` — which prevents collisions between two accounts.
- Only the **file name** is persisted in the `contacts.photo_path` column; the directory is reconstructed at read time.
- Uploading a new photo deletes the previous file, and deleting a contact removes its photo from the disk before the database row is removed.
- The `uploads` directory is served read-only as static content at `/uploads`.

---

## Technology Stack

| Layer | Technologies confirmed in the repository |
| --- | --- |
| **Frontend** | Flutter, Dart (≥ 3.0.0), Material 3 widgets, `http`, `shared_preferences`, `image_picker`, `url_launcher`, `font_awesome_flutter`, `cupertino_icons` |
| **Backend** | Python 3.11, FastAPI 0.104.1, Uvicorn 0.24.0, Pydantic v2 (`pydantic[email]`), `python-multipart` |
| **Data access** | SQLAlchemy 2.0.23 (ORM), `psycopg2-binary` 2.9.9, PostgreSQL 15 |
| **Authentication** | PyJWT 2.8.0 (HS256), bcrypt 4.1.1, `HTTPBearer` security scheme |
| **File storage** | Local filesystem under `uploads/photos`, served through Starlette `StaticFiles` |
| **Packaging** | `requirements.txt` with pinned versions, `Dockerfile` on `python:3.11-slim` |
| **Orchestration** | Docker Compose with a PostgreSQL service, health check and named volume |
| **Quality** | `flutter_lints` 3.0.0, `flutter_test` for widget tests, `flutter analyze` |

---

## Database Architecture

The API uses a single PostgreSQL database, `contacts_db`, with two tables managed through SQLAlchemy declarative models.

### `users`

| Column | Type | Constraints | Role |
| --- | --- | --- | --- |
| `id` | `Integer` | Primary key, indexed | Identifier |
| `nom` | `String` | Not null | Last name |
| `prenom` | `String` | Not null | First name |
| `email` | `String` | Unique, indexed, not null | Login identifier |
| `telephone` | `String` | Not null | Contact number |
| `password` | `String` | Not null | bcrypt hash — never returned by the API |
| `created_at` | `DateTime` | Default `utcnow` | Account creation timestamp |

### `contacts`

| Column | Type | Constraints | Role |
| --- | --- | --- | --- |
| `id` | `Integer` | Primary key, indexed | Identifier |
| `user_id` | `Integer` | Foreign key → `users.id`, not null, indexed | Owner of the record |
| `nom` | `String` | Not null | Last name |
| `prenom` | `String` | Not null | First name |
| `email` | `String` | Nullable | E-mail address |
| `telephone` | `String` | Not null | Telephone number, unique per user |
| `adresse` | `String` | Nullable | Postal address |
| `photo_path` | `String` | Nullable | File name inside `uploads/photos` |
| `is_favorite` | `Boolean` | Default `False` | Favourite flag |
| `created_at` | `DateTime` | Default `utcnow` | Creation timestamp |

### Relationships

```text
users 1 ────────── n contacts
      │                    │
      │                    └── photo_path → uploads/photos/{file}
      └── id ← user_id
```

The ORM relationship is declared with `cascade="all, delete-orphan"`, so removing a user removes the contacts that belong to it.


## API Reference

### Authentication

<details open>
<summary><code>POST /api/auth/register</code> — create an account</summary>

**Request**

```json
{
  "nom": "Benali",
  "prenom": "Sami",
  "email": "sami.benali@example.com",
  "telephone": "+216 20 123 456",
  "password": "secret123"
}
```

**Response `200`**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "nom": "Benali",
    "prenom": "Sami",
    "email": "sami.benali@example.com",
    "telephone": "+216 20 123 456",
    "created_at": "2024-05-12T09:14:00"
  }
}
```

**Errors** — `400` if the e-mail is already registered, `422` on schema validation failure.
</details>

<details>
<summary><code>POST /api/auth/login</code> — obtain a token</summary>

**Request**

```json
{ "email": "sami.benali@example.com", "password": "secret123" }
```

**Response** — identical to the registration response. **Errors** — `401` if the credentials do not match.
</details>

<details>
<summary><code>GET /api/auth/me</code> — current user</summary>

Requires `Authorization: Bearer <token>`. Returns the `UserResponse` of the authenticated account.
</details>

### Contact endpoints

| Method | Path | Body / query | Success |
| --- | --- | --- | --- |
| `GET` | `/api/contacts` | `?search=` optional | `200` — array of contacts |
| `GET` | `/api/contacts/{id}` | — | `200` — one contact |
| `POST` | `/api/contacts` | `ContactCreate` | `201` — created contact |
| `PUT` | `/api/contacts/{id}` | `ContactUpdate` | `200` — updated contact |
| `DELETE` | `/api/contacts/{id}` | — | `204` — no content |

**`ContactCreate`**

```json
{
  "nom": "Jlassi",
  "prenom": "Nour",
  "email": "nour.jlassi@example.com",
  "telephone": "+216 25 987 654",
  "adresse": "12 rue de la Liberté, Hammamet",
  "is_favorite": false
}
```

**`ContactUpdate`** accepts the same fields, all optional; only the supplied keys are modified.

**`ContactResponse`**

```json
{
  "id": 12,
  "user_id": 1,
  "nom": "Jlassi",
  "prenom": "Nour",
  "email": "nour.jlassi@example.com",
  "telephone": "+216 25 987 654",
  "adresse": "12 rue de la Liberté, Hammamet",
  "photo_path": "1_12_1715491234.5.png",
  "is_favorite": false,
  "created_at": "2024-05-12T10:02:00"
}
```

### Photos

| Method | Path | Content type | Success |
| --- | --- | --- | --- |
| `POST` | `/api/contacts/{id}/photo` | `multipart/form-data` (field `file`) | `200` — `{ "photo_path": "1_12_1715491234.5.png" }` |
| `DELETE` | `/api/contacts/{id}/photo` | — | `204` — no content |

Accepted image types: `image/jpeg`, `image/jpg`, `image/png`, `image/webp`.

### Service endpoints

| Method | Path | Response |
| --- | --- | --- |
| `GET` | `/` | `{ "message": "API Contacts - Bienvenue" }` |
| `GET` | `/health` | `{ "status": "healthy" }` |

---


## Security and Access Control

**Implemented in this repository**

- **Password hashing.** Passwords are hashed with bcrypt and a random salt; the plain-text value never leaves the request handler and is never returned by the API.
- **Token verification.** Every protected route depends on `get_current_user`, which verifies the HS256 signature and the expiry before the handler runs.
- **Session invalidation.** The token is resolved against the database on each request, so an account deleted after the token was issued can no longer access the API.
- **Ownership filtering.** All contact queries include `user_id == current_user.id`. Isolation is enforced by the API and does not rely on any client-side filtering.
- **Non-disclosure of foreign records.** A request for a contact owned by another account returns `404`, not `403`.
- **Validated uploads.** Only the four whitelisted image MIME types are accepted, and stored file names are generated server-side rather than derived from the client-supplied name.
- **Photo cleanup.** Orphaned image files are removed when a photo is replaced or a contact is deleted.
- **Secrets out of the repository.** `.env`, `uploads/`, `venv/` and build artefacts are listed in `.gitignore` and are never committed.

**Required for a production deployment**

- Override `SECRET_KEY` with a strong, unique value — the default shipped in the code is public and must never be used outside local development.
- Replace the wildcard CORS configuration with the explicit list of allowed frontend origins.
- Terminate TLS in front of the API and serve the Flutter client over HTTPS; the current setup uses plain HTTP.
- Add rate limiting on `/api/auth/login` and `/api/auth/register` to slow down credential stuffing.
- Apply an upload size limit to the photo endpoint, which currently validates the type but not the size.
- Restrict the PostgreSQL role used by the API to the `contacts_db` database, and never expose the database port publicly.

---

## Installation and Configuration

### Prerequisites

| Requirement | Version |
| --- | --- |
| Flutter SDK | 3.x (Dart ≥ 3.0.0) |
| Python | 3.11 (3.10+ works) |
| PostgreSQL | 15 (or any compatible version) |
| Docker + Docker Compose | Optional, for the containerised stack |

### 1 — Clone the repository

```bash
git clone https://github.com/Achref-004/Fllutter-Project.git
cd Fllutter-Project
```

### 2 — Start the backend

```bash
cd backend
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

Create a `.env`-style configuration or export the environment variables described in the next section, then start the API:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```



### 3 — Start the Flutter client

```bash
cd contacts_app
flutter pub get
flutter run
```


### 4 — Create the first account

Use the **Sign up** screen in the application, or call the API directly:

```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "Benali",
    "prenom": "Sami",
    "email": "sami.benali@example.com",
    "telephone": "+216 20 123 456",
    "password": "secret123"
  }'
```

---


## Docker Deployment

The `backend/` directory contains a complete containerised stack.

```bash
cd backend
docker compose up --build
```

**Services**

| Service | Image | Port | Purpose |
| --- | --- | --- | --- |
| `postgres` | `postgres:15` | `5432` | Application database, persisted in the `postgres_data` volume |
| `api` | Built from `backend/Dockerfile` | `8000` | FastAPI application with Uvicorn and auto-reload |

The API waits for the database to report healthy (`pg_isready`) before it starts. The `uploads` directory and `main.py` are bind-mounted, so the uploaded photos and the source code stay visible from the host during development.

> The `docker-compose.yml` ships with development credentials. Replace the `POSTGRES_PASSWORD` and `SECRET_KEY` values, and load them from a `.env` file, before any deployment outside a local machine.

---

## Project Structure

```text
Fllutter-Project/
├── README.md                       Project documentation
├── .gitignore                      Ignores uploads, secrets, virtualenvs and build output
├── backend/                        Python REST API
│   ├── main.py                     Application, ORM models, schemas, routes, auth
│   ├── requirements.txt            Pinned Python dependencies
│   ├── Dockerfile                  python:3.11-slim image definition
│   ├── docker-compose.yml          PostgreSQL + API stack
│   └── uploads/photos/             Runtime photo storage (not versioned)
│
└── contacts_app/                   Flutter application
    ├── pubspec.yaml                Package manifest and dependencies
    ├── analysis_options.yaml       flutter_lints configuration
    ├── assets/                     login_img.webp, singup_img.jpg
    ├── lib/
    │   ├── main.dart               Entry point, theme, named routes
    │   ├── models/                 user.dart, contact.dart
    │   ├── services/               api_service.dart
    │   └── pages/                  login, signup, contacts_list,
    │                               contact_detail, add_contact, edit_contact
    ├── test/                       widget_test.dart
    ├── android/                    Android runner, manifest, Gradle build
    ├── ios/                        iOS runner, Info.plist, Xcode project
    ├── web/                        Web runner, manifest, icons
    ├── windows/                    Windows runner
    ├── macos/                      macOS runner
    └── linux/                      Linux runner
```

---

## Testing and Validation


### Static analysis and tests

```bash
cd contacts_app
flutter analyze          # Static analysis against flutter_lints
flutter test             # Widget test suite
```

### Build validation

```bash
cd contacts_app
flutter build web        # Web build
flutter build apk        # Android build
```

---

## Current Limitations

The following points describe the current state of the code and should be addressed before a production release.


- **No upload size limit.** The photo endpoint checks the MIME type but not the file size, which leaves the server exposed to oversized uploads.
- **No rate limiting or account lockout.** The authentication endpoints can be called without restriction, and there is no protection against credential stuffing.
- **No password recovery.** There is no forgotten-password flow, no e-mail verification and no forced password rotation.
- **Token lifetime is not configurable.** The seven-day lifetime is hardcoded in `main.py` instead of being read from the environment.
- **Local photo storage.** Images are written to the local filesystem, so they are not shared between replicas and disappear with the container unless a volume is mounted.

---

## Future Improvements

1. **Introduce Alembic migrations** and a versioned schema, with a repeatable upgrade path from any deployed revision.
2. **Split the backend into modules** — routers, schemas, models and services — to keep the API layer maintainable as it grows.
3. **Add a complete test suite**: `pytest` for the API (auth, ownership, validation, uploads) and meaningful widget tests for the Flutter client.
4. **Implement a secure password recovery flow** with single-use, expiring reset tokens, plus e-mail verification on registration.
5. **Harden the API for production**: strict CORS, rate limiting, upload size limits, request validation limits, security headers and structured logging.


---



**Achref Bejaoui**

Master's student in Data Science, with a degree in Business Computing.

Areas of interest:

- Data Science
- Data Analytics
- Artificial Intelligence
- Mobile Engineering
- Backend Engineering
- Data Engineering

[LinkedIn](https://linkedin.com/in/achref-bejaoui00) · [GitHub](https://github.com/Achref-004)

---

## License

This project is distributed under the ISC License. See [`LICENSE`](LICENSE).

