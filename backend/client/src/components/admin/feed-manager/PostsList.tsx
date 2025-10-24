import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
	DropdownMenu,
	DropdownMenuContent,
	DropdownMenuItem,
	DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { MoreVertical, MessageSquare, Heart, HelpCircle } from "lucide-react";
import { formatDistanceToNow } from "date-fns";

interface Post {
	id: string;
	text: string;
	postType: string;
	imageUrl?: string;
	questionType?: string;
	questionText?: string;
	answersCount: number;
	likesCount: number;
	commentsCount: number;
	moderationStatus: string;
	createdAt: string;
	user: {
		id: string;
		fullName: string;
		username: string;
		profilePictureUrl?: string;
		accountType: string;
	};
}

interface PostsListProps {
	posts: Post[];
	isLoading: boolean;
	onModerate: (postId: string, status: string) => void;
	onDelete: (postId: string) => void;
}

export default function PostsList({
	posts,
	isLoading,
	onModerate,
	onDelete,
}: PostsListProps) {
	if (isLoading) {
		return (
			<div className="flex justify-center items-center py-12">
				<div className="w-8 h-8 border-4 border-[#64a7ff] border-t-transparent rounded-full animate-spin" />
			</div>
		);
	}

	if (posts.length === 0) {
		return (
			<div className="text-center py-12">
				<p className="text-gray-400">No posts found</p>
			</div>
		);
	}

	const getStatusColor = (status: string) => {
		switch (status) {
			case "approved":
				return "bg-[#00a63e] text-white";
			case "flagged":
				return "bg-[#e7000b] text-white";
			case "review_pending":
				return "bg-[#d08700] text-white";
			case "rejected":
				return "bg-gray-600 text-white";
			default:
				return "bg-gray-600 text-white";
		}
	};

	const getStatusLabel = (status: string) => {
		switch (status) {
			case "approved":
				return "Approved";
			case "flagged":
				return "Flagged";
			case "review_pending":
				return "Pending";
			case "rejected":
				return "Rejected";
			default:
				return status;
		}
	};

	return (
		<div className="space-y-4">
			{posts.map((post) => (
				<div
					key={post.id}
					className="bg-[#1a2433] border border-[#253347] rounded-lg p-6"
				>
					<div className="flex items-start justify-between mb-4">
						<div className="flex items-center gap-3">
							<Avatar className="w-12 h-12">
								<AvatarImage src={post.user.profilePictureUrl} />
								<AvatarFallback className="bg-[#64a7ff] text-white">
									{post.user.fullName.charAt(0)}
								</AvatarFallback>
							</Avatar>
							<div>
								<p className="text-white font-medium">{post.user.fullName}</p>
								<p className="text-gray-400 text-sm">
									@{post.user.username || "user"} ·{" "}
									{formatDistanceToNow(new Date(post.createdAt), {
										addSuffix: true,
									})}
								</p>
							</div>
						</div>

						<div className="flex items-center gap-2">
							<Badge className={getStatusColor(post.moderationStatus)}>
								{getStatusLabel(post.moderationStatus)}
							</Badge>
							{post.user.accountType === "admin" && (
								<Badge className="bg-purple-600 text-white">Admin</Badge>
							)}
							<DropdownMenu>
								<DropdownMenuTrigger asChild>
									<Button
										variant="ghost"
										size="sm"
										className="text-gray-400 hover:text-white"
									>
										<MoreVertical className="w-4 h-4" />
									</Button>
								</DropdownMenuTrigger>
								<DropdownMenuContent
									align="end"
									className="bg-[#1a2433] border-[#253347]"
								>
									{post.moderationStatus !== "approved" && (
										<DropdownMenuItem
											onClick={() => onModerate(post.id, "approved")}
											className="text-white hover:bg-[#253347]"
										>
											Approve
										</DropdownMenuItem>
									)}
									{post.moderationStatus !== "flagged" && (
										<DropdownMenuItem
											onClick={() => onModerate(post.id, "flagged")}
											className="text-white hover:bg-[#253347]"
										>
											Flag
										</DropdownMenuItem>
									)}
									{post.moderationStatus !== "rejected" && (
										<DropdownMenuItem
											onClick={() => onModerate(post.id, "rejected")}
											className="text-white hover:bg-[#253347]"
										>
											Reject
										</DropdownMenuItem>
									)}
									<DropdownMenuItem
										onClick={() => onDelete(post.id)}
										className="text-red-400 hover:bg-[#253347]"
									>
										Delete
									</DropdownMenuItem>
								</DropdownMenuContent>
							</DropdownMenu>
						</div>
					</div>

					<div className="mb-4">
						<p className="text-white mb-3">{post.text}</p>

						{post.postType === "image" && post.imageUrl && (
							<div className="relative rounded-lg overflow-hidden mb-3">
								<img
									src={post.imageUrl}
									alt="Post"
									className="w-full max-h-96 object-cover"
								/>
							</div>
						)}

						{post.postType === "quiz" && (
							<div className="bg-[#0a0f1a] border border-[#253347] rounded-lg p-4 mb-3">
								<div className="flex items-center gap-2 mb-2">
									<HelpCircle className="w-5 h-5 text-[#64a7ff]" />
									<span className="text-[#64a7ff] text-sm font-medium">
										Quiz Post
									</span>
								</div>
								{post.questionText && (
									<p className="text-white font-medium">{post.questionText}</p>
								)}
								{post.imageUrl && (
									<div className="relative rounded-lg overflow-hidden mt-3">
										<img
											src={post.imageUrl}
											alt="Quiz"
											className="w-full max-h-48 object-cover"
										/>
									</div>
								)}
							</div>
						)}
					</div>

					<div className="flex items-center gap-6 text-gray-400 text-sm">
						<div className="flex items-center gap-2">
							<Heart className="w-4 h-4" />
							<span>{post.likesCount}</span>
						</div>
						<div className="flex items-center gap-2">
							<MessageSquare className="w-4 h-4" />
							<span>{post.commentsCount}</span>
						</div>
						{post.postType === "quiz" && (
							<div className="flex items-center gap-2">
								<HelpCircle className="w-4 h-4" />
								<span>{post.answersCount} answers</span>
							</div>
						)}
						<div className="flex items-center gap-2 ml-auto">
							<Badge
								variant="outline"
								className="border-[#253347] text-gray-400"
							>
								{post.postType}
							</Badge>
						</div>
					</div>
				</div>
			))}
		</div>
	);
}
