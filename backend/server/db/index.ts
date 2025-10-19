import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';

const queryClient = postgres(process.env.DATABASE_URL!);
export const db = drizzle({ 
  client: queryClient,
  schema: {} // Empty schema to prevent auto-loading relations
});