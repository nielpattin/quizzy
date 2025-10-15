# Web

React frontend application for Quizzy built with TanStack Router.

## Features

- **Framework:** React 18
- **Routing:** TanStack Router (file-based)
- **Styling:** Tailwind CSS + shadcn/ui
- **Type Safety:** TypeScript
- **Dev Tools:** Biome (linting & formatting)

## Development

```bash
bun run dev            # Start dev server (port 3000)
bun run build          # Build for production
bun run typecheck      # Check TypeScript errors
```

## Biome (Linting & Formatting)

Use Biome CLI directly with `bunx`:

```bash
# Format all files in src/
bunx --bun biome format --write ./src

# Lint and auto-fix issues
bunx --bun biome lint --write ./src

# Run all checks (format + lint) and auto-fix
bunx --bun biome check --write ./src
```

## Project Structure

```
src/
  routes/              # File-based routes
    __root.tsx         # Root layout
    index.tsx          # Home page
  components/          # React components
    ui/                # shadcn/ui components
  lib/                 # Utilities
  main.tsx             # App entry
```

## Adding Routes

Create a new file in `src/routes/`:

```tsx
// src/routes/about.tsx
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/about')({
  component: About,
})

function About() {
  return <div>About Page</div>
}
```

## Adding UI Components

Use shadcn/ui CLI:

```bash
bunx shadcn@latest add button
bunx shadcn@latest add input
```

## Styling

This project uses Tailwind CSS. Add utility classes directly:

```tsx
<div className="flex items-center gap-4 p-4">
  <Button variant="outline">Click me</Button>
</div>
```

## API Integration

The web app calls the Hono server API at `http://localhost:8000`.

## Tech Stack

- [React](https://react.dev) - UI library
- [TanStack Router](https://tanstack.com/router) - Type-safe routing
- [Tailwind CSS](https://tailwindcss.com) - Utility-first CSS
- [shadcn/ui](https://ui.shadcn.com) - Component library
- [Biome](https://biomejs.dev) - Linter & formatter