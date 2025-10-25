import { Button } from "@/components/ui/button";
import { FileText, Bell, FileBarChart, Zap } from "lucide-react";

interface QuickActionsProps {
	onCreateQuiz?: () => void;
	onStartContest?: () => void;
	onSendNotification?: () => void;
	onGenerateReport?: () => void;
}

export function QuickActions({
	onCreateQuiz,
	onStartContest,
	onSendNotification,
	onGenerateReport,
}: QuickActionsProps) {
	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-3xl p-6">
			<h3 className="text-white text-base mb-8">Quick Actions</h3>

			<div className="grid grid-cols-4 gap-4">
				<Button
					onClick={onCreateQuiz}
					className="bg-[#64a7ff] hover:bg-[#5090e8] text-black h-14 rounded-2xl flex items-center justify-center gap-2"
				>
					<FileText className="size-5" />
					Create New Quiz
				</Button>

				<Button
					onClick={onStartContest}
					variant="outline"
					className="bg-[#0a0f1a] border-[#253347] hover:bg-[#253347] text-white h-14 rounded-2xl flex items-center justify-center gap-2"
				>
					<Zap className="size-5" />
					Start Contest
				</Button>

				<Button
					onClick={onSendNotification}
					variant="outline"
					className="bg-[#0a0f1a] border-[#253347] hover:bg-[#253347] text-white h-14 rounded-2xl flex items-center justify-center gap-2"
				>
					<Bell className="size-5" />
					Send Notification
				</Button>

				<Button
					onClick={onGenerateReport}
					variant="outline"
					className="bg-[#0a0f1a] border-[#253347] hover:bg-[#253347] text-white h-14 rounded-2xl flex items-center justify-center gap-2"
				>
					<FileBarChart className="size-5" />
					Generate Report
				</Button>
			</div>
		</div>
	);
}
