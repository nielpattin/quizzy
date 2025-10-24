import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/admin/feed-manager")({
	component: FeedManagerPage,
});

function FeedManagerPage() {
	return (
		<div className="flex flex-col gap-6">
			<div>
				<h1 className="text-white text-3xl font-bold">Feed Manager</h1>
				<p className="text-[#8b9bab] mt-1">
					Manage social feed posts, comments, and content moderation.
				</p>
			</div>

			<div className="bg-[#1a2433] border border-[#253347] rounded-3xl p-6">
				<p className="text-[#8b9bab]">
					Feed management interface will be implemented here...
				</p>
			</div>
		</div>
	);
}
