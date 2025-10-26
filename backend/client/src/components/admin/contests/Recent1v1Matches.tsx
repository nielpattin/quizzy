import { Swords } from "lucide-react";

interface Match {
	id: string;
	player1: {
		name: string;
		initials: string;
		score: string;
	};
	player2: {
		name: string;
		initials: string;
		score: string;
	};
	contestName: string;
	timeAgo: string;
}

const mockMatches: Match[] = [
	{
		id: "1",
		player1: { name: "Alex Chen", initials: "AC", score: "95%" },
		player2: { name: "Sarah Kim", initials: "SK", score: "87%" },
		contestName: "Math Masters Battle",
		timeAgo: "2 hours ago",
	},
	{
		id: "2",
		player1: { name: "Mike Wilson", initials: "MW", score: "78%" },
		player2: { name: "Lisa Garcia", initials: "LG", score: "82%" },
		contestName: "Frontend Developer Duel",
		timeAgo: "4 hours ago",
	},
	{
		id: "3",
		player1: { name: "David Brown", initials: "DB", score: "91%" },
		player2: { name: "Emma Davis", initials: "ED", score: "89%" },
		contestName: "Programming Challenge",
		timeAgo: "6 hours ago",
	},
];

export function Recent1v1Matches() {
	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-[14px] px-[25px] py-[25px] space-y-[30px]">
			<div className="flex items-center gap-2">
				<Swords className="w-5 h-5 text-white" />
				<h3 className="text-white text-[16px] font-normal">
					Recent 1v1 Matches
				</h3>
			</div>

			<div className="space-y-4">
				{mockMatches.map((match) => (
					<div
						key={match.id}
						className="bg-[#253347] rounded-[10px] px-4 py-4 space-y-2"
					>
						{/* Players */}
						<div className="flex items-center justify-between">
							{/* Player 1 */}
							<div className="flex items-center gap-3">
								<div className="w-[32px] h-[32px] rounded-full bg-[#64a7ff] flex items-center justify-center">
									<span className="text-black text-[12px] font-normal">
										{match.player1.initials}
									</span>
								</div>
								<div className="space-y-0">
									<div className="text-white text-[14px] leading-5">
										{match.player1.name}
									</div>
									<div className="text-[#8b9bab] text-[12px] leading-4">
										{match.player1.score}
									</div>
								</div>
							</div>

							{/* VS */}
							<div className="flex flex-col items-center">
								<div className="text-white text-[16px] font-bold leading-6">
									VS
								</div>
								<Swords className="w-4 h-4 text-[#8b9bab]" />
							</div>

							{/* Player 2 */}
							<div className="flex items-center gap-3">
								<div className="space-y-0 text-right">
									<div className="text-white text-[14px] leading-5">
										{match.player2.name}
									</div>
									<div className="text-[#8b9bab] text-[12px] leading-4">
										{match.player2.score}
									</div>
								</div>
								<div className="w-[32px] h-[32px] rounded-full bg-[#64a7ff] flex items-center justify-center">
									<span className="text-black text-[12px] font-normal">
										{match.player2.initials}
									</span>
								</div>
							</div>
						</div>

						{/* Contest Info */}
						<div className="space-y-0">
							<div className="text-[#8b9bab] text-[12px] leading-4 text-center">
								{match.contestName}
							</div>
							<div className="text-[#8b9bab] text-[12px] leading-4 text-center">
								{match.timeAgo}
							</div>
						</div>
					</div>
				))}
			</div>
		</div>
	);
}
