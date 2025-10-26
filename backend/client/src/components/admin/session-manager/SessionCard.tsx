import { formatDistanceToNow } from "date-fns";
import {
	MoreVertical,
	Trash2,
	Users as UsersIcon,
	XCircle,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";

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

interface SessionCardProps {
	session: Session;
	onViewParticipants: (id: string) => void;
	onEndSession: (id: string) => void;
	onDelete: (id: string) => void;
	onMore: (id: string) => void;
}

export function SessionCard({
	session,
	onViewParticipants,
	onEndSession,
	onDelete,
	onMore,
}: SessionCardProps) {
	const getStatus = () => {
		if (session.endedAt) return { label: "Completed", color: "bg-[#8b9bab]" };
		if (session.isLive && session.startedAt)
			return { label: "Live", color: "bg-[#00a63e]" };
		return { label: "Waiting", color: "bg-[#d08700]" };
	};

	const status = getStatus();

	const getDuration = () => {
		if (session.endedAt && session.startedAt) {
			const start = new Date(session.startedAt);
			const end = new Date(session.endedAt);
			const durationMs = end.getTime() - start.getTime();
			const minutes = Math.floor(durationMs / 60000);
			return `${minutes} min`;
		}
		if (session.startedAt) {
			const start = new Date(session.startedAt);
			const now = new Date();
			const durationMs = now.getTime() - start.getTime();
			const minutes = Math.floor(durationMs / 60000);
			return `${minutes} min (ongoing)`;
		}
		return `Est. ${session.estimatedMinutes} min`;
	};

	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-[14px] px-[25px] py-[25px]">
			<div className="flex items-start justify-between">
				<div className="flex-1 space-y-3">
					{/* Header */}
					<div className="flex items-center gap-3">
						<h3 className="text-white font-bold text-[16px] leading-6">
							{session.title}
						</h3>
						<Badge
							className={`${status.color} border-transparent text-white text-[12px] font-normal h-[22px] px-[9px] py-[3px] rounded-[8px]`}
						>
							{status.label}
						</Badge>
						<Badge className="border border-[#253347] text-[#8b9bab] text-[12px] font-normal h-[22px] px-[9px] py-[3px] rounded-[8px]">
							Code: {session.code}
						</Badge>
					</div>

					{/* Host Info */}
					{session.host && (
						<div className="flex items-center gap-2">
							<div className="w-[24px] h-[24px] rounded-full bg-[#64a7ff] flex items-center justify-center">
								{session.host.profilePictureUrl ? (
									<img
										src={session.host.profilePictureUrl}
										alt={session.host.fullName}
										className="w-full h-full rounded-full object-cover"
									/>
								) : (
									<span className="text-black text-[10px] font-medium">
										{session.host.fullName
											.split(" ")
											.map((n) => n[0])
											.join("")}
									</span>
								)}
							</div>
							<span className="text-[#8b9bab] text-[14px]">
								Host: {session.host.fullName}
								{session.host.username && ` (@${session.host.username})`}
							</span>
						</div>
					)}

					{/* Stats */}
					<div className="flex items-center gap-6 text-[#8b9bab] text-[14px] leading-5">
						<span>{session.joinedCount} participants</span>
						<span>{getDuration()}</span>
						{session.snapshot && (
							<span>{session.snapshot.questionCount} questions</span>
						)}
						<span>
							Created{" "}
							{formatDistanceToNow(new Date(session.createdAt), {
								addSuffix: true,
							})}
						</span>
					</div>

					{/* Timestamps */}
					{session.startedAt && (
						<div className="text-[#8b9bab] text-[13px]">
							Started: {new Date(session.startedAt).toLocaleString()}
						</div>
					)}
					{session.endedAt && (
						<div className="text-[#8b9bab] text-[13px]">
							Ended: {new Date(session.endedAt).toLocaleString()}
						</div>
					)}
				</div>

				{/* Actions */}
				<div className="flex items-center gap-2">
					<button
						type="button"
						onClick={() => onViewParticipants(session.id)}
						className="w-[36px] h-[32px] flex items-center justify-center rounded-[8px] hover:bg-[#253347] transition-colors"
						title="View Participants"
					>
						<UsersIcon className="w-4 h-4 text-[#8b9bab]" />
					</button>

					{!session.endedAt && (
						<button
							type="button"
							onClick={() => onEndSession(session.id)}
							className="w-[36px] h-[32px] flex items-center justify-center rounded-[8px] hover:bg-[#253347] transition-colors"
							title="End Session"
						>
							<XCircle className="w-4 h-4 text-[#8b9bab]" />
						</button>
					)}

					<button
						type="button"
						onClick={() => onDelete(session.id)}
						className="w-[36px] h-[32px] flex items-center justify-center rounded-[8px] hover:bg-[#253347] transition-colors"
						title="Delete"
					>
						<Trash2 className="w-4 h-4 text-[#8b9bab]" />
					</button>

					<button
						type="button"
						onClick={() => onMore(session.id)}
						className="w-[36px] h-[32px] flex items-center justify-center rounded-[8px] hover:bg-[#253347] transition-colors"
						title="More"
					>
						<MoreVertical className="w-4 h-4 text-[#8b9bab]" />
					</button>
				</div>
			</div>
		</div>
	);
}
