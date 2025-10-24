import { Edit2, MoreVertical, Trash2, UserCog } from "lucide-react";
import { useEffect, useRef, useState } from "react";

interface UserActionsMenuProps {
	userId: string;
	onEdit?: (userId: string) => void;
	onDelete?: (userId: string) => void;
	onChangeRole?: (userId: string) => void;
}

export function UserActionsMenu({
	userId,
	onEdit,
	onDelete,
	onChangeRole,
}: UserActionsMenuProps) {
	const [isOpen, setIsOpen] = useState(false);
	const menuRef = useRef<HTMLDivElement>(null);

	useEffect(() => {
		const handleClickOutside = (event: MouseEvent) => {
			if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
				setIsOpen(false);
			}
		};

		document.addEventListener("mousedown", handleClickOutside);
		return () => document.removeEventListener("mousedown", handleClickOutside);
	}, []);

	return (
		<div className="relative" ref={menuRef}>
			<button
				type="button"
				onClick={() => setIsOpen(!isOpen)}
				className="size-8 rounded-lg hover:bg-[#253347] flex items-center justify-center text-[#8b9bab] transition-colors"
			>
				<MoreVertical className="size-4" />
			</button>

			{isOpen && (
				<div className="absolute right-0 mt-1 w-48 bg-[#1d293d] border border-[#314158] rounded-lg shadow-lg z-10">
					<div className="py-1">
						{onEdit && (
							<button
								type="button"
								onClick={() => {
									onEdit(userId);
									setIsOpen(false);
								}}
								className="w-full px-4 py-2 text-left text-sm text-white hover:bg-[#253347] flex items-center gap-2 transition-colors"
							>
								<Edit2 className="size-4" />
								Edit User
							</button>
						)}
						{onChangeRole && (
							<button
								type="button"
								onClick={() => {
									onChangeRole(userId);
									setIsOpen(false);
								}}
								className="w-full px-4 py-2 text-left text-sm text-white hover:bg-[#253347] flex items-center gap-2 transition-colors"
							>
								<UserCog className="size-4" />
								Change Role
							</button>
						)}
						{onDelete && (
							<button
								type="button"
								onClick={() => {
									onDelete(userId);
									setIsOpen(false);
								}}
								className="w-full px-4 py-2 text-left text-sm text-[#e7000b] hover:bg-[#253347] flex items-center gap-2 transition-colors"
							>
								<Trash2 className="size-4" />
								Delete User
							</button>
						)}
					</div>
				</div>
			)}
		</div>
	);
}
