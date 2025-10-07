# Quizzy Monorepo

Full-stack quiz application with Flutter mobile app and Hono/Bun-powered backend.

## Project Structure

- `backend/` - Bun workspace (Hono API server + React web app)
  - `apps/server/` - Hono API with PostgreSQL + Drizzle ORM
  - `apps/web/` - React frontend with TanStack Router
  - `packages/shared/` - Shared types and utilities
- `app/` - Flutter mobile application

## Backend Setup

### First Time Setup

```bash
cd backend
bun install
```

### Database Setup

Start PostgreSQL in Docker:

```bash
bun run db:up
```

Generate and run migrations:

```bash
bun run db:generate
bun run db:migrate
```

### Development (in the `backend/` directory)

Start the Hono server (port 8000):

```bash
bun run dev:server
```

Start the React web app (port 3000):

```bash
bun run dev:web
```

### Database Commands

```bash
bun run db:up         # Start PostgreSQL
bun run db:down       # Stop PostgreSQL (keeps data)
bun run db:reset      # Stop and delete all data
bun run db:logs       # View PostgreSQL logs
bun run db:studio     # Open Drizzle Studio GUI
```

See [backend/README.md](backend/README.md) for detailed documentation.

## Flutter App

### VS Code

1. Select the desired device (Android emulator)
2. Press F5 to start debugging

### Command Line

```bash
cd app
flutter run
```

See [app/README.md](app/README.md) for Flutter-specific documentation (if exists).

## Tech Stack

**Backend:**
- Bun runtime + Hono framework
- PostgreSQL 18 + Drizzle ORM
- React 19 + TanStack Router
- TypeScript + Biome

**Mobile:**
- Flutter + Dart
- Material Design 3

## Documentation

- [Backend README](backend/README.md)
- [Server README](backend/apps/server/README.md)
- [Web README](backend/apps/web/README.md)