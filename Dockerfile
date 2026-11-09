# Lightweight base image
FROM node:22-alpine

ENV NODE_ENV=production \
    APP_ENV=staging \
    PORT=3000

WORKDIR /app

# Copy dependency files first so this layer is cached until they change
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copy only what the app needs
COPY src ./src

# Do not run as root
USER node

EXPOSE 3000

# Docker marks the container healthy/unhealthy using the /health endpoint
HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||3000)+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "src/server.js"]
