# syntax=docker/dockerfile:1
# Contexto de build: raíz del repo (pnpm necesita el lockfile y el workspace)

FROM node:24.22.1-alpine AS base
ENV PNPM_HOME=/pnpm
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
WORKDIR /app

FROM base AS deps
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/web/package.json apps/web/
COPY apps/api/package.json apps/api/
COPY packages/api-client/package.json packages/api-client/
RUN --mount=type=cache,target=/pnpm/store \
    pnpm install --frozen-lockfile --store-dir /pnpm/store --filter "@subproyecto/web..."

# Desarrollo: el código se monta como volumen (ver docker-compose.yml)
FROM deps AS dev
COPY apps/web apps/web
COPY packages/api-client packages/api-client
EXPOSE 5173
CMD ["pnpm", "--filter", "@subproyecto/web", "dev"]

FROM dev AS build
RUN pnpm --filter "@subproyecto/web" build

# Producción: nginx sin root sirve el SPA y proxea /api
FROM nginxinc/nginx-unprivileged:alpine AS prod
COPY apps/web/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/apps/web/dist /usr/share/nginx/html
EXPOSE 8080
