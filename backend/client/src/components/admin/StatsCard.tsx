import type { LucideIcon } from "lucide-react";

interface StatsCardProps {
	title: string;
	value: string | number;
	change: string;
	icon: LucideIcon;
	iconBg?: string;
}

export function StatsCard({
	title,
	value,
	change,
	icon: Icon,
	iconBg = "bg-[#314158]",
}: StatsCardProps) {
	const isPositive = change.startsWith("+");

	return (
		<div className="bg-[#1d293d] border border-[#314158] rounded-2xl p-6">
			<div className="flex items-center justify-between">
				<div className="flex flex-col gap-2">
					<p className="text-[#90a1b9] text-sm">{title}</p>
					<p className="text-white text-2xl font-bold">{value}</p>
					<p
						className={`text-sm ${isPositive ? "text-[#05df72]" : "text-[#e7000b]"}`}
					>
						{change}
					</p>
				</div>
				<div
					className={`${iconBg} rounded-xl size-12 flex items-center justify-center`}
				>
					<Icon className="size-6 text-white" />
				</div>
			</div>
		</div>
	);
}
