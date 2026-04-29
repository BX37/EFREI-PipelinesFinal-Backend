FROM node:22-alpine AS deps

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

# ─────────────────────────────────────────
FROM node:22-alpine AS runtime

WORKDIR /app

# Copie uniquement les dépendances de prod
COPY --from=deps /app/node_modules ./node_modules

# Copie les sources (pas de build nécessaire, c'est du JS pur ESM)
COPY . .

EXPOSE 3001

ENTRYPOINT ["node", "server.js"]