FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

FROM node:20-alpine

RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup

WORKDIR /app

COPY --chown=appuser:appgroup package*.json ./
RUN npm install --only=production && \
    npm cache clean --force

COPY --chown=appuser:appgroup --from=builder /app/src ./src

USER appuser
ENV NODE_ENV=production
EXPOSE 3003
CMD ["node", "src/index.js"]