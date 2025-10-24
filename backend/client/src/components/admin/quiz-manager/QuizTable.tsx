import { QuizCard } from "./QuizCard";

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

interface QuizTableProps {
	quizzes: Quiz[];
	isLoading: boolean;
	onEdit: (quizId: string) => void;
	onCopy: (quizId: string) => void;
	onDelete: (quizId: string) => void;
	onMore: (quizId: string) => void;
}

export function QuizTable({
	quizzes,
	isLoading,
	onEdit,
	onCopy,
	onDelete,
	onMore,
}: QuizTableProps) {
	if (isLoading) {
		return (
			<div className="flex items-center justify-center py-12">
				<div className="text-[#8b9bab]">Loading quizzes...</div>
			</div>
		);
	}

	if (quizzes.length === 0) {
		return (
			<div className="flex items-center justify-center py-12">
				<div className="text-[#8b9bab]">No quizzes found</div>
			</div>
		);
	}

	return (
		<div className="flex flex-col gap-4">
			{quizzes.map((quiz) => (
				<QuizCard
					key={quiz.id}
					quiz={quiz}
					onEdit={onEdit}
					onCopy={onCopy}
					onDelete={onDelete}
					onMore={onMore}
				/>
			))}
		</div>
	);
}
