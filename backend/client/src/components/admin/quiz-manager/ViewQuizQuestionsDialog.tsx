import { Check, FileQuestion, X } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
	Dialog,
	DialogContent,
	DialogDescription,
	DialogFooter,
	DialogHeader,
	DialogTitle,
} from "@/components/ui/dialog";

interface Question {
	id: string;
	quizId: string;
	type:
		| "single_choice"
		| "checkbox"
		| "true_false"
		| "type_answer"
		| "reorder"
		| "drop_pin";
	questionText: string;
	imageUrl: string | null;
	data: {
		options?: Array<{ text: string; isCorrect: boolean }>;
		correctAnswer?: boolean;
		acceptedAnswers?: string[];
		items?: string[];
		[key: string]: unknown;
	};
	orderIndex: number;
}

interface ViewQuizQuestionsDialogProps {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	quizTitle: string;
	questions: Question[];
	isLoading: boolean;
}

const questionTypeLabels: Record<Question["type"], string> = {
	single_choice: "Single Choice",
	checkbox: "Multiple Choice",
	true_false: "True/False",
	type_answer: "Type Answer",
	reorder: "Reorder",
	drop_pin: "Drop Pin",
};

const questionTypeBadgeColors: Record<Question["type"], string> = {
	single_choice: "bg-[#64a7ff]",
	checkbox: "bg-[#9810fa]",
	true_false: "bg-[#00a63e]",
	type_answer: "bg-[#d08700]",
	reorder: "bg-[#155dfc]",
	drop_pin: "bg-[#e7000b]",
};

function QuestionCard({
	question,
	index,
}: {
	question: Question;
	index: number;
}) {
	const renderAnswerDetails = () => {
		if (question.type === "single_choice" || question.type === "checkbox") {
			const options = question.data?.options || [];
			return (
				<div className="space-y-2">
					<div className="text-[#8b9bab] text-[13px] font-medium">
						Answer Options:
					</div>
					{options.map((option, idx) => (
						<div
							key={`option-${question.id}-${idx}`}
							className="flex items-start gap-2 text-[14px] leading-5"
						>
							{option.isCorrect ? (
								<Check className="w-4 h-4 text-[#00a63e] mt-0.5 flex-shrink-0" />
							) : (
								<X className="w-4 h-4 text-[#8b9bab] mt-0.5 flex-shrink-0" />
							)}
							<span
								className={
									option.isCorrect ? "text-[#00a63e]" : "text-[#8b9bab]"
								}
							>
								{option.text}
							</span>
						</div>
					))}
				</div>
			);
		}

		if (question.type === "true_false") {
			const correctAnswer = question.data?.correctAnswer;
			return (
				<div className="space-y-2">
					<div className="text-[#8b9bab] text-[13px] font-medium">
						Correct Answer:
					</div>
					<Badge className="bg-[#00a63e] border-transparent text-white">
						{correctAnswer ? "True" : "False"}
					</Badge>
				</div>
			);
		}

		if (question.type === "type_answer") {
			const acceptedAnswers = question.data?.acceptedAnswers || [];
			return (
				<div className="space-y-2">
					<div className="text-[#8b9bab] text-[13px] font-medium">
						Accepted Answers:
					</div>
					<div className="flex flex-wrap gap-2">
						{acceptedAnswers.map((answer, idx) => (
							<Badge
								key={`answer-${question.id}-${idx}`}
								className="bg-[#1a2433] border border-[#253347] text-[#8b9bab]"
							>
								{answer}
							</Badge>
						))}
					</div>
				</div>
			);
		}

		if (question.type === "reorder") {
			const items = question.data?.items || [];
			return (
				<div className="space-y-2">
					<div className="text-[#8b9bab] text-[13px] font-medium">
						Correct Order:
					</div>
					<ol className="list-decimal list-inside space-y-1 text-[14px] text-[#8b9bab]">
						{items.map((item, idx) => (
							<li key={`item-${question.id}-${idx}`}>{item}</li>
						))}
					</ol>
				</div>
			);
		}

		if (question.type === "drop_pin") {
			return (
				<div className="space-y-2">
					<div className="text-[#8b9bab] text-[13px] font-medium">
						Drop Pin Question
					</div>
					<div className="text-[#8b9bab] text-[14px]">
						Location-based answer required
					</div>
				</div>
			);
		}

		return null;
	};

	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-[14px] p-5 space-y-4">
			<div className="flex items-center gap-3">
				<Badge className="bg-[#64a7ff] border-transparent text-black font-medium">
					#{index + 1}
				</Badge>
				<Badge
					className={`${questionTypeBadgeColors[question.type]} border-transparent text-white`}
				>
					{questionTypeLabels[question.type]}
				</Badge>
			</div>

			<div className="text-white text-[16px] font-medium leading-6">
				{question.questionText}
			</div>

			{question.imageUrl && (
				<div className="w-full max-h-48 overflow-hidden rounded-lg">
					<img
						src={question.imageUrl}
						alt="Question"
						className="w-full h-full object-cover"
					/>
				</div>
			)}

			{renderAnswerDetails()}
		</div>
	);
}

export function ViewQuizQuestionsDialog({
	open,
	onOpenChange,
	quizTitle,
	questions,
	isLoading,
}: ViewQuizQuestionsDialogProps) {
	return (
		<Dialog open={open} onOpenChange={onOpenChange}>
			<DialogContent className="max-w-3xl bg-[#0a0f1a] border-[#253347] text-white max-h-[85vh] flex flex-col">
				<DialogHeader>
					<DialogTitle className="text-white text-[24px] font-bold">
						View Questions
					</DialogTitle>
					<DialogDescription className="text-[#8b9bab] text-[14px]">
						{quizTitle} • {questions.length} question
						{questions.length !== 1 ? "s" : ""}
					</DialogDescription>
				</DialogHeader>

				<div className="flex-1 overflow-y-auto pr-2 space-y-4">
					{isLoading ? (
						<div className="flex items-center justify-center py-12">
							<div className="text-[#8b9bab]">Loading questions...</div>
						</div>
					) : questions.length === 0 ? (
						<div className="flex flex-col items-center justify-center py-12 space-y-3">
							<FileQuestion className="w-12 h-12 text-[#8b9bab]" />
							<div className="text-[#8b9bab] text-center">
								No questions found in this quiz
							</div>
						</div>
					) : (
						questions
							.sort((a, b) => a.orderIndex - b.orderIndex)
							.map((question, index) => (
								<QuestionCard
									key={question.id}
									question={question}
									index={index}
								/>
							))
					)}
				</div>

				<DialogFooter>
					<Button
						onClick={() => onOpenChange(false)}
						className="bg-[#64a7ff] hover:bg-[#5296ee] text-black"
					>
						Close
					</Button>
				</DialogFooter>
			</DialogContent>
		</Dialog>
	);
}
