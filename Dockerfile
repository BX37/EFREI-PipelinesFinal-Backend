FROM node:22-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:22-alpine AS runtime

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY --from=builder /app/dist /app/dist
COPY --from=builder /app/public /app/public

EXPOSE 3000

ENTRYPOINT ["node", "dist/src/main.js"]
