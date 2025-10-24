import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/admin/leaderboard")({
	component: LeaderboardPage,
});

function LeaderboardPage() {
	return (
		<div className="flex flex-col gap-6">
			<div>
				<h1 className="text-white text-3xl font-bold">Leaderboard</h1>
				<p className="text-[#8b9bab] mt-1">
					View and manage platform-wide leaderboards and rankings.
				</p>
			</div>

			<div className="bg-[#1a2433] border border-[#253347] rounded-3xl p-6">
				<p className="text-[#8b9bab]">
					Leaderboard management interface will be implemented here...
				</p>
			</div>
		</div>
	);
}
