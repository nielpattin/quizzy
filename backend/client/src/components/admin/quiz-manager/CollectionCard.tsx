import { formatDistanceToNow } from "date-fns";
import { Edit, Eye, Trash2 } from "lucide-react";
import { Badge } from "@/components/ui/badge";

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

interface CollectionCardProps {
	collection: Collection;
	onEdit: (collectionId: string) => void;
	onView: (collectionId: string) => void;
	onDelete: (collectionId: string) => void;
}

export function CollectionCard({
	collection,
	onEdit,
	onView,
	onDelete,
}: CollectionCardProps) {
	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-[14px] px-[25px] py-[25px]">
			<div className="flex items-center justify-between">
				<div className="flex-1 flex flex-col gap-2">
					<div className="flex items-center gap-3">
						<h3 className="text-white font-bold text-[16px] leading-6">
							{collection.title}
						</h3>

						<Badge
							className={`h-[22px] px-[9px] py-[3px] rounded-[8px] text-white text-[12px] font-normal leading-4 ${
								collection.isPublic
									? "bg-[#64a7ff] border-transparent"
									: "bg-[#253347] border border-[#253347]"
							}`}
						>
							{collection.isPublic ? "public" : "private"}
						</Badge>
					</div>

					<div className="flex items-center gap-6 text-[#8b9bab] text-[14px] leading-5">
						<span>{collection.quizCount} quizzes</span>
						<span>
							Modified:{" "}
							{formatDistanceToNow(new Date(collection.updatedAt), {
								addSuffix: true,
							})}
						</span>
					</div>
				</div>

				<div className="flex items-center gap-2">
					<button
						type="button"
						onClick={() => onEdit(collection.id)}
						className="w-[36px] h-[32px] flex items-center justify-center rounded-[8px] hover:bg-[#253347] transition-colors"
						title="Edit"
					>
						<Edit className="w-4 h-4 text-[#8b9bab]" />
					</button>

					<button
						type="button"
						onClick={() => onView(collection.id)}
						className="w-[36px] h-[32px] flex items-center justify-center rounded-[8px] hover:bg-[#253347] transition-colors"
						title="View Quizzes"
					>
						<Eye className="w-4 h-4 text-[#8b9bab]" />
					</button>

					<button
						type="button"
						onClick={() => onDelete(collection.id)}
						className="w-[36px] h-[32px] flex items-center justify-center rounded-[8px] hover:bg-[#253347] transition-colors"
						title="Delete"
					>
						<Trash2 className="w-4 h-4 text-[#8b9bab]" />
					</button>
				</div>
			</div>
		</div>
	);
}
