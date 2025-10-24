import { TrendingUp, Flag, Clock } from "lucide-react";

interface Stats {
	totalPosts: number;
	pendingReview: number;
	engagementRate: number;
	flaggedContent: number;
}

interface StatsCardsProps {
	stats?: Stats;
}

export default function StatsCards({ stats }: StatsCardsProps) {
	const cards = [
		{
			title: "Total Posts",
			value: stats?.totalPosts || 0,
			icon: TrendingUp,
			color: "text-[#64a7ff]",
		},
		{
			title: "Pending Review",
			value: stats?.pendingReview || 0,
			icon: Clock,
			color: "text-[#d08700]",
		},
		{
			title: "Engagement Rate",
			value: `${stats?.engagementRate || 0}%`,
			icon: TrendingUp,
			color: "text-[#00a63e]",
		},
		{
			title: "Flagged Content",
			value: stats?.flaggedContent || 0,
			icon: Flag,
			color: "text-[#e7000b]",
		},
	];

	return (
		<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
			{cards.map((card) => (
				<div
					key={card.title}
					className="bg-[#1a2433] border border-[#253347] rounded-lg p-6 h-[154px] flex flex-col justify-between"
				>
					<div className="flex items-center justify-between">
						<p className="text-gray-400 text-sm">{card.title}</p>
						<card.icon className={`w-5 h-5 ${card.color}`} />
					</div>
					<div>
						<p className="text-white text-4xl font-bold">{card.value}</p>
					</div>
				</div>
			))}
		</div>
	);
}
