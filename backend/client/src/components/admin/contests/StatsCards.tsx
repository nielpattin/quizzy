import { Award, DollarSign, TrendingUp, Users } from "lucide-react";

interface StatCardProps {
	label: string;
	value: string | number;
	growth: string;
	icon: React.ReactNode;
	iconBg: string;
}

function StatCard({ label, value, growth, icon, iconBg }: StatCardProps) {
	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-[14px] px-[25px] py-[25px]">
			<div className="flex items-center justify-between">
				<div className="space-y-1">
					<div className="text-[#8b9bab] text-[14px] leading-5">{label}</div>
					<div className="text-white text-[24px] font-bold leading-8">
						{value}
					</div>
					<div className="text-[#05df72] text-[14px] leading-5">{growth}</div>
				</div>
				<div
					className={`${iconBg} rounded-[14px] w-[48px] h-[48px] flex items-center justify-center`}
				>
					{icon}
				</div>
			</div>
		</div>
	);
}

export function StatsCards() {
	return (
		<div className="grid grid-cols-4 gap-6">
			<StatCard
				label="Active Contests"
				value={12}
				growth="+3"
				icon={<Award className="w-6 h-6 text-[#8b9bab]" />}
				iconBg="bg-[#253347]"
			/>
			<StatCard
				label="Total Participants"
				value="2,847"
				growth="+456"
				icon={<Users className="w-6 h-6 text-[#8b9bab]" />}
				iconBg="bg-[#253347]"
			/>
			<StatCard
				label="Prize Pool"
				value="$15,500"
				growth="+$2,500"
				icon={<DollarSign className="w-6 h-6 text-[#8b9bab]" />}
				iconBg="bg-[#253347]"
			/>
			<StatCard
				label="Avg. Participation"
				value={237}
				growth="+23"
				icon={<TrendingUp className="w-6 h-6 text-[#8b9bab]" />}
				iconBg="bg-[#253347]"
			/>
		</div>
	);
}
