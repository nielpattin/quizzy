# Quizzy Monorepo

Full-stack quiz application with Flutter mobile app and Hono/Bun-powered backend + React Admin UI web.

## Project Structure

- `backend/` - Bun workspace (Hono API server + React web app)
  - `server/` - Hono API with PostgreSQL + Drizzle ORM
    - `db/` - Database schema and Drizzle ORM setup
    - `lib/` - Shared utilities (Supabase client)
    - `middleware/` - Authentication middleware
    - `routes/` - API route handlers
  - `client/` - React frontend with TanStack Router (Vite)
- `app/` - Flutter mobile application
  - `lib/` - Dart source code
    - `pages/` - UI screens (auth, home, library, profile, quiz, social)
    - `models/` - Data models
    - `services/` - Business logic
    - `widgets/` - Reusable components
  - `android/` - Android platform code

## Tech Stack

**Backend:**
- Bun runtime + Hono framework (OpenAPI)
- PostgreSQL 18 + Drizzle ORM (Bun SQL driver)
- React 19 + TanStack Router + Vite
- TypeScript + Biome
- Supabase (Authentication)
- Scalar (API documentation at `/scalar`)

**Mobile:**
- Flutter + Dart
- Material Design 3
- go_router (Navigation)
- Supabase Flutter SDK (Authentication)
- flutter_dotenv (Environment variables)

## Features

- **Quiz Management**: Create, edit, version, and organize quizzes
- **Game Sessions**: Real-time multiplayer quiz games with join codes
- **Social Feed**: Posts, comments, likes, and user interactions
- **User Profiles**: Follow/followers system, profile customization
- **Collections**: Organize quizzes into collections
- **Authentication**: Email/password, Google OAuth, GitHub OAuth
- **Cross-platform**: Flutter mobile app + React web interface


## Documentation

- [Backend README](backend/README.md)
- [Flutter App README](app/README.md)