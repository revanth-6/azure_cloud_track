FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

FROM node:20-alpine

RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup

WORKDIR /app

# Copy and install as appuser directly
COPY --chown=appuser:appgroup package*.json ./
RUN npm install --only=production && \
    npm cache clean --force

# Copy source with correct ownership immediately
COPY --chown=appuser:appgroup --from=builder /app/src ./src

# No need for chown -R anymore!
USER appuser
ENV NODE_ENV=production
EXPOSE 3001
CMD ["node", "src/index.js"]