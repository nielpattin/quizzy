import { CollectionCard } from "./CollectionCard";

interface Collection {
	id: string;
	title: string;
	description: string | null;
	imageUrl: string | null;
	quizCount: number;
	isPublic: boolean;
	updatedAt: string;
	user: {
		id: string;
		fullName: string;
		username: string | null;
		profilePictureUrl: string | null;
	} | null;
}

interface CollectionsTableProps {
	collections: Collection[];
	isLoading: boolean;
	onEdit: (collectionId: string) => void;
	onView: (collectionId: string) => void;
	onDelete: (collectionId: string) => void;
}

export function CollectionsTable({
	collections,
	isLoading,
	onEdit,
	onView,
	onDelete,
}: CollectionsTableProps) {
	if (isLoading) {
		return (
			<div className="flex items-center justify-center py-12">
				<div className="text-[#8b9bab]">Loading collections...</div>
			</div>
		);
	}

	if (collections.length === 0) {
		return (
			<div className="flex items-center justify-center py-12">
				<div className="text-[#8b9bab]">
					No collections found. Create your first collection to organize
					quizzes.
				</div>
			</div>
		);
	}

	return (
		<div className="flex flex-col gap-4">
			{collections.map((collection) => (
				<CollectionCard
					key={collection.id}
					collection={collection}
					onEdit={onEdit}
					onView={onView}
					onDelete={onDelete}
				/>
			))}
		</div>
	);
}
