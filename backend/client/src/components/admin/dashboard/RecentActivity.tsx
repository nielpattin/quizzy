interface Activity {
	id: string;
	user: string;
	action: string;
	target?: string;
	detail?: string;
	time: string;
	color: string;
}

interface RecentActivityProps {
	activities: Activity[];
}

export function RecentActivity({ activities }: RecentActivityProps) {
	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-3xl p-6">
			<h3 className="text-white text-base mb-10">Recent Activity</h3>

			<div className="space-y-5">
				{activities.map((activity) => (
					<div key={activity.id} className="flex gap-5">
						<div
							className="size-2 rounded-full mt-2 flex-shrink-0"
							style={{ backgroundColor: activity.color }}
						/>
						<div className="flex-1 space-y-1">
							<div className="space-y-1">
								<p className="text-white text-sm">
									<span className="font-normal">{activity.user}</span>{" "}
									<span className="text-[#8b9bab]">{activity.action}</span>
									{activity.target && (
										<>
											{" "}
											<span className="font-normal">{activity.target}</span>
										</>
									)}
									{activity.detail && (
										<>
											{" "}
											<span className="text-[#8b9bab]">{activity.detail}</span>{" "}
											<span className="text-[#05df72]">92%</span>
										</>
									)}
								</p>
							</div>
							<p className="text-[#8b9bab] text-xs">{activity.time}</p>
						</div>
					</div>
				))}
			</div>
		</div>
	);
}
