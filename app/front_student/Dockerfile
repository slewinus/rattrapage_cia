# Stage 1: Installer les dépendances
FROM node:18-alpine AS deps
WORKDIR /app
COPY package.json yarn.lock* package-lock.json* ./
RUN yarn install --frozen-lockfile --network-timeout 100000 || npm install

# Stage 2: Build de l'application
FROM node:18-alpine AS builder
WORKDIR /app

# Fix react-scripts + Node 18 (OpenSSL v3)
ENV NODE_OPTIONS=--openssl-legacy-provider

ARG REACT_APP_API_URL=/api
ENV REACT_APP_API_URL=${REACT_APP_API_URL}

# Copie des dépendances du stage précédent
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN yarn build

# Stage 3: Runtime Nginx optimisé
FROM nginx:1.27-alpine
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build /usr/share/nginx/html

# Optimisation Nginx
RUN echo "gzip on;" >> /etc/nginx/conf.d/gzip.conf && \
    echo "gzip_types text/css text/javascript application/javascript application/json image/svg+xml;" >> /etc/nginx/conf.d/gzip.conf && \
    echo "gzip_min_length 1000;" >> /etc/nginx/conf.d/gzip.conf