import { Trophy } from "lucide-react";

interface Performer {
	rank: number;
	name: string;
	initials: string;
	points: number;
}

interface TopPerformersProps {
	performers: Performer[];
}

export function TopPerformers({ performers }: TopPerformersProps) {
	const getBadgeColor = (rank: number) => {
		switch (rank) {
			case 1:
				return "bg-[#f0b100]";
			case 2:
				return "bg-[#99a1af]";
			case 3:
				return "bg-[#ff6900]";
			default:
				return "bg-[#253347]";
		}
	};

	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-3xl p-6">
			<div className="flex items-center gap-3 mb-10">
				<div className="bg-[rgba(240,177,0,0.1)] rounded-xl size-9 flex items-center justify-center">
					<Trophy className="size-5 text-[#f0b100]" />
				</div>
				<h3 className="text-white text-base">Top Performers</h3>
			</div>

			<div className="space-y-4">
				{performers.map((performer) => (
					<div key={performer.rank} className="flex items-center gap-3">
						<div
							className={`${getBadgeColor(performer.rank)} rounded-full size-8 flex items-center justify-center`}
						>
							<span className="text-white text-sm font-normal">
								{performer.rank}
							</span>
						</div>
						<div className="bg-[#64a7ff] rounded-full size-10 flex items-center justify-center">
							<span className="text-black text-sm font-normal">
								{performer.initials}
							</span>
						</div>
						<div className="flex-1">
							<p className="text-white text-base">{performer.name}</p>
							<p className="text-[#8b9bab] text-sm">
								{performer.points.toLocaleString()} points
							</p>
						</div>
					</div>
				))}
			</div>
		</div>
	);
}
