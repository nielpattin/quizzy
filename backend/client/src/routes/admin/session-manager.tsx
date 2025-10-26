import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { SessionCard } from "@/components/admin/session-manager/SessionCard";
import { SessionFilters } from "@/components/admin/session-manager/SessionFilters";
import { SessionParticipantsDialog } from "@/components/admin/session-manager/SessionParticipantsDialog";
import { SessionStatsCards } from "@/components/admin/session-manager/SessionStatsCards";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/contexts/AuthContext";
import { API_BASE_URL } from "@/lib/constants";

export const Route = createFileRoute("/admin/session-manager")({
	component: SessionManagerPage,
});

interface Session {
	id: string;
	title: string;
	code: string;
	isLive: boolean;
	joinedCount: number;
	estimatedMinutes: number;
	startedAt: string | null;
	endedAt: string | null;
	createdAt: string;
	host: {
		id: string;
		username: string | null;
		fullName: string;
		profilePictureUrl: string | null;
	} | null;
	snapshot: {
		id: string;
		title: string;
		questionCount: number;
	} | null;
}

interface SessionsResponse {
	sessions: Session[];
	total: number;
	page: number;
	limit: number;
}

async function fetchSessions(
	token: string,
	params: {
		search?: string;
		status?: string;
		page?: number;
		limit?: number;
	},
): Promise<SessionsResponse> {
	const searchParams = new URLSearchParams();
	if (params.search) searchParams.append("search", params.search);
	if (params.status && params.status !== "all")
		searchParams.append("status", params.status);
	if (params.page) searchParams.append("page", params.page.toString());
	if (params.limit) searchParams.append("limit", params.limit.toString());

	const response = await fetch(
		`${API_BASE_URL}/api/admin/sessions?${searchParams}`,
		{
			headers: {
				Authorization: `Bearer ${token}`,
			},
		},
	);

	if (!response.ok) {
		throw new Error("Failed to fetch sessions");
	}

	return response.json();
}

async function endSession(token: string, sessionId: string): Promise<void> {
	const response = await fetch(
		`${API_BASE_URL}/api/admin/sessions/${sessionId}/end`,
		{
			method: "POST",
			headers: {
				Authorization: `Bearer ${token}`,
			},
		},
	);

	if (!response.ok) {
		throw new Error("Failed to end session");
	}
}

async function deleteSession(token: string, sessionId: string): Promise<void> {
	const response = await fetch(
		`${API_BASE_URL}/api/admin/sessions/${sessionId}`,
		{
			method: "DELETE",
			headers: {
				Authorization: `Bearer ${token}`,
			},
		},
	);

	if (!response.ok) {
		throw new Error("Failed to delete session");
	}
}

function SessionManagerPage() {
	const queryClient = useQueryClient();
	const { session } = useAuth();
	const token = session?.access_token;

	const [searchQuery, setSearchQuery] = useState("");
	const [statusFilter, setStatusFilter] = useState("all");
	const [currentPage, setCurrentPage] = useState(1);

	const [participantsDialogOpen, setParticipantsDialogOpen] = useState(false);
	const [selectedSession, setSelectedSession] = useState<Session | null>(null);

	const { data, isLoading } = useQuery({
		queryKey: ["admin-sessions", { searchQuery, statusFilter, currentPage }],
		queryFn: () =>
			token
				? fetchSessions(token, {
						search: searchQuery,
						status: statusFilter,
						page: currentPage,
						limit: 10,
					})
				: Promise.reject("No token"),
		enabled: !!token,
	});

	const endSessionMutation = useMutation({
		mutationFn: (sessionId: string) =>
			token ? endSession(token, sessionId) : Promise.reject("No token"),
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: ["admin-sessions"] });
			queryClient.invalidateQueries({ queryKey: ["session-stats"] });
		},
	});

	const deleteSessionMutation = useMutation({
		mutationFn: (sessionId: string) =>
			token ? deleteSession(token, sessionId) : Promise.reject("No token"),
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: ["admin-sessions"] });
			queryClient.invalidateQueries({ queryKey: ["session-stats"] });
		},
	});

	const handleViewParticipants = (sessionId: string) => {
		const session = data?.sessions.find((s) => s.id === sessionId);
		if (session) {
			setSelectedSession(session);
			setParticipantsDialogOpen(true);
		}
	};

	const handleEndSession = async (sessionId: string) => {
		if (confirm("Are you sure you want to end this session?")) {
			await endSessionMutation.mutateAsync(sessionId);
		}
	};

	const handleDelete = async (sessionId: string) => {
		if (
			confirm(
				"Are you sure you want to delete this session? This action cannot be undone.",
			)
		) {
			await deleteSessionMutation.mutateAsync(sessionId);
		}
	};

	const handleMore = (sessionId: string) => {
		console.log("More options for session:", sessionId);
	};

	return (
		<div className="flex flex-col gap-6">
			{/* Header */}
			<div>
				<h1 className="text-white text-[30px] font-bold leading-9">
					Session Manager
				</h1>
				<p className="text-[#8b9bab] mt-1 text-[16px] leading-6">
					Monitor and manage all quiz sessions in real-time.
				</p>
			</div>

			{/* Stats Cards */}
			<SessionStatsCards />

			{/* Filters */}
			<SessionFilters
				searchQuery={searchQuery}
				onSearchChange={setSearchQuery}
				statusFilter={statusFilter}
				onStatusChange={setStatusFilter}
			/>

			{/* Sessions List */}
			<div className="space-y-4">
				{isLoading ? (
					<div className="flex items-center justify-center py-12">
						<div className="text-[#8b9bab]">Loading sessions...</div>
					</div>
				) : !data || data.sessions.length === 0 ? (
					<div className="flex items-center justify-center py-12">
						<div className="text-[#8b9bab]">No sessions found</div>
					</div>
				) : (
					<>
						{data.sessions.map((sessionItem) => (
							<SessionCard
								key={sessionItem.id}
								session={sessionItem}
								onViewParticipants={handleViewParticipants}
								onEndSession={handleEndSession}
								onDelete={handleDelete}
								onMore={handleMore}
							/>
						))}

						{/* Pagination */}
						{data.total > data.limit && (
							<div className="flex items-center justify-center gap-2 mt-6">
								<Button
									variant="outline"
									onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
									disabled={currentPage === 1}
									className="bg-[#1a2433] border-[#253347] text-white hover:bg-[#253347]"
								>
									Previous
								</Button>
								<span className="text-[#8b9bab] px-4">
									Page {currentPage} of {Math.ceil(data.total / data.limit)}
								</span>
								<Button
									variant="outline"
									onClick={() => setCurrentPage((p) => p + 1)}
									disabled={currentPage >= Math.ceil(data.total / data.limit)}
									className="bg-[#1a2433] border-[#253347] text-white hover:bg-[#253347]"
								>
									Next
								</Button>
							</div>
						)}
					</>
				)}
			</div>

			{/* Participants Dialog */}
			<SessionParticipantsDialog
				open={participantsDialogOpen}
				onOpenChange={setParticipantsDialogOpen}
				sessionId={selectedSession?.id || null}
				sessionTitle={selectedSession?.title || ""}
			/>
		</div>
	);
}
