# ───────────────
# 1. Dependencies (avec dev pour tests)
# ───────────────
FROM node:22-alpine AS deps

WORKDIR /app
COPY package*.json ./
RUN npm ci

# ───────────────
# 2. Test stage
# ───────────────
FROM node:22-alpine AS test

WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

CMD ["npm", "test"]

# ───────────────
# 3. Production deps only
# ───────────────
FROM node:22-alpine AS prod-deps

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

# ───────────────
# 4. Runtime final
# ───────────────
FROM node:22-alpine AS runtime

WORKDIR /app

COPY --from=prod-deps /app/node_modules ./node_modules
COPY . .

EXPOSE 3000
CMD ["node", "server.js"]