# CloudFlow Guestbook

A tiny PHP + MySQL app I own end to end — the deployable workload for the CloudFlow DevOps project.

## What it is
- **PHP** (plain, no framework) served by **Nginx** + **PHP-FPM**
- **MySQL** database
- A small **UI** (sign the guestbook) and a **JSON API**
- ~1 app file (`public/index.php`) — small enough to understand every line

## Run it locally
```bash
docker compose up --build -d
# open http://localhost:8080
```
Edit `public/index.php`, refresh the browser — changes appear instantly (live code mount).

## API
- `GET  /api/messages` — list messages (JSON)
- `POST /api/messages` — add a message `{"name": "...", "message": "..."}`
- `GET  /api/health`   — health check (used by monitoring / load balancers)

## Structure
```
guestbook/
├── public/index.php        # the whole app: UI + API
├── docker/nginx.conf       # nginx serves php-fpm
├── docker/supervisord.conf # runs nginx + php-fpm together
├── Dockerfile              # builds the app image
└── docker-compose.yml      # local dev (app + mysql)
```
