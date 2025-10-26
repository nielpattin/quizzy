import { createFileRoute } from "@tanstack/react-router";
import { Plus } from "lucide-react";
import { useState } from "react";
import { ContestCard } from "@/components/admin/contests/ContestCard";
import { ContestFilters } from "@/components/admin/contests/ContestFilters";
import { ContestTabs } from "@/components/admin/contests/ContestTabs";
import { QuickActions } from "@/components/admin/contests/QuickActions";
import { Recent1v1Matches } from "@/components/admin/contests/Recent1v1Matches";
import { StatsCards } from "@/components/admin/contests/StatsCards";
import { Button } from "@/components/ui/button";

export const Route = createFileRoute("/admin/contests")({
	component: ContestsPage,
});

// Mock data for contests
const mockContests = [
	{
		id: "1",
		title: "Weekly Programming Challenge",
		status: "active" as const,
		type: "tournament" as const,
		icon: "🏆",
		participants: {
			current: 156,
			max: 200,
			percentage: 78,
		},
		duration: "7 days",
		prizePool: "$500",
		difficulty: "medium" as const,
		dateRange: "2024-02-15 - 2024-02-22",
	},
	{
		id: "2",
		title: "Math Masters Battle",
		status: "active" as const,
		type: "1v1" as const,
		icon: "🔢",
		participants: {
			current: 89,
			max: 100,
			percentage: 89,
		},
		duration: "1 week",
		prizePool: "$200",
		difficulty: "hard" as const,
		dateRange: "2024-02-20 - 2024-02-27",
	},
];

function ContestsPage() {
	const [searchQuery, setSearchQuery] = useState("");
	const [typeFilter, setTypeFilter] = useState("all");
	const [categoryFilter, setCategoryFilter] = useState("all");
	const [activeTab, setActiveTab] = useState("active");

	const handleView = (id: string) => {
		console.log("View contest:", id);
	};

	const handleEdit = (id: string) => {
		console.log("Edit contest:", id);
	};

	const handleViewUsers = (id: string) => {
		console.log("View users:", id);
	};

	const handleDelete = (id: string) => {
		console.log("Delete contest:", id);
	};

	const handleMore = (id: string) => {
		console.log("More options:", id);
	};

	return (
		<div className="flex flex-col gap-6">
			{/* Header */}
			<div className="flex items-center justify-between">
				<div>
					<h1 className="text-white text-[30px] font-bold leading-9">
						Contest Management
					</h1>
					<p className="text-[#8b9bab] mt-1 text-[16px] leading-6">
						Create and manage quiz battles, tournaments, and competitions.
					</p>
				</div>

				<Button className="h-[36px] bg-[#64a7ff] hover:bg-[#5296ee] text-black text-[14px] rounded-[8px]">
					<Plus className="w-4 h-4 mr-2" />
					Create Contest
				</Button>
			</div>

			{/* Stats Cards */}
			<StatsCards />

			{/* Filters */}
			<ContestFilters
				searchQuery={searchQuery}
				onSearchChange={setSearchQuery}
				typeFilter={typeFilter}
				onTypeChange={setTypeFilter}
				categoryFilter={categoryFilter}
				onCategoryChange={setCategoryFilter}
			/>

			{/* Main Content Grid */}
			<div className="grid grid-cols-[1fr_360px] gap-6">
				{/* Left Column - Contest List */}
				<div className="space-y-8">
					<ContestTabs activeTab={activeTab} onTabChange={setActiveTab}>
						<div className="space-y-4">
							{mockContests.map((contest) => (
								<ContestCard
									key={contest.id}
									contest={contest}
									onView={handleView}
									onEdit={handleEdit}
									onViewUsers={handleViewUsers}
									onDelete={handleDelete}
									onMore={handleMore}
								/>
							))}
						</div>
					</ContestTabs>
				</div>

				{/* Right Column - Sidebar */}
				<div className="space-y-6">
					<Recent1v1Matches />
					<QuickActions />
				</div>
			</div>
		</div>
	);
}
