FROM node:20-bookworm

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends swi-prolog \
    && rm -rf /var/lib/apt/lists/*

COPY backend/package*.json ./backend/
RUN cd backend && npm install --omit=dev

COPY frontend/package*.json ./frontend/
RUN cd frontend && npm install

COPY facts.pl constraints.pl optimization.pl main.pl ./
COPY backend ./backend
COPY frontend ./frontend

RUN cd frontend && npm run build

EXPOSE 3001

CMD ["node", "backend/server.js"]
