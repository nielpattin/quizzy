import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/admin/")({
	component: DashboardPage,
});

function DashboardPage() {
	return (
		<div className="flex flex-col gap-6">
			<div>
				<h1 className="text-white text-3xl font-bold">Dashboard</h1>
				<p className="text-[#8b9bab] mt-1">
					Welcome back! Here's what's happening with your quiz platform.
				</p>
			</div>

			{/* Stats Cards */}
			<div className="grid grid-cols-4 gap-6">
				<StatCard
					title="Total Users"
					value="12,847"
					change="+12.5%"
					icon="👥"
				/>
				<StatCard
					title="Active Quizzes"
					value="1,284"
					change="+8.2%"
					icon="📝"
				/>
				<StatCard
					title="Total Attempts"
					value="45,632"
					change="+23.1%"
					icon="📊"
				/>
				<StatCard title="Avg. Score" value="78.5%" change="+5.3%" icon="⭐" />
			</div>

			{/* Placeholder Content */}
			<div className="bg-[#1a2433] border border-[#253347] rounded-3xl p-6">
				<h2 className="text-white text-lg font-semibold mb-4">
					Dashboard Content
				</h2>
				<p className="text-[#8b9bab]">
					Dashboard charts and data will be implemented here...
				</p>
			</div>
		</div>
	);
}

function StatCard({
	title,
	value,
	change,
	icon,
}: {
	title: string;
	value: string;
	change: string;
	icon: string;
}) {
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
				<div className="text-4xl">{icon}</div>
			</div>
		</div>
	);
}
