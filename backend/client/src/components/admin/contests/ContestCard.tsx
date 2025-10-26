import { Copy, Eye, MoreVertical, Trash2, Users } from "lucide-react";
import { Badge } from "@/components/ui/badge";

interface Contest {
	id: string;
	title: string;
	status: "active" | "upcoming" | "completed";
	type: "tournament" | "1v1" | "battle";
	icon: string;
	participants: {
		current: number;
		max: number;
		percentage: number;
	};
	duration: string;
	prizePool: string;
	difficulty: "easy" | "medium" | "hard";
	dateRange: string;
}

interface ContestCardProps {
	contest: Contest;
	onView: (id: string) => void;
	onEdit: (id: string) => void;
	onViewUsers: (id: string) => void;
	onDelete: (id: string) => void;
	onMore: (id: string) => void;
}

const difficultyColors = {
	easy: "bg-[#00a63e]",
	medium: "bg-[#d08700]",
	hard: "bg-[#f54900]",
};

const statusColors = {
	active: "bg-[#00a63e]",
	upcoming: "bg-[#155dfc]",
	completed: "bg-[#8b9bab]",
};

export function ContestCard({
	contest,
	onView,
	onEdit,
	onViewUsers,
	onDelete,
	onMore,
}: ContestCardProps) {
	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-[14px] px-[25px] py-[25px]">
			<div className="flex items-start justify-between">
				<div className="flex-1 space-y-4">
					{/* Header */}
					<div className="flex items-center gap-3">
						<span className="text-[20px]">{contest.icon}</span>
						<h3 className="text-white font-bold text-[16px] leading-6">
							{contest.title}
						</h3>
						<Badge
							className={`${statusColors[contest.status]} border-transparent text-white text-[12px] font-normal h-[22px] px-[9px] py-[3px] rounded-[8px]`}
						>
							{contest.status.charAt(0).toUpperCase() + contest.status.slice(1)}
						</Badge>
						<Badge className="border border-[#253347] text-white text-[12px] font-normal h-[22px] px-[9px] py-[3px] rounded-[8px]">
							{contest.type}
						</Badge>
					</div>

					{/* Stats Grid */}
					<div className="grid grid-cols-4 gap-4">
						<div className="space-y-1">
							<div className="text-[#8b9bab] text-[14px] leading-5">
								Participants
							</div>
							<div className="text-white text-[16px] leading-6">
								{contest.participants.current}/{contest.participants.max}
							</div>
							<div className="bg-[rgba(100,167,255,0.2)] h-[4px] rounded-full overflow-hidden">
								<div
									className="bg-[#64a7ff] h-full"
									style={{ width: `${contest.participants.percentage}%` }}
								/>
							</div>
						</div>

						<div className="space-y-1">
							<div className="text-[#8b9bab] text-[14px] leading-5">
								Duration
							</div>
							<div className="text-white text-[16px] leading-6">
								{contest.duration}
							</div>
						</div>

						<div className="space-y-1">
							<div className="text-[#8b9bab] text-[14px] leading-5">
								Prize Pool
							</div>
							<div className="text-white text-[16px] leading-6">
								{contest.prizePool}
							</div>
						</div>

						<div className="space-y-1">
							<div className="text-[#8b9bab] text-[14px] leading-5">
								Difficulty
							</div>
							<Badge
								className={`${difficultyColors[contest.difficulty]} border-transparent text-white text-[12px] font-normal h-[22px] px-[9px] py-[3px] rounded-[8px]`}
							>
								{contest.difficulty.charAt(0).toUpperCase() +
									contest.difficulty.slice(1)}
							</Badge>
						</div>
					</div>

					{/* Date Range */}
					<div className="text-[#8b9bab] text-[14px] leading-5">
						{contest.dateRange}
					</div>
				</div>

				{/* Actions */}
				<div className="flex items-center gap-2">
					<button
						type="button"
						onClick={() => onView(contest.id)}
						className="w-[36px] h-[32px] flex items-center justify-center rounded-[8px] hover:bg-[#253347] transition-colors"
						title="View"
					>
						<Eye className="w-4 h-4 text-[#8b9bab]" />
					</button>
					<button
						type="button"
						onClick={() => onEdit(contest.id)}
						className="w-[36px] h-[32px] flex items-center justify-center rounded-[8px] hover:bg-[#253347] transition-colors"
						title="Edit"
					>
						<Copy className="w-4 h-4 text-[#8b9bab]" />
					</button>
					<button
						type="button"
						onClick={() => onViewUsers(contest.id)}
						className="w-[36px] h-[32px] flex items-center justify-center rounded-[8px] hover:bg-[#253347] transition-colors"
						title="View Users"
					>
						<Users className="w-4 h-4 text-[#8b9bab]" />
					</button>
					<button
						type="button"
						onClick={() => onDelete(contest.id)}
						className="w-[36px] h-[32px] flex items-center justify-center rounded-[8px] hover:bg-[#253347] transition-colors"
						title="Delete"
					>
						<Trash2 className="w-4 h-4 text-[#8b9bab]" />
					</button>
					<button
						type="button"
						onClick={() => onMore(contest.id)}
						className="w-[36px] h-[32px] flex items-center justify-center rounded-[8px] hover:bg-[#253347] transition-colors"
						title="More"
					>
						<MoreVertical className="w-4 h-4 text-[#8b9bab]" />
					</button>
				</div>
			</div>
		</div>
	);
}
