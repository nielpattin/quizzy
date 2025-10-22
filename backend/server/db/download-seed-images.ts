import { mkdir } from 'fs/promises';
import { existsSync } from 'fs';
import path from 'path';

const PEXELS_API_KEY = process.env.PEXEL_API_KEY;
const BASE_URL = 'https://api.pexels.com/v1/search';

interface PexelsPhoto {
	id: number;
	src: {
		large: string;
		original: string;
	};
	photographer: string;
}

interface PexelsResponse {
	photos: PexelsPhoto[];
	total_results: number;
}

const IMAGE_CATEGORIES = {
	posts: [
		'education',
		'learning',
		'books',
		'students',
		'classroom',
		'knowledge',
		'teaching',
		'studying',
		'university',
		'school',
	],
	quizzes: [
		'quiz',
		'question mark',
		'thinking',
		'brainstorm',
		'test',
		'exam',
		'mathematics',
		'science',
		'geography',
		'technology',
	],
};

const downloadImage = async (url: string, filepath: string): Promise<void> => {
	console.log(`  📥 Downloading: ${path.basename(filepath)}`);
	const response = await fetch(url);
	if (!response.ok)
		throw new Error(`Failed to download: ${response.statusText}`);

	const arrayBuffer = await response.arrayBuffer();
	await Bun.write(filepath, Buffer.from(arrayBuffer));
};

const searchPexels = async (
	query: string,
	perPage: number = 1,
): Promise<PexelsPhoto[]> => {
	const url = `${BASE_URL}?query=${encodeURIComponent(query)}&per_page=${perPage}`;

	const response = await fetch(url, {
		headers: {
			Authorization: PEXELS_API_KEY!,
		},
	});

	if (!response.ok) {
		throw new Error(
			`Pexels API error: ${response.status} ${response.statusText}`,
		);
	}

	const data: PexelsResponse = await response.json();
	return data.photos;
};

const main = async () => {
	if (!PEXELS_API_KEY) {
		console.error('❌ PEXEL_API_KEY not found in .env file');
		process.exit(1);
	}

	console.log('🎨 Downloading seed images from Pexels...\n');

	const seedImagesDir = path.join(__dirname, 'seed-images');
	const postsDir = path.join(seedImagesDir, 'posts');
	const quizzesDir = path.join(seedImagesDir, 'quizzes');

	if (!existsSync(seedImagesDir))
		await mkdir(seedImagesDir, { recursive: true });
	if (!existsSync(postsDir)) await mkdir(postsDir, { recursive: true });
	if (!existsSync(quizzesDir)) await mkdir(quizzesDir, { recursive: true });

	console.log('📂 Downloading POST images...');
	for (let i = 0; i < IMAGE_CATEGORIES.posts.length; i++) {
		const query = IMAGE_CATEGORIES.posts[i];
		console.log(`  🔍 Searching: "${query}"`);

		try {
			const photos = await searchPexels(query, 1);
			if (photos.length > 0) {
				const photo = photos[0];
				const filename = `${String(i + 1).padStart(2, '0')}-${query.replace(/\s+/g, '-')}.jpg`;
				const filepath = path.join(postsDir, filename);

				await downloadImage(photo.src.large, filepath);
				console.log(`  ✅ Saved: ${filename} (by ${photo.photographer})`);
			}

			await new Promise((resolve) => setTimeout(resolve, 500));
		} catch (error) {
			console.error(`  ❌ Failed to download "${query}":`, error);
		}
	}

	console.log('\n📂 Downloading QUIZ images...');
	for (let i = 0; i < IMAGE_CATEGORIES.quizzes.length; i++) {
		const query = IMAGE_CATEGORIES.quizzes[i];
		console.log(`  🔍 Searching: "${query}"`);

		try {
			const photos = await searchPexels(query, 1);
			if (photos.length > 0) {
				const photo = photos[0];
				const filename = `${String(i + 1).padStart(2, '0')}-${query.replace(/\s+/g, '-')}.jpg`;
				const filepath = path.join(quizzesDir, filename);

				await downloadImage(photo.src.large, filepath);
				console.log(`  ✅ Saved: ${filename} (by ${photo.photographer})`);
			}

			await new Promise((resolve) => setTimeout(resolve, 500));
		} catch (error) {
			console.error(`  ❌ Failed to download "${query}":`, error);
		}
	}

	console.log('\n✅ Image download complete!');
	console.log(
		`📊 Total images: ${IMAGE_CATEGORIES.posts.length + IMAGE_CATEGORIES.quizzes.length}`,
	);
	console.log(`📁 Location: ${seedImagesDir}`);
	console.log(
		'\n💡 Next step: Run "bun run db:seed" to upload images to MinIO and seed database',
	);
};

main().catch((error) => {
	console.error('❌ Download failed:', error);
	process.exit(1);
});
