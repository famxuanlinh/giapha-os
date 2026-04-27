# Sử dụng Bun image chính thức
FROM oven/bun:1 AS base

# 1. Cài đặt dependencies
FROM base AS deps
WORKDIR /app
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

# 2. Build dự án
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Khai báo các đối số build (Build Arguments)
ARG NEXT_PUBLIC_SUPABASE_URL
ARG NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY
ARG SITE_NAME

# Chuyển đối số thành biến môi trường để Next.js nhận diện khi build
ENV NEXT_PUBLIC_SUPABASE_URL=$NEXT_PUBLIC_SUPABASE_URL
ENV NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY=$NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY
ENV SITE_NAME=$SITE_NAME

ENV NODE_ENV=production
RUN bun run build

# 3. Runner stage - Chỉ copy những gì cần thiết để chạy
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
# Cloud Run mặc định dùng port 8080
ENV PORT=8080
ENV HOSTNAME="0.0.0.0"

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 8080

# Chạy server (Next.js standalone output chạy bằng node)
CMD ["node", "server.js"]
