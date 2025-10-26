import { useQuery } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import {
	AlertCircle,
	AlertTriangle,
	Info,
	Bug,
	Activity,
	Calendar,
	Search,
	ChevronLeft,
	ChevronRight,
	Copy,
	Check,
} from "lucide-react";
import { useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from "@/components/ui/select";
import {
	Table,
	TableBody,
	TableCell,
	TableHead,
	TableHeader,
	TableRow,
} from "@/components/ui/table";
import {
	Sheet,
	SheetContent,
	SheetHeader,
	SheetTitle,
} from "@/components/ui/sheet";
import { useAuth } from "@/contexts/AuthContext";
import { API_BASE_URL } from "@/lib/constants";

export const Route = createFileRoute("/admin/logs")({
	component: LogsPage,
});

interface SystemLog {
	id: string;
	timestamp: string;
	level: "error" | "warn" | "info" | "debug" | "trace";
	message: string;
	metadata: Record<string, unknown> | null;
	userId: string | null;
	endpoint: string | null;
	method: string | null;
	statusCode: number | null;
	duration: number | null;
	error: string | null;
	ipAddress: string | null;
	userAgent: string | null;
	createdAt: string;
	userEmail: string | null;
	userName: string | null;
}

interface LogsResponse {
	logs: SystemLog[];
	pagination: {
		page: number;
		limit: number;
		total: number;
		totalPages: number;
	};
}

interface LogStatsResponse {
	totalLogs: number;
	errorLogs: number;
	warnLogs: number;
	infoLogs: number;
	recentLogs: number;
}

async function fetchLogs(
	token: string,
	params: {
		level?: string;
		search?: string;
		startDate?: string;
		endDate?: string;
		userId?: string;
		endpoint?: string;
		page?: number;
		limit?: number;
	},
): Promise<LogsResponse> {
	const searchParams = new URLSearchParams();
	if (params.level && params.level !== "all")
		searchParams.append("level", params.level);
	if (params.search) searchParams.append("search", params.search);
	if (params.startDate) searchParams.append("startDate", params.startDate);
	if (params.endDate) searchParams.append("endDate", params.endDate);
	if (params.userId) searchParams.append("userId", params.userId);
	if (params.endpoint) searchParams.append("endpoint", params.endpoint);
	if (params.page) searchParams.append("page", params.page.toString());
	if (params.limit) searchParams.append("limit", params.limit.toString());

	const response = await fetch(
		`${API_BASE_URL}/api/admin/logs?${searchParams}`,
		{
			headers: {
				Authorization: `Bearer ${token}`,
			},
		},
	);

	if (!response.ok) {
		throw new Error("Failed to fetch logs");
	}

	return response.json();
}

async function fetchLogStats(token: string): Promise<LogStatsResponse> {
	const response = await fetch(`${API_BASE_URL}/api/admin/logs/stats`, {
		headers: {
			Authorization: `Bearer ${token}`,
		},
	});

	if (!response.ok) {
		throw new Error("Failed to fetch log stats");
	}

	return response.json();
}

function LogsPage() {
	const { session } = useAuth();
	const [search, setSearch] = useState("");
	const [level, setLevel] = useState<string>("all");
	const [page, setPage] = useState(1);
	const [selectedLog, setSelectedLog] = useState<SystemLog | null>(null);
	const [copied, setCopied] = useState(false);
	const limit = 50;

	const { data: stats } = useQuery({
		queryKey: ["logStats", session?.access_token],
		queryFn: () => fetchLogStats(session?.access_token || ""),
		enabled: !!session?.access_token,
		staleTime: 30000,
		refetchInterval: 30000,
	});

	const { data, isLoading } = useQuery({
		queryKey: ["logs", session?.access_token, search, level, page],
		queryFn: () =>
			fetchLogs(session?.access_token || "", {
				search,
				level,
				page,
				limit,
			}),
		enabled: !!session?.access_token,
		staleTime: 10000,
		refetchInterval: 30000,
	});

	const getLevelBadge = (level: string) => {
		switch (level) {
			case "error":
				return (
					<Badge variant="destructive" className="gap-1">
						<AlertCircle className="h-3 w-3" />
						Error
					</Badge>
				);
			case "warn":
				return (
					<Badge
						variant="outline"
						className="gap-1 border-[#d08700] text-[#d08700]"
					>
						<AlertTriangle className="h-3 w-3" />
						Warning
					</Badge>
				);
			case "info":
				return (
					<Badge
						variant="outline"
						className="gap-1 border-[#64a7ff] text-[#64a7ff]"
					>
						<Info className="h-3 w-3" />
						Info
					</Badge>
				);
			case "debug":
				return (
					<Badge variant="outline" className="gap-1">
						<Bug className="h-3 w-3" />
						Debug
					</Badge>
				);
			default:
				return <Badge variant="outline">{level}</Badge>;
		}
	};

	const getStatusCodeBadge = (statusCode: number | null) => {
		if (!statusCode) return null;

		if (statusCode >= 500) {
			return <Badge variant="destructive">{statusCode}</Badge>;
		}
		if (statusCode >= 400) {
			return (
				<Badge variant="outline" className="border-[#d08700] text-[#d08700]">
					{statusCode}
				</Badge>
			);
		}
		if (statusCode >= 300) {
			return <Badge variant="outline">{statusCode}</Badge>;
		}
		return (
			<Badge variant="outline" className="border-[#00a63e] text-[#00a63e]">
				{statusCode}
			</Badge>
		);
	};

	const formatTimestamp = (timestamp: string) => {
		const date = new Date(timestamp);
		return new Intl.DateTimeFormat("en-US", {
			month: "short",
			day: "numeric",
			hour: "2-digit",
			minute: "2-digit",
			second: "2-digit",
		}).format(date);
	};

	const formatDuration = (duration: number | null) => {
		if (!duration) return null;
		if (duration < 1000) return `${duration}ms`;
		return `${(duration / 1000).toFixed(2)}s`;
	};

	return (
		<div className="flex min-h-screen flex-col gap-6 p-6">
			{/* Header */}
			<div className="flex items-center justify-between">
				<div>
					<h1 className="text-2xl font-bold text-[#e0e0e0]">System Logs</h1>
					<p className="text-sm text-[#8b9bab]">
						Monitor application logs and system events
					</p>
				</div>
				<Button
					variant="outline"
					size="sm"
					onClick={() => window.location.reload()}
				>
					<Activity className="mr-2 h-4 w-4" />
					Refresh
				</Button>
			</div>

			{/* Stats Cards */}
			{stats && (
				<div className="grid grid-cols-1 gap-4 md:grid-cols-5">
					<div className="rounded-lg bg-[#1a2433] p-4">
						<div className="flex items-center justify-between">
							<span className="text-sm text-[#8b9bab]">Total Logs</span>
							<Activity className="h-4 w-4 text-[#64a7ff]" />
						</div>
						<div className="mt-2 text-2xl font-bold text-[#e0e0e0]">
							{stats.totalLogs.toLocaleString()}
						</div>
					</div>

					<div className="rounded-lg bg-[#1a2433] p-4">
						<div className="flex items-center justify-between">
							<span className="text-sm text-[#8b9bab]">Errors</span>
							<AlertCircle className="h-4 w-4 text-[#e7000b]" />
						</div>
						<div className="mt-2 text-2xl font-bold text-[#e7000b]">
							{stats.errorLogs.toLocaleString()}
						</div>
					</div>

					<div className="rounded-lg bg-[#1a2433] p-4">
						<div className="flex items-center justify-between">
							<span className="text-sm text-[#8b9bab]">Warnings</span>
							<AlertTriangle className="h-4 w-4 text-[#d08700]" />
						</div>
						<div className="mt-2 text-2xl font-bold text-[#d08700]">
							{stats.warnLogs.toLocaleString()}
						</div>
					</div>

					<div className="rounded-lg bg-[#1a2433] p-4">
						<div className="flex items-center justify-between">
							<span className="text-sm text-[#8b9bab]">Info</span>
							<Info className="h-4 w-4 text-[#64a7ff]" />
						</div>
						<div className="mt-2 text-2xl font-bold text-[#64a7ff]">
							{stats.infoLogs.toLocaleString()}
						</div>
					</div>

					<div className="rounded-lg bg-[#1a2433] p-4">
						<div className="flex items-center justify-between">
							<span className="text-sm text-[#8b9bab]">Last 24h</span>
							<Calendar className="h-4 w-4 text-[#00a63e]" />
						</div>
						<div className="mt-2 text-2xl font-bold text-[#00a63e]">
							{stats.recentLogs.toLocaleString()}
						</div>
					</div>
				</div>
			)}

			{/* Filters */}
			<div className="flex flex-col gap-4 rounded-lg bg-[#1a2433] p-4 md:flex-row">
				<div className="flex-1">
					<div className="relative">
						<Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[#8b9bab]" />
						<Input
							placeholder="Search logs by message or endpoint..."
							value={search}
							onChange={(e) => {
								setSearch(e.target.value);
								setPage(1);
							}}
							className="border-[#253347] bg-[#0a0f1a] pl-10 text-[#e0e0e0] placeholder:text-[#8b9bab]"
						/>
					</div>
				</div>

				<Select
					value={level}
					onValueChange={(value) => {
						setLevel(value);
						setPage(1);
					}}
				>
					<SelectTrigger className="w-[180px] border-[#253347] bg-[#0a0f1a] text-[#e0e0e0]">
						<SelectValue placeholder="Log Level" />
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="all">All Levels</SelectItem>
						<SelectItem value="error">Error</SelectItem>
						<SelectItem value="warn">Warning</SelectItem>
						<SelectItem value="info">Info</SelectItem>
						<SelectItem value="debug">Debug</SelectItem>
					</SelectContent>
				</Select>
			</div>

			{/* Logs Table */}
			<div className="rounded-lg bg-[#1a2433]">
				<Table>
					<TableHeader>
						<TableRow className="border-b border-[#253347] hover:bg-transparent">
							<TableHead className="text-[#8b9bab]">Timestamp</TableHead>
							<TableHead className="text-[#8b9bab]">Level</TableHead>
							<TableHead className="text-[#8b9bab]">Message</TableHead>
							<TableHead className="text-[#8b9bab]">Endpoint</TableHead>
							<TableHead className="text-[#8b9bab]">Status</TableHead>
							<TableHead className="text-[#8b9bab]">Duration</TableHead>
							<TableHead className="text-[#8b9bab]">User</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{isLoading ? (
							<TableRow>
								<TableCell colSpan={7} className="text-center text-[#8b9bab]">
									Loading logs...
								</TableCell>
							</TableRow>
						) : data?.logs.length === 0 ? (
							<TableRow>
								<TableCell colSpan={7} className="text-center text-[#8b9bab]">
									No logs found
								</TableCell>
							</TableRow>
						) : (
							data?.logs.map((log) => (
								<TableRow
									key={log.id}
									className="border-b border-[#253347] hover:bg-[#252B3B] cursor-pointer transition-colors"
									onClick={() => setSelectedLog(log)}
								>
									<TableCell className="text-[#cad5e2]">
										{formatTimestamp(log.timestamp)}
									</TableCell>
									<TableCell>{getLevelBadge(log.level)}</TableCell>
									<TableCell className="max-w-md">
										<div className="truncate text-[#e0e0e0]">{log.message}</div>
										{log.error && (
											<div className="mt-1 truncate text-xs text-[#e7000b]">
												{log.error}
											</div>
										)}
									</TableCell>
									<TableCell>
										{log.endpoint && (
											<div className="flex items-center gap-2">
												<Badge
													variant="outline"
													className="border-[#314158] text-[#8b9bab]"
												>
													{log.method}
												</Badge>
												<span className="truncate text-sm text-[#cad5e2]">
													{log.endpoint}
												</span>
											</div>
										)}
									</TableCell>
									<TableCell>{getStatusCodeBadge(log.statusCode)}</TableCell>
									<TableCell className="text-[#8b9bab]">
										{formatDuration(log.duration)}
									</TableCell>
									<TableCell>
										{log.userName && (
											<div className="text-sm">
												<div className="text-[#e0e0e0]">{log.userName}</div>
												<div className="text-xs text-[#8b9bab]">
													{log.userEmail}
												</div>
											</div>
										)}
									</TableCell>
								</TableRow>
							))
						)}
					</TableBody>
				</Table>
			</div>

			{/* Pagination */}
			{data && data.pagination.totalPages > 1 && (
				<div className="flex items-center justify-between">
					<div className="text-sm text-[#8b9bab]">
						Showing {(page - 1) * limit + 1} to{" "}
						{Math.min(page * limit, data.pagination.total)} of{" "}
						{data.pagination.total} logs
					</div>
					<div className="flex items-center gap-2">
						<Button
							variant="outline"
							size="sm"
							onClick={() => setPage(page - 1)}
							disabled={page === 1}
						>
							<ChevronLeft className="h-4 w-4" />
							Previous
						</Button>
						<div className="text-sm text-[#e0e0e0]">
							Page {page} of {data.pagination.totalPages}
						</div>
						<Button
							variant="outline"
							size="sm"
							onClick={() => setPage(page + 1)}
							disabled={page === data.pagination.totalPages}
						>
							Next
							<ChevronRight className="h-4 w-4" />
						</Button>
					</div>
				</div>
			)}

			{/* Log Details Side Panel */}
			<Sheet
				open={!!selectedLog}
				onOpenChange={(open) => !open && setSelectedLog(null)}
			>
				<SheetContent className="w-[600px] overflow-y-auto bg-[#1a2433] border-l border-[#253347]">
					<SheetHeader>
						<SheetTitle className="text-[#e0e0e0] flex items-center justify-between">
							<span>Log Details</span>
							<Button
								variant="outline"
								size="sm"
								onClick={() => {
									if (selectedLog) {
										navigator.clipboard.writeText(
											JSON.stringify(selectedLog, null, 2),
										);
										setCopied(true);
										setTimeout(() => setCopied(false), 2000);
									}
								}}
								className="border-[#314158] text-[#8b9bab] hover:text-[#e0e0e0]"
							>
								{copied ? (
									<>
										<Check className="mr-2 h-4 w-4" />
										Copied
									</>
								) : (
									<>
										<Copy className="mr-2 h-4 w-4" />
										Copy JSON
									</>
								)}
							</Button>
						</SheetTitle>
					</SheetHeader>

					{selectedLog && (
						<div className="mt-6 space-y-6">
							{/* Header Section */}
							<div className="space-y-3">
								<div className="flex items-center gap-2">
									{getLevelBadge(selectedLog.level)}
									{selectedLog.statusCode &&
										getStatusCodeBadge(selectedLog.statusCode)}
								</div>
								<div className="text-sm text-[#8b9bab]">
									{formatTimestamp(selectedLog.timestamp)}
								</div>
								<div className="text-xs font-mono text-[#8b9bab]">
									ID: {selectedLog.id}
								</div>
							</div>

							{/* Message Section */}
							<div className="space-y-2">
								<div className="text-sm font-semibold text-[#e0e0e0]">
									Message
								</div>
								<div className="rounded-lg bg-[#0a0f1a] p-3 text-sm text-[#cad5e2]">
									{selectedLog.message}
								</div>
							</div>

							{/* Request Details */}
							{selectedLog.endpoint && (
								<div className="space-y-2">
									<div className="text-sm font-semibold text-[#e0e0e0]">
										Request
									</div>
									<div className="space-y-2 rounded-lg bg-[#0a0f1a] p-3 text-sm">
										<div className="flex items-center gap-2">
											<span className="text-[#8b9bab]">Method:</span>
											<Badge
												variant="outline"
												className="border-[#314158] text-[#8b9bab]"
											>
												{selectedLog.method}
											</Badge>
										</div>
										<div className="flex gap-2">
											<span className="text-[#8b9bab]">Endpoint:</span>
											<span className="break-all text-[#cad5e2]">
												{selectedLog.endpoint}
											</span>
										</div>
										{selectedLog.duration && (
											<div className="flex gap-2">
												<span className="text-[#8b9bab]">Duration:</span>
												<span className="text-[#cad5e2]">
													{formatDuration(selectedLog.duration)}
												</span>
											</div>
										)}
									</div>
								</div>
							)}

							{/* User Details */}
							{selectedLog.userName && (
								<div className="space-y-2">
									<div className="text-sm font-semibold text-[#e0e0e0]">
										User
									</div>
									<div className="space-y-2 rounded-lg bg-[#0a0f1a] p-3 text-sm">
										<div className="flex gap-2">
											<span className="text-[#8b9bab]">Name:</span>
											<span className="text-[#cad5e2]">
												{selectedLog.userName}
											</span>
										</div>
										<div className="flex gap-2">
											<span className="text-[#8b9bab]">Email:</span>
											<span className="text-[#cad5e2]">
												{selectedLog.userEmail}
											</span>
										</div>
										{selectedLog.userId && (
											<div className="flex gap-2">
												<span className="text-[#8b9bab]">User ID:</span>
												<span className="font-mono text-xs text-[#8b9bab]">
													{selectedLog.userId}
												</span>
											</div>
										)}
									</div>
								</div>
							)}

							{/* Client Details */}
							<div className="space-y-2">
								<div className="text-sm font-semibold text-[#e0e0e0]">
									Client
								</div>
								<div className="space-y-2 rounded-lg bg-[#0a0f1a] p-3 text-sm">
									<div className="flex gap-2">
										<span className="text-[#8b9bab]">IP Address:</span>
										<span className="text-[#cad5e2]">
											{selectedLog.ipAddress || "unknown"}
										</span>
									</div>
									<div className="flex flex-col gap-1">
										<span className="text-[#8b9bab]">User Agent:</span>
										<span className="break-all text-xs text-[#cad5e2]">
											{selectedLog.userAgent || "unknown"}
										</span>
									</div>
								</div>
							</div>

							{/* Metadata */}
							{selectedLog.metadata && (
								<div className="space-y-2">
									<div className="text-sm font-semibold text-[#e0e0e0]">
										Metadata
									</div>
									<div className="rounded-lg bg-[#0a0f1a] p-3">
										<pre className="overflow-x-auto text-xs text-[#8b9bab]">
											{JSON.stringify(selectedLog.metadata, null, 2)}
										</pre>
									</div>
								</div>
							)}

							{/* Error Details */}
							{selectedLog.error && (
								<div className="space-y-2">
									<div className="text-sm font-semibold text-[#e7000b]">
										Error
									</div>
									<div className="rounded-lg bg-[#0a0f1a] p-3">
										<pre className="overflow-x-auto whitespace-pre-wrap text-xs text-[#e7000b]">
											{selectedLog.error}
										</pre>
									</div>
								</div>
							)}
						</div>
					)}
				</SheetContent>
			</Sheet>
		</div>
	);
}
