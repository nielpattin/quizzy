import { ChevronDown, Search } from "lucide-react";

interface ContestFiltersProps {
	searchQuery: string;
	onSearchChange: (query: string) => void;
	typeFilter: string;
	onTypeChange: (type: string) => void;
	categoryFilter: string;
	onCategoryChange: (category: string) => void;
}

export function ContestFilters({
	searchQuery,
	onSearchChange,
	typeFilter,
	onTypeChange,
	categoryFilter,
	onCategoryChange,
}: ContestFiltersProps) {
	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-[14px] px-[25px] py-[25px]">
			<div className="flex items-center justify-between">
				{/* Search */}
				<div className="relative w-[378px]">
					<Search className="absolute left-[12px] top-[10px] w-4 h-4 text-[#8b9bab]" />
					<input
						type="text"
						placeholder="Search contests..."
						value={searchQuery}
						onChange={(e) => onSearchChange(e.target.value)}
						className="w-full h-[36px] bg-[rgba(37,51,71,0.3)] border border-[#253347] rounded-[8px] pl-[40px] pr-[12px] py-[4px] text-[#8b9bab] text-[14px] placeholder:text-[#8b9bab] focus:outline-none focus:border-[#64a7ff]"
					/>
				</div>

				{/* Filters */}
				<div className="flex items-center gap-3">
					<div className="relative">
						<select
							value={typeFilter}
							onChange={(e) => onTypeChange(e.target.value)}
							className="h-[36px] w-[128px] bg-[rgba(37,51,71,0.3)] border border-[#253347] rounded-[8px] px-[13px] py-[2px] text-[#8b9bab] text-[14px] appearance-none cursor-pointer focus:outline-none focus:border-[#64a7ff]"
						>
							<option value="all">Type</option>
							<option value="tournament">Tournament</option>
							<option value="1v1">1v1</option>
							<option value="battle">Battle</option>
						</select>
						<ChevronDown className="absolute right-[13px] top-[10px] w-4 h-4 text-[#8b9bab] pointer-events-none" />
					</div>

					<div className="relative">
						<select
							value={categoryFilter}
							onChange={(e) => onCategoryChange(e.target.value)}
							className="h-[36px] w-[160px] bg-[rgba(37,51,71,0.3)] border border-[#253347] rounded-[8px] px-[13px] py-[2px] text-[#8b9bab] text-[14px] appearance-none cursor-pointer focus:outline-none focus:border-[#64a7ff]"
						>
							<option value="all">Category</option>
							<option value="programming">Programming</option>
							<option value="math">Mathematics</option>
							<option value="science">Science</option>
							<option value="general">General Knowledge</option>
						</select>
						<ChevronDown className="absolute right-[13px] top-[10px] w-4 h-4 text-[#8b9bab] pointer-events-none" />
					</div>
				</div>
			</div>
		</div>
	);
}
