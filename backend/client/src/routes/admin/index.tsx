import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { DashboardStats } from "@/components/admin/dashboard/DashboardStats";
import { UserGrowthChart } from "@/components/admin/dashboard/UserGrowthChart";
import { UserRoleDistribution } from "@/components/admin/dashboard/UserRoleDistribution";
import { QuizCategories } from "@/components/admin/dashboard/QuizCategories";
import { TopPerformers } from "@/components/admin/dashboard/TopPerformers";
import { RecentActivity } from "@/components/admin/dashboard/RecentActivity";
import { QuickActions } from "@/components/admin/dashboard/QuickActions";
import { Button } from "@/components/ui/button";
import { Download, ChevronDown } from "lucide-react";

export const Route = createFileRoute("/admin/")({
	component: DashboardPage,
});

const mockDashboardData = {
	stats: {
		totalUsers: 1250,
		activeQuizzes: 342,
		totalAttempts: 8456,
		avgScore: 78.5,
		userGrowth: 12.5,
		quizGrowth: 8.2,
		attemptsGrowth: 23.1,
		scoreGrowth: 5.3,
	},
	userGrowth: [
		{ month: "Jan", activeUsers: 450, newUsers: 120, quizzesTaken: 890 },
		{ month: "Feb", activeUsers: 520, newUsers: 145, quizzesTaken: 1050 },
		{ month: "Mar", activeUsers: 680, newUsers: 180, quizzesTaken: 1320 },
		{ month: "Apr", activeUsers: 750, newUsers: 210, quizzesTaken: 1580 },
		{ month: "May", activeUsers: 920, newUsers: 240, quizzesTaken: 1820 },
		{ month: "Jun", activeUsers: 1100, newUsers: 280, quizzesTaken: 2150 },
	],
	roleDistribution: {
		members: 1180,
		employees: 70,
		total: 1250,
		growthRate: 12.5,
	},
	categories: [
		{ name: "Science", count: 85, percentage: 25, color: "#64a7ff" },
		{ name: "History", count: 68, percentage: 20, color: "#c27aff" },
		{ name: "Math", count: 58, percentage: 17, color: "#05df72" },
		{ name: "Geography", count: 51, percentage: 15, color: "#fdc700" },
		{ name: "Literature", count: 44, percentage: 13, color: "#ff6a6a" },
		{ name: "Other", count: 36, percentage: 10, color: "#8b9bab" },
	],
	topPerformers: [
		{ rank: 1, name: "Sarah Johnson", initials: "SJ", points: 2847 },
		{ rank: 2, name: "Michael Chen", initials: "MC", points: 2653 },
		{ rank: 3, name: "Emma Davis", initials: "ED", points: 2489 },
		{ rank: 4, name: "James Wilson", initials: "JW", points: 2301 },
		{ rank: 5, name: "Lisa Anderson", initials: "LA", points: 2198 },
	],
	recentActivities: [
		{
			id: "1",
			user: "John Doe",
			action: "completed",
			target: "Science Quiz #42",
			time: "2 min ago",
			color: "#05df72",
		},
		{
			id: "2",
			user: "Alice Smith",
			action: "started",
			target: "History Challenge",
			time: "15 min ago",
			color: "#64a7ff",
		},
		{
			id: "3",
			user: "Bob Martinez",
			action: "completed",
			target: "Math Assessment",
			time: "1 hour ago",
			color: "#fdc700",
		},
		{
			id: "4",
			user: "Emily Brown",
			action: "started",
			target: "Geography Quiz",
			time: "2 hours ago",
			color: "#c27aff",
		},
	],
};

function DashboardPage() {
	const navigate = useNavigate();
	const data = mockDashboardData;

	return (
		<div className="space-y-6 pb-8">
			<div className="flex items-center justify-between">
				<div className="space-y-1">
					<h1 className="text-white text-3xl font-bold">Dashboard</h1>
					<p className="text-[#8b9bab] text-base">
						Welcome back! Here's what's happening with your quiz platform.
					</p>
				</div>

				<div className="flex items-center gap-3">
					<Button
						variant="outline"
						className="bg-[rgba(37,51,71,0.3)] border-[#253347] hover:bg-[#253347] text-white h-9 rounded-lg"
					>
						Last 30 days
						<ChevronDown className="size-4" />
					</Button>

					<Button
						variant="outline"
						className="bg-[#0a0f1a] border-[#253347] hover:bg-[#253347] text-white h-9 rounded-lg"
					>
						<Download className="size-4" />
						Export Report
					</Button>

					<Button
						onClick={() => navigate({ to: "/admin/quiz-manager" })}
						className="bg-[#64a7ff] hover:bg-[#5090e8] text-black h-9 rounded-lg"
					>
						Create Quiz
					</Button>
				</div>
			</div>

			<DashboardStats stats={data.stats} />

			<div className="grid grid-cols-2 gap-6">
				<UserGrowthChart data={data.userGrowth} />
				<UserRoleDistribution data={data.roleDistribution} />
			</div>

			<div className="grid grid-cols-3 gap-6">
				<QuizCategories categories={data.categories} />
				<TopPerformers performers={data.topPerformers} />
				<RecentActivity activities={data.recentActivities} />
			</div>

			<QuickActions
				onCreateQuiz={() => navigate({ to: "/admin/quiz-manager" })}
				onStartContest={() => navigate({ to: "/admin/contests" })}
				onSendNotification={() => {}}
				onGenerateReport={() => {}}
			/>
		</div>
	);
}
