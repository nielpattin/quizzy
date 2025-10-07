# Backend Workspace

Bun monorepo workspace containing the Hono API server and React frontend for Quizzy.

## Structure

- **`apps/server/`** - Hono API server with PostgreSQL + Drizzle ORM
- **`apps/web/`** - React frontend with TanStack Router
- **`packages/shared/`** - Shared types, schemas, and utilities

## Getting Started

```bash
# Install dependencies
bun install

# Start PostgreSQL database
bun run db:up

# Start server (port 8000)
bun run dev:server

# Start web frontend
bun run dev:web
```

## Database Commands

```bash
bun run db:up          # Start PostgreSQL Docker container
bun run db:down        # Stop PostgreSQL (keeps data)
bun run db:reset       # Stop PostgreSQL and delete all data
bun run db:logs        # View PostgreSQL logs
bun run db:generate    # Generate Drizzle migrations
bun run db:migrate     # Run pending migrations
bun run db:push        # Push schema changes (dev only)
bun run db:studio      # Open Drizzle Studio GUI
```

## Development Commands

```bash
bun run dev            # Start all apps in dev mode
bun run dev:web        # Start React frontend only
bun run dev:server     # Start Hono server only
bun run build          # Build web for production
bun run typecheck      # Check TypeScript errors in all apps
```

## Tech Stack

- **Runtime:** Bun
- **Server:** Hono
- **Database:** PostgreSQL + Drizzle ORM (Bun SQL driver)
- **Frontend:** React + TanStack Router
- **Styling:** Tailwind CSS + shadcn/ui

## Learn More

- [Bun Documentation](https://bun.sh/docs)
- [Hono Framework](https://hono.dev/docs)
- [Drizzle ORM](https://orm.drizzle.team/docs)
- [TanStack Router](https://tanstack.com/router)
