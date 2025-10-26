import { useQuery } from "@tanstack/react-query";
import { formatDistanceToNow } from "date-fns";
import { Button } from "@/components/ui/button";
import {
	Dialog,
	DialogContent,
	DialogDescription,
	DialogFooter,
	DialogHeader,
	DialogTitle,
} from "@/components/ui/dialog";
import { useAuth } from "@/contexts/AuthContext";
import { API_BASE_URL } from "@/lib/constants";

interface Participant {
	id: string;
	score: number;
	rank: number | null;
	joinedAt: string;
	leftAt: string | null;
	user: {
		id: string;
		username: string | null;
		fullName: string;
		profilePictureUrl: string | null;
	} | null;
}

interface SessionParticipantsDialogProps {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	sessionId: string | null;
	sessionTitle: string;
}

async function fetchSessionParticipants(
	token: string,
	sessionId: string,
): Promise<Participant[]> {
	const response = await fetch(
		`${API_BASE_URL}/api/admin/sessions/${sessionId}/participants`,
		{
			headers: {
				Authorization: `Bearer ${token}`,
			},
		},
	);

	if (!response.ok) {
		throw new Error("Failed to fetch participants");
	}

	return response.json();
}

export function SessionParticipantsDialog({
	open,
	onOpenChange,
	sessionId,
	sessionTitle,
}: SessionParticipantsDialogProps) {
	const { session } = useAuth();
	const token = session?.access_token;

	const { data: participants, isLoading } = useQuery({
		queryKey: ["session-participants", sessionId],
		queryFn: () =>
			token && sessionId
				? fetchSessionParticipants(token, sessionId)
				: Promise.reject("No token or session ID"),
		enabled: !!token && !!sessionId && open,
	});

	return (
		<Dialog open={open} onOpenChange={onOpenChange}>
			<DialogContent className="max-w-3xl bg-[#0a0f1a] border-[#253347] text-white max-h-[85vh] flex flex-col">
				<DialogHeader>
					<DialogTitle className="text-white text-[24px] font-bold">
						Session Participants
					</DialogTitle>
					<DialogDescription className="text-[#8b9bab] text-[14px]">
						{sessionTitle} • {participants?.length || 0} participant
						{participants?.length !== 1 ? "s" : ""}
					</DialogDescription>
				</DialogHeader>

				<div className="flex-1 overflow-y-auto pr-2">
					{isLoading ? (
						<div className="flex items-center justify-center py-12">
							<div className="text-[#8b9bab]">Loading participants...</div>
						</div>
					) : !participants || participants.length === 0 ? (
						<div className="flex items-center justify-center py-12">
							<div className="text-[#8b9bab]">No participants yet</div>
						</div>
					) : (
						<div className="space-y-3">
							{participants.map((participant, index) => (
								<div
									key={participant.id}
									className="bg-[#1a2433] border border-[#253347] rounded-[14px] px-4 py-4"
								>
									<div className="flex items-center justify-between">
										<div className="flex items-center gap-3">
											{/* Participation Number Badge */}
											<div className="flex-shrink-0 w-[32px] h-[32px] rounded-full bg-[#64a7ff] flex items-center justify-center">
												<span className="text-black text-[14px] font-bold">
													#{index + 1}
												</span>
											</div>

											<div className="w-[40px] h-[40px] rounded-full bg-[#64a7ff] flex items-center justify-center">
												{participant.user?.profilePictureUrl ? (
													<img
														src={participant.user.profilePictureUrl}
														alt={participant.user.fullName}
														className="w-full h-full rounded-full object-cover"
													/>
												) : (
													<span className="text-black text-[14px] font-medium">
														{participant.user?.fullName
															.split(" ")
															.map((n) => n[0])
															.join("") || "?"}
													</span>
												)}
											</div>
											<div>
												<div className="text-white text-[16px] font-medium">
													{participant.user?.fullName || "Unknown User"}
												</div>
												{participant.user?.username && (
													<div className="text-[#8b9bab] text-[14px]">
														@{participant.user.username}
													</div>
												)}
											</div>
										</div>

										<div className="flex items-center gap-6">
											<div className="text-right">
												<div className="text-[#8b9bab] text-[12px]">Score</div>
												<div className="text-white text-[18px] font-bold">
													{participant.score}
												</div>
											</div>

											{participant.rank !== null && (
												<div className="text-right">
													<div className="text-[#8b9bab] text-[12px]">Rank</div>
													<div className="text-white text-[18px] font-bold">
														#{participant.rank}
													</div>
												</div>
											)}

											<div className="text-right">
												<div className="text-[#8b9bab] text-[12px]">Joined</div>
												<div className="text-[#8b9bab] text-[14px]">
													{formatDistanceToNow(new Date(participant.joinedAt), {
														addSuffix: true,
													})}
												</div>
											</div>

											{participant.leftAt && (
												<div className="text-right">
													<div className="text-[#8b9bab] text-[12px]">Left</div>
													<div className="text-[#8b9bab] text-[14px]">
														{formatDistanceToNow(new Date(participant.leftAt), {
															addSuffix: true,
														})}
													</div>
												</div>
											)}
										</div>
									</div>
								</div>
							))}
						</div>
					)}
				</div>

				<DialogFooter>
					<Button
						onClick={() => onOpenChange(false)}
						className="bg-[#64a7ff] hover:bg-[#5296ee] text-black"
					>
						Close
					</Button>
				</DialogFooter>
			</DialogContent>
		</Dialog>
	);
}
