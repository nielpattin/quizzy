# Server

Hono API server with PostgreSQL database and Drizzle ORM for Quizzy.

## Features

- **Framework:** Hono (fast web framework for Bun)
- **Database:** PostgreSQL with Drizzle ORM
- **Driver:** Bun SQL (native PostgreSQL bindings)
- **Port:** 8000

## Getting Started

```bash
# Install dependencies (from backend root)
bun install

# Start PostgreSQL
bun run db:up

# Generate and run migrations
bun run db:generate
bun run db:migrate

# Start server with hot reload
bun run dev
```

## Database Commands

```bash
bun run db:up          # Start PostgreSQL Docker container
bun run db:down        # Stop PostgreSQL (keeps data)
bun run db:reset       # Stop and delete all data
bun run db:logs        # View PostgreSQL logs
bun run db:generate    # Generate migrations from schema
bun run db:migrate     # Run pending migrations
bun run db:push        # Push schema directly (dev only)
bun run db:studio      # Open Drizzle Studio GUI
```

## Development

```bash
bun run dev            # Start with hot reload (port 8000)
bun run typecheck      # Check TypeScript errors
```

## Project Structure

```
src/
  db/
    index.ts           # Drizzle client
    schema.ts          # Database schema
  index.ts             # Hono app entry
drizzle/               # Auto-generated migrations
drizzle.config.ts      # Drizzle Kit config
docker-compose.yml     # PostgreSQL container
.env                   # Environment variables
```

## Environment Variables

Create `.env` file:

```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/quizzy
```

## Tech Stack

- [Hono](https://hono.dev/docs) - Web framework
- [Drizzle ORM](https://orm.drizzle.team/docs) - TypeScript ORM
- [Bun SQL](https://bun.sh/docs/api/sql) - Native PostgreSQL driver
- [PostgreSQL](https://www.postgresql.org/) - Database
