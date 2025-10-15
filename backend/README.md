# Backend Workspace

Bun workspace containing the Hono API server and React frontend for Quizzy.

## Structure

- **`server/`** - Hono API server with PostgreSQL + Drizzle ORM
- **`client/`** - React frontend with TanStack Router

## Getting Started

```bash
# Install dependencies
bun install

# Start PostgreSQL database
bun run db:up

# Start server (port 8000)
bun run dev
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
bun run dev            # Start Hono server with hot reload
bun run typecheck      # Check TypeScript errors
```

## Project Structure

```
server/
  db/
    index.ts           # Database client
    schema.ts          # Drizzle schema definitions
  lib/
    supabase.ts        # Supabase client setup
  middleware/
    auth.ts            # JWT verification middleware
  routes/
    user.ts            # User API routes
  index.ts             # App entry point

client/
  src/
    routes/            # TanStack Router file-based routes
    components/        # React components
      ui/              # shadcn/ui components
    lib/               # Utilities
```

## Environment Variables

Create a `.env` file in `backend/`:

```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/quizzy
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

## API Routes

## Database Schema

## Learn More

- [Bun Documentation](https://bun.sh/docs)
- [Hono Framework](https://hono.dev/docs)
- [Drizzle ORM](https://orm.drizzle.team/docs)
- [TanStack Router](https://tanstack.com/router)
