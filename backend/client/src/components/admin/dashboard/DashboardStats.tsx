import { Activity, FileText, Target, Users } from "lucide-react";

interface Stats {
	totalUsers: number;
	activeQuizzes: number;
	totalAttempts: number;
	avgScore: number;
	userGrowth: number;
	quizGrowth: number;
	attemptsGrowth: number;
	scoreGrowth: number;
}

interface DashboardStatsProps {
	stats: Stats;
}

export function DashboardStats({ stats }: DashboardStatsProps) {
	return (
		<div className="grid grid-cols-4 gap-6">
			<StatCard
				title="Total Users"
				value={stats.totalUsers.toLocaleString()}
				change={`+${stats.userGrowth}%`}
				icon={Users}
			/>
			<StatCard
				title="Active Quizzes"
				value={stats.activeQuizzes.toLocaleString()}
				change={`+${stats.quizGrowth}%`}
				icon={FileText}
			/>
			<StatCard
				title="Total Attempts"
				value={stats.totalAttempts.toLocaleString()}
				change={`+${stats.attemptsGrowth}%`}
				icon={Activity}
			/>
			<StatCard
				title="Avg. Score"
				value={`${stats.avgScore}%`}
				change={`+${stats.scoreGrowth}%`}
				icon={Target}
			/>
		</div>
	);
}

interface StatCardProps {
	title: string;
	value: string;
	change: string;
	icon: React.ComponentType<{ className?: string }>;
}

function StatCard({ title, value, change, icon: Icon }: StatCardProps) {
	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-3xl p-6">
			<div className="flex items-start justify-between">
				<div className="flex flex-col gap-2">
					<p className="text-[#8b9bab] text-sm">{title}</p>
					<p className="text-white text-3xl font-bold">{value}</p>
					<div className="bg-[rgba(0,201,80,0.1)] px-2 py-1 rounded-full inline-flex w-fit">
						<span className="text-[#05df72] text-sm font-bold">{change}</span>
					</div>
				</div>
				<div className="rounded-2xl size-15 flex items-center justify-center pt-4 px-4">
					<Icon className="size-7 text-white opacity-50" />
				</div>
			</div>
		</div>
	);
}
