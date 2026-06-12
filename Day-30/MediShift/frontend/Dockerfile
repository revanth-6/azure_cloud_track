FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine

RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup

RUN chown -R appuser:appgroup \
    /usr/share/nginx/html \
    /var/cache/nginx \
    /var/log/nginx \
    /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R appuser:appgroup \
    /var/run/nginx.pid

COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

USER appuser
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]