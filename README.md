# OpenSchool Platform

**Nyílt forráskódú oktatási platform, amely a valódi fejlesztői munkafolyamatokra építi a programozástanulást.**

---

## A probléma

A programozásoktatás a legtöbb iskolában egy zárt rendszerben zajlik: a diák feltölt egy fájlt, a tanár kézzel javít, a visszajelzés napokkal később érkezik. A diák megtanulja a nyelv szintaxisát, de nem találkozik verziókezeléssel, automatikus tesztekkel vagy csapatkommunikációval — azokkal az eszközökkel, amelyeket az első munkanapján használnia kell majd.

A tanár oldalán ez tükröződik: félévente kézzel épít fel repókat, kézzel javít, kézzel összesít. Az ismétlődő adminisztráció elnyeli azt az időt, amit kódátnézésre, mentorálásra és valódi visszajelzésre kellene fordítani.

**Az iskola megtanítja a nyelvet, de nem a szakmát.**

## A megoldás

Az OpenSchool nem egy újabb feladatbeadó rendszer. A diákok **ugyanazokkal az eszközökkel dolgoznak, amelyeket az iparban is használnak**:

| Iskolai verzió | Ipari megfelelő |
|---|---|
| GitHub repóba pushol | Verziókezelés, commit kultúra |
| GitHub Actions futtatja a teszteket | CI pipeline — zöld build = kész |
| Discord szálakban kérdez | Csapatkommunikáció |
| VS Code + terminál | Ipari fejlesztőkörnyezet |
| Docker + PostgreSQL | Konténerizált fejlesztés |
| pytest / shell tesztek | Tesztvezérelt gondolkodás |

A cél nem az, hogy a diák egy platformot tanuljon meg használni, hanem hogy **a munkafolyamat maga legyen a tananyag része**. Amikor a diák commitol, pushol, olvassa a teszt kimenetét és Discord-on kérdez — már fejlesztőként dolgozik.

## Alapelvek

| Elv | Megvalósítás |
|---|---|
| **Valódi eszközök, nem iskolai pótlékok** | GitHub (nem Google Classroom), Discord (nem Kréta üzenet), VS Code (nem online editor) |
| **Gyakorlat az elmélet előtt** | Max 15 perc elmélet, utána live coding. A programozás kézműves szakma — kézzel kell írni, nem slideokon nézni |
| **CI mint visszajelzés** | Az automatikus tesztek nem büntetnek — azonnal megmutatják, mi működik és mi nem. A diák megtanulja olvasni a teszt kimenetet, ahogy egy fejlesztő a CI logot |
| **A git történet számít** | A tanár nem csak a végeredményt nézi, hanem a commitokat: mikor dolgozott, hogyan építette fel, mennyit írt egyszerre |
| **Növekedési szemlélet** | A házi feladat visszajelzés, nem büntetés. A fejlődés számít, nem a hibátlanság |

## Miért nyílt forráskódú?

Az oktatási szoftverek többsége zárt: fizetős licence, kiszolgáltatott felhasználók, testreszabhatatlan logika. Az OpenSchool másképp gondolkodik:

- **Átláthatóság** — A tanár és a diák is látja, hogyan működik a platform. A kód nem fekete doboz — maga is tananyag.
- **Szabadság** — Bármely iskola, bármely tanár letöltheti, módosíthatja, saját igényeire szabhatja. Nincs vendor lock-in.
- **Közösség** — A hibákat bárki jelzi, a javításokat bárki beküldik. Az oktatási szoftver nem egy cég terméke — közös erőforrás.
- **Példamutatás** — Ha azt tanítjuk, hogy a nyílt forráskód az ipar alapja, a saját eszközeink is legyenek nyíltak.

Az OpenSchool a [MIT licenc](LICENSE) alatt érhető el.

## Kinek való?

**Tanároknak**, akik:
- GitHub Classroom-ot használnak vagy szeretnének elkezdeni
- automatizálnák az ismétlődő adminisztrációt
- magyar nyelvű, kulturálisan illeszkedő anyagokat keresnek
- egy jól strukturált kiindulópontot akarnak, amit saját igényeikre szabhatnak

**Diákoknak**, akik:
- valódi projekteken keresztül akarnak programozni tanulni
- az iparban használt eszközökkel akarnak megismerkedni
- hitelesíthető tanúsítványt szeretnének a tudásukról

## Mit tud a platform?

| Funkció | Leírás |
|---|---|
| **GitHub OAuth** | Bejelentkezés GitHub fiókkal — nincs külön regisztráció |
| **Kurzuskezelés** | Kurzusok, modulok, gyakorlatok hierarchikus szervezése |
| **Haladáskövetés** | Automatikus CI-alapú ellenőrzés — pushol → tesztek futnak → haladás frissül |
| **GitHub Classroom** | Classroom assignment linkek, webhook-alapú valós idejű szinkronizálás |
| **Tanúsítványok** | PDF generálás QR kóddal, nyilvános hitelesítési oldal |
| **Admin panel** | Statisztikák, felhasználókezelés, kurzus CRUD |
| **Tanári nézet** | Diákok haladásának összesítése kurzusonként |

## Tech stack

| Réteg | Technológia |
|---|---|
| Backend | FastAPI · SQLAlchemy · Alembic · Python 3.12 |
| Adatbázis | PostgreSQL 16 |
| Frontend | Astro 5 (statikus kimenet) |
| Infrastruktúra | Docker Compose · nginx · GitHub Actions CI/CD |
| PDF | fpdf2 · QR kód natív vektorként |
| Kódminőség | Ruff linter/formatter · pre-commit · pytest (56 teszt) |

## Gyors indítás

```bash
git clone https://github.com/ghemrich/openschool-platform.git
cd openschool-platform
cp .env.example .env
# Szerkeszd a .env fájlt (GitHub OAuth adatok)

docker compose up --build -d
curl http://localhost/health
# → {"status": "ok"}
```

Részletes útmutató: [Telepítési útmutató](docs/telepitesi-utmutato.md)

## Dokumentáció

| Dokumentum | Leírás |
|---|---|
| [Architektúra](docs/architektura.md) | Rendszer felépítés, adatmodell, auth folyamat, API struktúra |
| [Telepítési útmutató](docs/telepitesi-utmutato.md) | Helyi fejlesztés, staging, éles VPS telepítés, SSL, backup |
| [Fejlesztői környezet](docs/fejlesztoi-kornyezet.md) | Python venv, VS Code, pre-commit, Ruff, pytest, Docker |
| [Jövőkép és fejlesztési terv](docs/jovokep-es-fejlesztesi-terv.md) | Kurzusok, megvalósított funkciók, roadmap |
| [Hozzájárulás](CONTRIBUTING.md) | Fork, branch stratégia, PR küldés, kódstílus |

## Hozzájárulás

Szívesen fogadjuk a hozzájárulásokat! Olvasd el a [CONTRIBUTING.md](CONTRIBUTING.md) fájlt a részletekért.

## Licenc

MIT — lásd [LICENSE](LICENSE)

A `good first issue` címkéjű [issue-k](../../issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) ideálisak kezdőknek.

## Licensz

A projekt az [MIT License](LICENSE) alatt érhető el.
