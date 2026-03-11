# OpenSchool Platform — Telepítési útmutató

> 📖 **Dokumentáció:** [Főoldal](../../README.md) · [Architektúra](architektura.md) · **Telepítés** · [Éles telepítés](eles-telepites.md) · [Staging](staging-telepites.md) · [Környezeti változók](kornyezeti-valtozok.md) · [Fejlesztői útmutató](../development/fejlesztoi-utmutato.md) · [Backend](../development/backend-fejlesztes.md) · [Frontend](../development/frontend-fejlesztes.md) · [Tesztelés](../development/tesztelesi-utmutato.md) · [API referencia](../reference/api-referencia.md) · [Adatbázis](../reference/adatbazis-sema.md) · [Karbantartás](../operations/karbantartas-utmutato.md) · [Automatizálás](../operations/automatizalas-beallitas.md) · [GitHub Classroom](../integrations/github-classroom-integraciot.md) · [Discord](../integrations/discord-integracio.md) · [Felhasználói útmutató](../guides/felhasznaloi-utmutato.md) · [Dokumentálás](../guides/dokumentacios-utmutato.md) · [Roadmap](../jovokep-es-fejlesztesi-terv.md) · [Hozzájárulás](../../CONTRIBUTING.md)

Ez az útmutató a helyi fejlesztési környezet beállítását ismerteti. Az éles és staging telepítéshez lásd a külön dokumentumokat.

---

## Tartalomjegyzék

1. [Előfeltételek](#előfeltételek)
2. [Helyi fejlesztés (Docker)](#helyi-fejlesztés-docker)
3. [Helyi fejlesztés (Docker nélkül)](#helyi-fejlesztés-docker-nélkül)
4. [Környezeti változók](#környezeti-változók)
5. [Adatbázis és migrációk](#adatbázis-és-migrációk)
6. [GitHub OAuth beállítás](#github-oauth-beállítás)
7. [Tesztek futtatása](#tesztek-futtatása)

---

## Előfeltételek

- **Docker** 24+ és **Docker Compose** v2
- **Python** 3.12+ (helyi fejlesztéshez Docker nélkül)
- **Node.js** 20+ (frontend fejlesztéshez)
- **Git**
- **GitHub fiók** (OAuth alkalmazás létrehozásához)

---

## Helyi fejlesztés (Docker)

A leggyorsabb módja a teljes rendszer elindításának:

```bash
# Repó klónozása
git clone git@github.com:ghemrich/openschool-platform.git
cd openschool-platform

# Környezeti fájl létrehozása
cp .env.example .env
# Szerkeszd a .env fájlt a GitHub OAuth adataiddal (lásd "GitHub OAuth beállítás")

# Összes szolgáltatás indítása (backend, db, nginx, frontend)
docker compose up --build -d

# Ellenőrzés
curl http://localhost/health
# → {"status": "ok"}

# Logok megtekintése
docker compose logs -f backend
```

**Futó szolgáltatások:**

| Szolgáltatás | Port | Leírás                      |
|-------------|------|-----------------------------|
| nginx       | 80   | Reverse proxy (belépési pont)|
| backend     | 8000 | FastAPI API (belső)          |
| db          | 5432 | PostgreSQL 16                |
| frontend    | —    | Astro build (statikus fájlok)|

**Hasznos parancsok:**

```bash
make up        # docker compose up --build -d
make down      # docker compose down
make test      # pytest futtatás
make migrate   # alembic migrációk futtatása
make lint      # ruff ellenőrzés + formázás
```

---

## Helyi fejlesztés (Docker nélkül)

Backend fejlesztéshez:

```bash
cd backend

# Virtuális környezet létrehozása
python -m venv .venv
source .venv/bin/activate  # Linux/macOS
# .venv\Scripts\activate   # Windows

# Függőségek telepítése (produkció)
pip install -r requirements.txt
# Vagy fejlesztéshez (teszt, lint eszközökkel):
# pip install -r requirements-dev.txt

# Környezeti változók beállítása (vagy .env fájl a backend/ könyvtárban)
export DATABASE_URL="postgresql://openschool:openschool@localhost:5432/openschool"
export SECRET_KEY="change-me-in-production"
export BASE_URL="http://localhost"

# Migrációk futtatása
alembic upgrade head

# Szerver indítása
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Frontend fejlesztéshez:

```bash
cd frontend
npm install
npm run dev    # Astro dev szerver: http://localhost:4321
npm run build  # Statikus fájlok buildelése
```

---

## Környezeti változók

Hozz létre egy `.env` fájlt a projekt gyökérkönyvtárában (soha ne commitold):

```bash
# Adatbázis
DB_USER=openschool
DB_PASSWORD=openschool
DB_NAME=openschool
DATABASE_URL=postgresql://openschool:openschool@db:5432/openschool

# Biztonság
SECRET_KEY=change-me-in-production    # JWT aláíró kulcs — élesben random 64 karakteres stringet használj

# Platform
BASE_URL=http://localhost              # Tanúsítványok és QR kódok URL-jéhez
                                       # Élesben: https://yourdomain.com
ENVIRONMENT=development                # development vagy production
ALLOWED_ORIGINS=http://localhost,http://localhost:4321  # CORS engedélyezett eredetek

# GitHub OAuth
GITHUB_CLIENT_ID=your_client_id
GITHUB_CLIENT_SECRET=your_client_secret
```

| Változó | Kötelező | Leírás |
|---------|----------|--------|
| `DATABASE_URL` | Igen | PostgreSQL kapcsolati string |
| `SECRET_KEY` | Igen | JWT aláíró kulcs — élesben **egyedi és véletlenszerű** legyen |
| `BASE_URL` | Igen | A platform publikus URL-je (tanúsítványokhoz, QR kódokhoz) |
| `GITHUB_CLIENT_ID` | Igen | GitHub OAuth App kliens azonosító |
| `GITHUB_CLIENT_SECRET` | Igen | GitHub OAuth App kliens titkos kulcs |
| `GITHUB_ORG` | Nem | GitHub szervezet neve (Classroom integrációhoz) |
| `GITHUB_WEBHOOK_SECRET` | Nem | GitHub webhook titkos kulcs (Classroom webhookhoz) |
| `DB_USER` | Igen | PostgreSQL felhasználónév (docker-compose használja) |
| `DB_PASSWORD` | Igen | PostgreSQL jelszó (docker-compose használja) |
| `DB_NAME` | Igen | PostgreSQL adatbázisnév (docker-compose használja) |
| `ENVIRONMENT` | Nem | `development` vagy `production` — élesben kikapcsolja a Swagger UI-t |
| `ALLOWED_ORIGINS` | Nem | CORS engedélyezett eredetek, vesszővel elválasztva (pl. `https://yourdomain.com`) |

---

## Adatbázis és migrációk

A projekt **Alembic**-et használ az adatbázis migrációkhoz.

```bash
# Összes függőben lévő migráció futtatása
cd backend
alembic upgrade head

# Új migráció létrehozása modell módosítás után
alembic revision --autogenerate -m "leírás a változásról"

# Aktuális migrációs állapot ellenőrzése
alembic current

# Egy lépés visszavonása
alembic downgrade -1
```

Docker-en keresztül:

```bash
docker compose exec backend alembic upgrade head
```

---

## GitHub OAuth beállítás

1. Nyisd meg a [GitHub Developer Settings](https://github.com/settings/developers) oldalt
2. Kattints a **New OAuth App** gombra
3. Töltsd ki:
   - **Application name:** `OpenSchool` (vagy bármilyen név)
   - **Homepage URL:** `http://localhost` (vagy az éles domain)
   - **Authorization callback URL:** `http://localhost/api/auth/callback`
4. Kattints a **Register application** gombra
5. Másold ki a **Client ID**-t és generálj **Client Secret**-et
6. Add hozzá a `.env` fájlhoz:
   ```
   GITHUB_CLIENT_ID=Ov23li...
   GITHUB_CLIENT_SECRET=25a23e268e...
   ```

> **Fontos:** Éles környezethez hozz létre külön OAuth App-ot az éles domain-nel mint callback URL: `https://yourdomain.com/api/auth/callback`

---

## Tesztek futtatása

```bash
cd backend

# Összes teszt futtatása
pytest -v

# Adott tesztfájl futtatása
pytest tests/test_auth.py -v

# Lefedettségi riporttal
pytest --cov=app --cov-report=term-missing
```

A CI pipeline minden push és PR esetén automatikusan futtatja a teszteket.

---

## Következő lépések

| Feladat | Dokumentum |
|---------|-----------|
| Éles telepítés VPS-re (szerver, SSH, DNS, SSL, CI/CD) | [Éles telepítés](eles-telepites.md) |
| Staging környezet beüzemelése | [Staging telepítés](staging-telepites.md) |
| Karbantartás, backup, cron job-ok | [Automatizálás](../operations/automatizalas-beallitas.md) |
| Karbantartási munkafolyamatok | [Karbantartás](../operations/karbantartas-utmutato.md) |
| Környezeti változók referencia | [Környezeti változók](kornyezeti-valtozok.md) |

