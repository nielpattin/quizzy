import { Button } from "@/components/ui/button";
import {
	Dialog,
	DialogContent,
	DialogDescription,
	DialogFooter,
	DialogHeader,
	DialogTitle,
} from "@/components/ui/dialog";

interface DeleteQuizDialogProps {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	onConfirm: () => void;
	isDeleting: boolean;
	quizTitle: string;
}

export function DeleteQuizDialog({
	open,
	onOpenChange,
	onConfirm,
	isDeleting,
	quizTitle,
}: DeleteQuizDialogProps) {
	return (
		<Dialog open={open} onOpenChange={onOpenChange}>
			<DialogContent className="bg-[#1a2433] border-[#253347] text-white">
				<DialogHeader>
					<DialogTitle className="text-white">Delete Quiz</DialogTitle>
					<DialogDescription className="text-[#8b9bab]">
						Are you sure you want to delete "{quizTitle}"? This action cannot be
						undone.
					</DialogDescription>
				</DialogHeader>
				<DialogFooter>
					<Button
						variant="outline"
						onClick={() => onOpenChange(false)}
						disabled={isDeleting}
						className="bg-transparent border-[#253347] text-white hover:bg-[#253347]"
					>
						Cancel
					</Button>
					<Button
						onClick={onConfirm}
						disabled={isDeleting}
						className="bg-red-600 hover:bg-red-700 text-white"
					>
						{isDeleting ? "Deleting..." : "Delete"}
					</Button>
				</DialogFooter>
			</DialogContent>
		</Dialog>
	);
}
