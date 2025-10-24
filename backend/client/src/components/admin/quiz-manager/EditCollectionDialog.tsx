import { useEffect, useId, useState } from "react";
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

interface EditCollectionDialogProps {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	onUpdateCollection: (
		id: string,
		data: { title: string; description: string; isPublic: boolean },
	) => Promise<void>;
	collection: {
		id: string;
		title: string;
		description: string | null;
		isPublic: boolean;
	} | null;
}

export function EditCollectionDialog({
	open,
	onOpenChange,
	onUpdateCollection,
	collection,
}: EditCollectionDialogProps) {
	const titleId = useId();
	const descriptionId = useId();
	const isPublicId = useId();

	const [title, setTitle] = useState("");
	const [description, setDescription] = useState("");
	const [isPublic, setIsPublic] = useState(true);
	const [isUpdating, setIsUpdating] = useState(false);

	useEffect(() => {
		if (collection) {
			setTitle(collection.title);
			setDescription(collection.description || "");
			setIsPublic(collection.isPublic);
		}
	}, [collection]);

	const handleSubmit = async (e: React.FormEvent) => {
		e.preventDefault();
		if (!title.trim() || !collection) return;

		setIsUpdating(true);
		try {
			await onUpdateCollection(collection.id, { title, description, isPublic });
			onOpenChange(false);
		} catch (error) {
			console.error("Failed to update collection:", error);
		} finally {
			setIsUpdating(false);
		}
	};

	return (
		<Dialog open={open} onOpenChange={onOpenChange}>
			<DialogContent className="bg-[#1a2433] border-[#253347] text-white">
				<form onSubmit={handleSubmit}>
					<DialogHeader>
						<DialogTitle className="text-white">Edit Collection</DialogTitle>
						<DialogDescription className="text-[#8b9bab]">
							Update your collection details.
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
							disabled={isUpdating}
							className="bg-transparent border-[#253347] text-white hover:bg-[#253347]"
						>
							Cancel
						</Button>
						<Button
							type="submit"
							disabled={isUpdating || !title.trim()}
							className="bg-[#64a7ff] hover:bg-[#5296ee] text-black"
						>
							{isUpdating ? "Updating..." : "Update Collection"}
						</Button>
					</DialogFooter>
				</form>
			</DialogContent>
		</Dialog>
	);
}
