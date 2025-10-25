import { Users } from "lucide-react";

interface RoleDistribution {
	members: number;
	employees: number;
	total: number;
	growthRate: number;
}

interface UserRoleDistributionProps {
	data: RoleDistribution;
}

export function UserRoleDistribution({ data }: UserRoleDistributionProps) {
	const membersPercentage = ((data.members / data.total) * 100).toFixed(1);
	const employeesPercentage = ((data.employees / data.total) * 100).toFixed(1);

	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-3xl p-6">
			<div className="flex items-center gap-3 mb-8">
				<div className="bg-[rgba(100,167,255,0.1)] rounded-xl size-9 flex items-center justify-center">
					<Users className="size-5 text-[#64a7ff]" />
				</div>
				<h3 className="text-white text-base">User Role Distribution</h3>
			</div>

			<div className="space-y-6">
				<div className="space-y-4">
					<div className="space-y-2">
						<div className="flex items-center justify-between">
							<span className="text-white text-base">Members</span>
							<span className="text-[#8b9bab] text-base">
								{data.members.toLocaleString()} ({membersPercentage}%)
							</span>
						</div>
						<div className="bg-[#253347] h-3 rounded-full overflow-hidden">
							<div
								className="bg-[#64a7ff] h-full rounded-full"
								style={{ width: `${membersPercentage}%` }}
							/>
						</div>
					</div>

					<div className="space-y-2">
						<div className="flex items-center justify-between">
							<span className="text-white text-base">Employees</span>
							<span className="text-[#8b9bab] text-base">
								{data.employees.toLocaleString()} ({employeesPercentage}%)
							</span>
						</div>
						<div className="bg-[#253347] h-3 rounded-full overflow-hidden">
							<div
								className="bg-[#64a7ff] h-full rounded-full"
								style={{ width: `${employeesPercentage}%` }}
							/>
						</div>
					</div>
				</div>

				<div className="border-t border-[#253347] pt-6 grid grid-cols-2 gap-4">
					<div className="text-center">
						<p className="text-white text-2xl font-bold">
							{(data.total / 1000).toFixed(1)}K
						</p>
						<p className="text-[#8b9bab] text-sm mt-1">Total Users</p>
					</div>
					<div className="text-center">
						<p className="text-[#05df72] text-2xl font-bold">
							+{data.growthRate}%
						</p>
						<p className="text-[#8b9bab] text-sm mt-1">Growth Rate</p>
					</div>
				</div>
			</div>
		</div>
	);
}
