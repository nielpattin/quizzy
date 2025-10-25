import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { Search, Flag, CheckCircle2, Clock } from "lucide-react";
import PostsList from "@/components/admin/feed-manager/PostsList";
import StatsCards from "@/components/admin/feed-manager/StatsCards";
import { useAuth } from "@/contexts/AuthContext";
import { API_BASE_URL } from "@/lib/constants";

export const Route = createFileRoute("/admin/feed-manager")({
	component: FeedManager,
});

function FeedManager() {
	const { session } = useAuth();
	const token = session?.access_token;
	const [activeTab, setActiveTab] = useState("all");
	const [search, setSearch] = useState("");
	const [postType, setPostType] = useState("all");
	const [page, setPage] = useState(1);
	const queryClient = useQueryClient();

	const { data: stats } = useQuery({
		queryKey: ["admin", "posts", "stats"],
		queryFn: async () => {
			const response = await fetch(`${API_BASE_URL}/api/admin/posts/stats`, {
				headers: {
					Authorization: `Bearer ${token}`,
				},
			});
			if (!response.ok) throw new Error("Failed to fetch stats");
			return response.json();
		},
	});

	const { data: postsData, isLoading } = useQuery({
		queryKey: ["admin", "posts", activeTab, search, postType, page],
		queryFn: async () => {
			const params = new URLSearchParams({
				page: page.toString(),
				limit: "10",
			});
			if (search) params.append("search", search);
			if (postType !== "all") params.append("postType", postType);
			if (activeTab !== "all") params.append("status", activeTab);

			const response = await fetch(
				`${API_BASE_URL}/api/admin/posts?${params}`,
				{
					headers: {
						Authorization: `Bearer ${token}`,
					},
				},
			);
			if (!response.ok) throw new Error("Failed to fetch posts");
			return response.json();
		},
	});

	const moderateMutation = useMutation({
		mutationFn: async ({
			postId,
			status,
		}: {
			postId: string;
			status: string;
		}) => {
			const response = await fetch(
				`${API_BASE_URL}/api/admin/posts/${postId}/moderate`,
				{
					method: "PUT",
					headers: {
						"Content-Type": "application/json",
						Authorization: `Bearer ${token}`,
					},
					body: JSON.stringify({ status }),
				},
			);
			if (!response.ok) throw new Error("Failed to moderate post");
			return response.json();
		},
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: ["admin", "posts"] });
		},
	});

	const deleteMutation = useMutation({
		mutationFn: async (postId: string) => {
			const response = await fetch(
				`${API_BASE_URL}/api/admin/posts/${postId}`,
				{
					method: "DELETE",
					headers: {
						Authorization: `Bearer ${token}`,
					},
				},
			);
			if (!response.ok) throw new Error("Failed to delete post");
			return response.json();
		},
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: ["admin", "posts"] });
		},
	});

	return (
		<div className="flex-1 overflow-auto p-8">
			<div className="mb-8">
				<h1 className="text-3xl font-bold text-white mb-2">Feed Manager</h1>
				<p className="text-gray-400">
					Monitor and moderate user-generated content
				</p>
			</div>

			<StatsCards stats={stats} />

			<div className="bg-[#1a2433] rounded-lg border border-[#253347] p-6 mb-6">
				<div className="flex flex-col sm:flex-row gap-4 mb-6">
					<div className="flex-1 relative">
						<Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
						<Input
							type="text"
							placeholder="Search posts..."
							value={search}
							onChange={(e) => setSearch(e.target.value)}
							className="pl-10 bg-[#0a0f1a] border-[#253347] text-white"
						/>
					</div>

					<Select value={postType} onValueChange={setPostType}>
						<SelectTrigger className="w-[180px] bg-[#0a0f1a] border-[#253347] text-white">
							<SelectValue placeholder="Post Type" />
						</SelectTrigger>
						<SelectContent className="bg-[#1a2433] border-[#253347]">
							<SelectItem value="all">All Types</SelectItem>
							<SelectItem value="text">Text</SelectItem>
							<SelectItem value="image">Image</SelectItem>
							<SelectItem value="quiz">Quiz</SelectItem>
						</SelectContent>
					</Select>
				</div>

				<Tabs value={activeTab} onValueChange={setActiveTab}>
					<TabsList className="bg-[#0a0f1a] border-[#253347]">
						<TabsTrigger
							value="all"
							className="data-[state=active]:bg-[#64a7ff] data-[state=active]:text-white text-[#8b9bab]"
						>
							All Posts
						</TabsTrigger>
						<TabsTrigger
							value="pending"
							className="data-[state=active]:bg-[#64a7ff] data-[state=active]:text-white text-[#8b9bab]"
						>
							<Clock className="w-4 h-4 mr-2" />
							Pending
						</TabsTrigger>
						<TabsTrigger
							value="flagged"
							className="data-[state=active]:bg-[#64a7ff] data-[state=active]:text-white text-[#8b9bab]"
						>
							<Flag className="w-4 h-4 mr-2" />
							Flagged
						</TabsTrigger>
						<TabsTrigger
							value="approved"
							className="data-[state=active]:bg-[#64a7ff] data-[state=active]:text-white text-[#8b9bab]"
						>
							<CheckCircle2 className="w-4 h-4 mr-2" />
							Approved
						</TabsTrigger>
					</TabsList>

					<TabsContent value={activeTab} className="mt-6">
						<PostsList
							posts={postsData?.posts || []}
							isLoading={isLoading}
							onModerate={(postId, status) =>
								moderateMutation.mutate({ postId, status })
							}
							onDelete={(postId) => deleteMutation.mutate(postId)}
						/>

						{postsData && postsData.total > 10 && (
							<div className="flex justify-center gap-2 mt-6">
								<Button
									variant="outline"
									onClick={() => setPage((p) => Math.max(1, p - 1))}
									disabled={page === 1}
									className="bg-[#0a0f1a] border-[#253347] text-white"
								>
									Previous
								</Button>
								<span className="flex items-center px-4 text-white">
									Page {page} of {Math.ceil(postsData.total / 10)}
								</span>
								<Button
									variant="outline"
									onClick={() => setPage((p) => p + 1)}
									disabled={page >= Math.ceil(postsData.total / 10)}
									className="bg-[#0a0f1a] border-[#253347] text-white"
								>
									Next
								</Button>
							</div>
						)}
					</TabsContent>
				</Tabs>
			</div>
		</div>
	);
}
