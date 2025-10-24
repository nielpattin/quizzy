import { useId, useState } from "react";
import { Button } from "@/components/ui/button";
import {
	Dialog,
	DialogContent,
	DialogDescription,
	DialogFooter,
	DialogHeader,
	DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";

interface CreateCollectionDialogProps {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	onCreateCollection: (data: {
		title: string;
		description: string;
		isPublic: boolean;
	}) => Promise<void>;
}

export function CreateCollectionDialog({
	open,
	onOpenChange,
	onCreateCollection,
}: CreateCollectionDialogProps) {
	const titleId = useId();
	const descriptionId = useId();
	const isPublicId = useId();

	const [title, setTitle] = useState("");
	const [description, setDescription] = useState("");
	const [isPublic, setIsPublic] = useState(true);
	const [isCreating, setIsCreating] = useState(false);

	const handleSubmit = async (e: React.FormEvent) => {
		e.preventDefault();
		if (!title.trim()) return;

		setIsCreating(true);
		try {
			await onCreateCollection({ title, description, isPublic });
			setTitle("");
			setDescription("");
			setIsPublic(true);
			onOpenChange(false);
		} catch (error) {
			console.error("Failed to create collection:", error);
		} finally {
			setIsCreating(false);
		}
	};

	return (
		<Dialog open={open} onOpenChange={onOpenChange}>
			<DialogContent className="bg-[#1a2433] border-[#253347] text-white">
				<form onSubmit={handleSubmit}>
					<DialogHeader>
						<DialogTitle className="text-white">
							Create New Collection
						</DialogTitle>
						<DialogDescription className="text-[#8b9bab]">
							Organize your quizzes into collections for better management.
						</DialogDescription>
					</DialogHeader>

					<div className="space-y-4 py-4">
						<div className="space-y-2">
							<Label htmlFor={titleId} className="text-white">
								Title *
							</Label>
							<Input
								id={titleId}
								value={title}
								onChange={(e) => setTitle(e.target.value)}
								placeholder="Enter collection title"
								className="bg-[rgba(37,51,71,0.3)] border-[#253347] text-white placeholder:text-[#8b9bab]"
								required
							/>
						</div>

						<div className="space-y-2">
							<Label htmlFor={descriptionId} className="text-white">
								Description
							</Label>
							<Textarea
								id={descriptionId}
								value={description}
								onChange={(e) => setDescription(e.target.value)}
								placeholder="Enter collection description (optional)"
								className="bg-[rgba(37,51,71,0.3)] border-[#253347] text-white placeholder:text-[#8b9bab]"
								rows={3}
							/>
						</div>

						<div className="flex items-center justify-between">
							<Label htmlFor={isPublicId} className="text-white">
								Public Collection
							</Label>
							<Switch
								id={isPublicId}
								checked={isPublic}
								onCheckedChange={setIsPublic}
							/>
						</div>
					</div>

					<DialogFooter>
						<Button
							type="button"
							variant="outline"
							onClick={() => onOpenChange(false)}
							disabled={isCreating}
							className="bg-transparent border-[#253347] text-white hover:bg-[#253347]"
						>
							Cancel
						</Button>
						<Button
							type="submit"
							disabled={isCreating || !title.trim()}
							className="bg-[#64a7ff] hover:bg-[#5296ee] text-black"
						>
							{isCreating ? "Creating..." : "Create Collection"}
						</Button>
					</DialogFooter>
				</form>
			</DialogContent>
		</Dialog>
	);
}
