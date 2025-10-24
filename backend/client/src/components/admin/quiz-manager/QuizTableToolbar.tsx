import { Search } from "lucide-react";
import { Input } from "@/components/ui/input";
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from "@/components/ui/select";

interface QuizTableToolbarProps {
	searchQuery: string;
	onSearchChange: (value: string) => void;
	categoryFilter: string;
	onCategoryChange: (value: string) => void;
	statusFilter: string;
	onStatusChange: (value: string) => void;
	showFilters?: boolean;
}

export function QuizTableToolbar({
	searchQuery,
	onSearchChange,
	categoryFilter,
	onCategoryChange,
	statusFilter,
	onStatusChange,
	showFilters = true,
}: QuizTableToolbarProps) {
	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-[14px] px-[25px] py-[25px]">
			<div className="flex items-center gap-3">
				<div className="flex-1 relative">
					<Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#8b9bab]" />
					<Input
						placeholder="Search collections and quizzes..."
						value={searchQuery}
						onChange={(e) => onSearchChange(e.target.value)}
						className="pl-10 bg-[rgba(37,51,71,0.3)] border-[#253347] text-white placeholder:text-[#8b9bab] h-[36px] rounded-[8px] text-[14px]"
					/>
				</div>

				{showFilters && (
					<>
						<Select value={categoryFilter} onValueChange={onCategoryChange}>
							<SelectTrigger className="w-[144px] h-[36px] bg-[rgba(37,51,71,0.3)] border-[#253347] text-[#8b9bab] text-[14px] rounded-[8px]">
								<SelectValue placeholder="Category" />
							</SelectTrigger>
							<SelectContent className="bg-[#1a2433] border-[#253347]">
								<SelectItem value="all" className="text-white">
									All Categories
								</SelectItem>
								<SelectItem value="Mathematics" className="text-white">
									Mathematics
								</SelectItem>
								<SelectItem value="Science" className="text-white">
									Science
								</SelectItem>
								<SelectItem value="History" className="text-white">
									History
								</SelectItem>
								<SelectItem value="Geography" className="text-white">
									Geography
								</SelectItem>
								<SelectItem value="Programming" className="text-white">
									Programming
								</SelectItem>
							</SelectContent>
						</Select>

						<Select value={statusFilter} onValueChange={onStatusChange}>
							<SelectTrigger className="w-[128px] h-[36px] bg-[rgba(37,51,71,0.3)] border-[#253347] text-[#8b9bab] text-[14px] rounded-[8px]">
								<SelectValue placeholder="Status" />
							</SelectTrigger>
							<SelectContent className="bg-[#1a2433] border-[#253347]">
								<SelectItem value="all" className="text-white">
									All Status
								</SelectItem>
								<SelectItem value="published" className="text-white">
									Published
								</SelectItem>
								<SelectItem value="draft" className="text-white">
									Draft
								</SelectItem>
							</SelectContent>
						</Select>
					</>
				)}
			</div>
		</div>
	);
}
