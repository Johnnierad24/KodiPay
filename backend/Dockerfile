# KodiPay backend — production image
FROM node:22-alpine

# App lives here
WORKDIR /app

# Install dependencies first for better layer caching
COPY package*.json ./
RUN npm ci --omit=dev

# Copy application source
COPY . .

# Render/Railway inject PORT; default to 5000 for local runs
ENV NODE_ENV=production
EXPOSE 5000

# Run as the built-in non-root user for safety
USER node

CMD ["node", "src/server.js"]
