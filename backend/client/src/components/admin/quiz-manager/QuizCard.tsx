import { formatDistanceToNow } from "date-fns";
import { Copy, Edit, MoreVertical, Trash2 } from "lucide-react";
import { Badge } from "@/components/ui/badge";

interface Quiz {
	id: string;
	title: string;
	description: string | null;
	category: string | null;
	questionCount: number;
	playCount: number;
	updatedAt: string;
	status: "published" | "draft";
	collection: { id: string; title: string } | null;
	user: {
		id: string;
		fullName: string;
		username: string | null;
		profilePictureUrl: string | null;
	} | null;
}

interface QuizCardProps {
	quiz: Quiz;
	onEdit: (quizId: string) => void;
	onCopy: (quizId: string) => void;
	onDelete: (quizId: string) => void;
	onMore: (quizId: string) => void;
}

export function QuizCard({
	quiz,
	onEdit,
	onCopy,
	onDelete,
	onMore,
}: QuizCardProps) {
	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-[14px] px-[25px] py-[25px]">
			<div className="flex items-center justify-between">
				<div className="flex-1 flex flex-col gap-2">
					<div className="flex items-center gap-3">
						<h3 className="text-white font-bold text-[16px] leading-6">
							{quiz.title}
						</h3>

						<Badge
							className={`h-[22px] px-[9px] py-[3px] rounded-[8px] text-white text-[12px] font-normal leading-4 ${
								quiz.status === "published"
									? "bg-[#00a63e] border-transparent"
									: "bg-[#d08700] border-transparent"
							}`}
						>
							{quiz.status}
						</Badge>
					</div>

					<div className="flex items-center gap-6 text-[#8b9bab] text-[14px] leading-5">
						{quiz.collection && (
							<span>Collection: {quiz.collection.title}</span>
						)}
						<span>{quiz.questionCount} questions</span>
						<span>{quiz.playCount} attempts</span>
						<span>
							Modified:{" "}
							{formatDistanceToNow(new Date(quiz.updatedAt), {
								addSuffix: true,
							})}
						</span>
					</div>
				</div>

				<div className="flex items-center gap-2">
					<button
						type="button"
						onClick={() => onEdit(quiz.id)}
						className="w-[36px] h-[32px] flex items-center justify-center rounded-[8px] hover:bg-[#253347] transition-colors"
						title="Edit"
					>
						<Edit className="w-4 h-4 text-[#8b9bab]" />
					</button>

					<button
						type="button"
						onClick={() => onCopy(quiz.id)}
						className="w-[36px] h-[32px] flex items-center justify-center rounded-[8px] hover:bg-[#253347] transition-colors"
						title="Copy"
					>
						<Copy className="w-4 h-4 text-[#8b9bab]" />
					</button>

					<button
						type="button"
						onClick={() => onDelete(quiz.id)}
						className="w-[36px] h-[32px] flex items-center justify-center rounded-[8px] hover:bg-[#253347] transition-colors"
						title="Delete"
					>
						<Trash2 className="w-4 h-4 text-[#8b9bab]" />
					</button>

					<button
						type="button"
						onClick={() => onMore(quiz.id)}
						className="w-[36px] h-[32px] flex items-center justify-center rounded-[8px] hover:bg-[#253347] transition-colors"
						title="More"
					>
						<MoreVertical className="w-4 h-4 text-[#8b9bab]" />
					</button>
				</div>
			</div>
		</div>
	);
}
