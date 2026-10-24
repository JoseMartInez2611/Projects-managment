# SubProyecto

Monorepo con frontend (React + Vite + TypeScript + Material UI) y backend (FastAPI + PostgreSQL), orquestado con pnpm workspaces + Turborepo y empaquetado con Docker.

```
apps/web              React + Vite + TS + MUI
apps/api              FastAPI + SQLAlchemy + Alembic (gestionado con uv)
packages/api-client   Tipos TS generados desde el OpenAPI de la API
```

## Requisitos

- Docker Desktop
- Node >= 20.19 y pnpm 12 (`packageManager` en `package.json`)
- [uv](https://docs.astral.sh/uv/) (solo para correr lint/test/dev del backend fuera de Docker; instala Python 3.13 por su cuenta)

## Arranque rápido (Docker)

```bash
cp .env.example .env        # opcional en dev: hay defaults
pnpm docker:dev
```

| Servicio | URL                              |
| -------- | -------------------------------- |
| Web      | http://localhost:5173            |
| API      | http://localhost:8000/api/docs   |
| Postgres | localhost:5432 (usuario/clave de `.env`) |

Hot reload en web (Vite) y api (uvicorn). La API aplica `alembic upgrade head` al arrancar.
`pnpm docker:down` detiene todo; agrega `-v` a `docker compose down` para borrar la base de datos.

## Producción local

```bash
cp .env.example .env        # obligatorio: define una POSTGRES_PASSWORD real
pnpm docker:prod            # http://localhost:8080
pnpm docker:prod:down
```

Solo nginx publica puerto (`PROD_WEB_PORT`, 8080). `api` y `db` quedan en la red interna; nginx proxea `/api` a la API. El servicio `migrate` corre las migraciones antes de levantar `api`.

## Desarrollo sin Docker

```bash
pnpm install
pnpm turbo run lint typecheck test build   # todo el monorepo
pnpm dev                                   # web (5173) y api (8000); requiere Postgres en localhost:5432
```

`uv` debe estar en el PATH. Con `pip install --user uv` en Windows queda en `%APPDATA%\Python\Python3xx\Scripts`.

## Tipos del cliente API

Tras cambiar rutas o modelos de la API:

```bash
pnpm generate
```

Esto exporta `packages/api-client/openapi.json` y regenera `packages/api-client/src/schema.d.ts`. Ambos archivos se commitean, así el build del frontend en Docker no necesita Python.

## Migraciones

```bash
cd apps/api
uv run alembic revision --autogenerate -m "descripcion"
uv run alembic upgrade head
```

Los modelos deben heredar de `app.db.base.Base`.
