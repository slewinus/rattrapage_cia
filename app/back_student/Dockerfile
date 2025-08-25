# Multi-stage build pour optimiser la taille et le cache
FROM node:18-alpine AS deps
WORKDIR /usr/src/app

# Installation des dépendances système pour Alpine
RUN apk add --no-cache python3 make g++ sqlite-dev

# Copie uniquement les fichiers de dépendances pour maximiser le cache
COPY package.json yarn.lock* package-lock.json* ./
RUN yarn install --frozen-lockfile --network-timeout 100000 || npm install

# Stage de build
FROM node:18-alpine AS builder
WORKDIR /usr/src/app

RUN apk add --no-cache python3 make g++ sqlite-dev

COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY . .

# Stage final
FROM node:18-alpine
WORKDIR /usr/src/app

# Installation minimale pour runtime
RUN apk add --no-cache python3 netcat-openbsd sqlite-libs && \
    ln -sf /usr/bin/python3 /usr/bin/python

ENV PYTHON=/usr/bin/python3
ENV NODE_ENV=production

# Copie des fichiers depuis le builder
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app .

# Script d'entrée optimisé
RUN printf '#!/bin/sh\nset -e\n\
echo "Waiting for DB at $DB_HOST:3306..."\n\
timeout 60 sh -c "until nc -z $DB_HOST 3306; do sleep 1; done"\n\
echo "Running migrations..."\n\
yarn migration:start || true\n\
echo "Starting app..."\n\
exec yarn start\n' > /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 3000
ENTRYPOINT ["/entrypoint.sh"]