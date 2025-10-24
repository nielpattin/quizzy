import { useQuery } from "@tanstack/react-query";
import { X } from "lucide-react";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
	Dialog,
	DialogContent,
	DialogDescription,
	DialogHeader,
	DialogTitle,
} from "@/components/ui/dialog";
import { useAuth } from "@/contexts/AuthContext";

interface Quiz {
	id: string;
	title: string;
	description: string | null;
	category: string | null;
	questionCount: number;
	playCount: number;
	favoriteCount: number;
	createdAt: string;
}

interface Collection {
	id: string;
	title: string;
	description: string | null;
	quizzes: Quiz[];
}

interface ViewCollectionQuizzesDialogProps {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	collectionId: string | null;
	onRemoveQuiz: (collectionId: string, quizId: string) => Promise<void>;
}

async function fetchCollectionWithQuizzes(
	token: string,
	collectionId: string,
): Promise<Collection> {
	const response = await fetch(
		`http://localhost:8000/api/collection/${collectionId}`,
		{
			headers: {
				Authorization: `Bearer ${token}`,
			},
		},
	);

	if (!response.ok) {
		throw new Error("Failed to fetch collection");
	}

	return response.json();
}

export function ViewCollectionQuizzesDialog({
	open,
	onOpenChange,
	collectionId,
	onRemoveQuiz,
}: ViewCollectionQuizzesDialogProps) {
	const { session } = useAuth();
	const token = session?.access_token;
	const [removingQuizId, setRemovingQuizId] = useState<string | null>(null);

	const { data: collection, isLoading } = useQuery({
		queryKey: ["collection-quizzes", collectionId],
		queryFn: () =>
			token && collectionId
				? fetchCollectionWithQuizzes(token, collectionId)
				: Promise.reject("No token or collection ID"),
		enabled: !!token && !!collectionId && open,
	});

	const handleRemoveQuiz = async (quizId: string) => {
		if (!collectionId) return;
		setRemovingQuizId(quizId);
		try {
			await onRemoveQuiz(collectionId, quizId);
		} finally {
			setRemovingQuizId(null);
		}
	};

	return (
		<Dialog open={open} onOpenChange={onOpenChange}>
			<DialogContent className="bg-[#1a2433] border-[#253347] text-white max-w-3xl max-h-[80vh] overflow-y-auto">
				<DialogHeader>
					<DialogTitle className="text-white text-xl">
						{collection?.title || "Collection Quizzes"}
					</DialogTitle>
					<DialogDescription className="text-[#8b9bab]">
						{collection?.description || "Manage quizzes in this collection"}
					</DialogDescription>
				</DialogHeader>

				<div className="py-4">
					{isLoading && (
						<div className="flex items-center justify-center py-8">
							<div className="text-[#8b9bab]">Loading quizzes...</div>
						</div>
					)}

					{!isLoading && collection?.quizzes.length === 0 && (
						<div className="flex items-center justify-center py-8">
							<div className="text-[#8b9bab]">
								No quizzes in this collection yet.
							</div>
						</div>
					)}

					{!isLoading && collection && collection.quizzes.length > 0 && (
						<div className="space-y-3">
							{collection.quizzes.map((quiz) => (
								<div
									key={quiz.id}
									className="bg-[#0a0f1a] border border-[#253347] rounded-lg p-4 flex items-center justify-between"
								>
									<div className="flex-1">
										<h4 className="text-white font-semibold text-sm">
											{quiz.title}
										</h4>
										<div className="flex items-center gap-4 mt-1 text-[#8b9bab] text-xs">
											<span>{quiz.questionCount} questions</span>
											<span>{quiz.playCount} plays</span>
											{quiz.category && <span>{quiz.category}</span>}
										</div>
									</div>

									<Button
										size="sm"
										variant="ghost"
										onClick={() => handleRemoveQuiz(quiz.id)}
										disabled={removingQuizId === quiz.id}
										className="text-[#8b9bab] hover:text-red-500 hover:bg-[#253347]"
									>
										{removingQuizId === quiz.id ? (
											"Removing..."
										) : (
											<X className="w-4 h-4" />
										)}
									</Button>
								</div>
							))}
						</div>
					)}
				</div>
			</DialogContent>
		</Dialog>
	);
}
