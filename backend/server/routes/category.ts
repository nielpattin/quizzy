import { Hono } from 'hono';
import { authMiddleware, type AuthContext } from '../middleware/auth';
import { db } from '../db/index';
import { categories } from '../db/schema';
import { eq, and, desc, asc } from 'drizzle-orm';

type Variables = {
	user: AuthContext;
};

const categoryRoutes = new Hono<{ Variables: Variables }>();

// Public Routes

// GET /api/categories - Get all categories
categoryRoutes.get('/', async (c) => {
	try {
		const allCategories = await db
			.select()
			.from(categories);

		return c.json(allCategories);
	} catch (error) {
		console.error('Error fetching categories:', error);
		return c.json({ error: 'Failed to fetch categories' }, 500);
	}
});

// GET /api/categories/:id - Get single category by ID
categoryRoutes.get('/:id', async (c) => {
	const categoryId = c.req.param('id');

	try {
		const [category] = await db.select().from(categories).where(eq(categories.id, categoryId));

		if (!category) {
			return c.json({ error: 'Category not found' }, 404);
		}

		return c.json(category);
	} catch (error) {
		console.error('Error fetching category:', error);
		return c.json({ error: 'Failed to fetch category' }, 500);
	}
});

// GET /api/categories/slug/:slug - Get category by slug
categoryRoutes.get('/slug/:slug', async (c) => {
	const slug = c.req.param('slug');

	try {
		const [category] = await db.select().from(categories).where(eq(categories.slug, slug));

		if (!category) {
			return c.json({ error: 'Category not found' }, 404);
		}

		return c.json(category);
	} catch (error) {
		console.error('Error fetching category by slug:', error);
		return c.json({ error: 'Failed to fetch category' }, 500);
	}
});

export default categoryRoutes;
