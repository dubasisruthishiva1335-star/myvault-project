# Root Dockerfile for Railway builds.
# This monorepo contains multiple apps (admin-web/, backend/, landing-web/, mobile-app/).
# Railpack cannot automatically determine which app to build, so this Dockerfile
# explicitly builds and runs the NestJS backend located in backend/.

# ---- Builder stage ----
FROM node:18-alpine AS builder
WORKDIR /app

RUN apk add --no-cache openssl

# Install dependencies based on the backend's package files
COPY backend/package.json backend/package-lock.json* ./
RUN npm install

# Copy the rest of the backend source
COPY backend/ .

# Generate the Prisma client and build the NestJS app
RUN npx prisma generate
RUN npm run build

# ---- Runner stage ----
FROM node:18-alpine AS runner
WORKDIR /app

RUN apk add --no-cache openssl

ENV NODE_ENV=production

# Copy built app, production dependencies, and Prisma schema needed at runtime
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/prisma ./prisma

EXPOSE 4000

CMD ["sh", "-c", "npx prisma db push && npm run seed && npm start"]
