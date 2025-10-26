import { ChevronDown, Search } from "lucide-react";

interface SessionFiltersProps {
	searchQuery: string;
	onSearchChange: (query: string) => void;
	statusFilter: string;
	onStatusChange: (status: string) => void;
}

export function SessionFilters({
	searchQuery,
	onSearchChange,
	statusFilter,
	onStatusChange,
}: SessionFiltersProps) {
	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-[14px] px-[25px] py-[25px]">
			<div className="flex items-center justify-between">
				{/* Search */}
				<div className="relative w-[378px]">
					<Search className="absolute left-[12px] top-[10px] w-4 h-4 text-[#8b9bab]" />
					<input
						type="text"
						placeholder="Search sessions by title or code..."
						value={searchQuery}
						onChange={(e) => onSearchChange(e.target.value)}
						className="w-full h-[36px] bg-[rgba(37,51,71,0.3)] border border-[#253347] rounded-[8px] pl-[40px] pr-[12px] py-[4px] text-[#8b9bab] text-[14px] placeholder:text-[#8b9bab] focus:outline-none focus:border-[#64a7ff]"
					/>
				</div>

				{/* Status Filter */}
				<div className="relative">
					<select
						value={statusFilter}
						onChange={(e) => onStatusChange(e.target.value)}
						className="h-[36px] w-[160px] bg-[rgba(37,51,71,0.3)] border border-[#253347] rounded-[8px] px-[13px] py-[2px] text-[#8b9bab] text-[14px] appearance-none cursor-pointer focus:outline-none focus:border-[#64a7ff]"
					>
						<option value="all">All Sessions</option>
						<option value="active">Active</option>
						<option value="completed">Completed</option>
					</select>
					<ChevronDown className="absolute right-[13px] top-[10px] w-4 h-4 text-[#8b9bab] pointer-events-none" />
				</div>
			</div>
		</div>
	);
}
