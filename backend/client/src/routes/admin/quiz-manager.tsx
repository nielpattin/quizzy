import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/admin/quiz-manager")({
	component: QuizManagerPage,
});

function QuizManagerPage() {
	return (
		<div className="flex flex-col gap-6">
			<div>
				<h1 className="text-white text-3xl font-bold">Quiz Manager</h1>
				<p className="text-[#8b9bab] mt-1">
					Manage all quizzes, create new ones, and edit existing quizzes.
				</p>
			</div>

			<div className="bg-[#1a2433] border border-[#253347] rounded-3xl p-6">
				<p className="text-[#8b9bab]">
					Quiz management interface will be implemented here...
				</p>
			</div>
		</div>
	);
}
