FROM dhi.io/node:25-debian12-dev AS builder
WORKDIR /app

# Copy dependency files first. Docker caches this layer, 
# making future builds much faster if you don't change package.json
COPY package.json package-lock.json ./
RUN npm ci

# Copy the rest of the source code and build the application
COPY . .
RUN npm run build

# We start fresh with a brand new, empty Runtime Linux image
FROM dhi.io/node:25-debian12 AS runner
WORKDIR /app

# Image already runs as non-root user "node" with UID 1000, but we explicitly
# set it here for clarity and to ensure all files are owned by the correct user.
USER node

# Set the environment to production
ENV NODE_ENV=production
ENV PORT=3000

# Copy ONLY the optimized artifacts from Stage 1. 
# We leave the heavy node_modules and source code behind.
COPY --from=builder --chown=node:node /app/public ./public
COPY --from=builder --chown=node:node /app/.next/standalone ./
COPY --from=builder --chown=node:node /app/.next/static ./.next/static

EXPOSE 3000

# The standalone output creates a highly optimized server.js file
CMD ["node", "server.js"]