import { Users } from "lucide-react";

interface UserGrowthData {
	month: string;
	activeUsers: number;
	newUsers: number;
	quizzesTaken: number;
}

interface UserGrowthChartProps {
	data: UserGrowthData[];
}

export function UserGrowthChart({ data }: UserGrowthChartProps) {
	const maxValue = Math.max(
		...data.map((d) => Math.max(d.activeUsers, d.newUsers, d.quizzesTaken)),
	);

	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-3xl p-6">
			<div className="flex items-center gap-3 mb-8">
				<div className="bg-[rgba(100,167,255,0.1)] rounded-xl size-9 flex items-center justify-center">
					<Users className="size-5 text-[#64a7ff]" />
				</div>
				<h3 className="text-white text-base">User Growth & Activity</h3>
			</div>

			<div className="space-y-6">
				<div className="h-80 relative">
					<svg
						className="w-full h-full"
						viewBox="0 0 405 320"
						role="img"
						aria-label="User growth and activity chart"
					>
						<title>User Growth & Activity Chart</title>
						<g className="grid-lines">
							{[0, 1, 2, 3, 4].map((i) => (
								<line
									key={i}
									x1="60"
									y1={5 + i * 64}
									x2="405"
									y2={5 + i * 64}
									stroke="#253347"
									strokeWidth="1"
								/>
							))}
						</g>

						<g className="y-axis-labels">
							{[14000, 10500, 7000, 3500, 0].map((value, i) => (
								<text
									key={value}
									x="50"
									y={10 + i * 64}
									fill="#8b9bab"
									fontSize="12"
									textAnchor="end"
								>
									{value}
								</text>
							))}
						</g>

						<g className="bars">
							{data.map((item, i) => {
								const x = 70 + i * 50;
								const barWidth = 12;

								const activeUsersHeight = (item.activeUsers / maxValue) * 200;
								const newUsersHeight = (item.newUsers / maxValue) * 200;
								const quizzesTakenHeight = (item.quizzesTaken / maxValue) * 200;

								return (
									<g key={item.month}>
										<rect
											x={x}
											y={260 - activeUsersHeight}
											width={barWidth}
											height={activeUsersHeight}
											fill="#fdc700"
											rx="2"
										/>
										<rect
											x={x + 14}
											y={260 - newUsersHeight}
											width={barWidth}
											height={newUsersHeight}
											fill="#64a7ff"
											rx="2"
										/>
										<rect
											x={x + 28}
											y={260 - quizzesTakenHeight}
											width={barWidth}
											height={quizzesTakenHeight}
											fill="#05df72"
											rx="2"
										/>

										<text
											x={x + 20}
											y="280"
											fill="#8b9bab"
											fontSize="12"
											textAnchor="middle"
										>
											{item.month}
										</text>
									</g>
								);
							})}
						</g>
					</svg>
				</div>

				<div className="flex items-center justify-center gap-6">
					<div className="flex items-center gap-2">
						<div className="size-3.5 rounded-full bg-[#fdc700]" />
						<span className="text-[#fdc700] text-base">Active Users</span>
					</div>
					<div className="flex items-center gap-2">
						<div className="size-3.5 rounded-full bg-[#64a7ff]" />
						<span className="text-[#64a7ff] text-base">New Users</span>
					</div>
					<div className="flex items-center gap-2">
						<div className="size-3.5 rounded-full bg-[#05df72]" />
						<span className="text-[#05df72] text-base">Quizzes Taken</span>
					</div>
				</div>
			</div>
		</div>
	);
}
