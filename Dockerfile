# Image of the API. Build from the repository root:
#   docker build -t bida-api .
FROM node:22-slim

RUN npm install --global pnpm@12.9.0

WORKDIR /app

# Manifests first, so the install layer is cached until a dependency changes.
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/api/package.json apps/api/
COPY apps/docs/package.json apps/docs/
COPY packages/api-contract/package.json packages/api-contract/
RUN pnpm install --frozen-lockfile --filter @bida/api...

COPY apps/api apps/api
COPY packages/api-contract packages/api-contract

USER node
WORKDIR /app/apps/api
ENV PORT=3000
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
  CMD node -e "fetch('http://127.0.0.1:'+process.env.PORT+'/health').then(r=>process.exit(r.ok?0:1),()=>process.exit(1))"
CMD ["./node_modules/.bin/tsx", "src/main.ts"]
