import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { FileUp, FolderPlus, Layers, ListChecks, Sparkles } from "lucide-react";
import { useState } from "react";
import { CollectionsTable } from "@/components/admin/quiz-manager/CollectionsTable";
import { CreateCollectionDialog } from "@/components/admin/quiz-manager/CreateCollectionDialog";
import { DeleteCollectionDialog } from "@/components/admin/quiz-manager/DeleteCollectionDialog";
import { DeleteQuizDialog } from "@/components/admin/quiz-manager/DeleteQuizDialog";
import { EditCollectionDialog } from "@/components/admin/quiz-manager/EditCollectionDialog";
import { QuizTable } from "@/components/admin/quiz-manager/QuizTable";
import { QuizTableToolbar } from "@/components/admin/quiz-manager/QuizTableToolbar";
import { ViewCollectionQuizzesDialog } from "@/components/admin/quiz-manager/ViewCollectionQuizzesDialog";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useAuth } from "@/contexts/AuthContext";

export const Route = createFileRoute("/admin/quiz-manager")({
	component: QuizManagerPage,
});

interface Quiz {
	id: string;
	title: string;
	description: string | null;
	category: string | null;
	questionCount: number;
	playCount: number;
	updatedAt: string;
	status: "published" | "draft";
	collection: { id: string; title: string } | null;
	user: {
		id: string;
		fullName: string;
		username: string | null;
		profilePictureUrl: string | null;
	} | null;
}

interface QuizzesResponse {
	quizzes: Quiz[];
	total: number;
	page: number;
	limit: number;
}

interface Collection {
	id: string;
	title: string;
	description: string | null;
	imageUrl: string | null;
	quizCount: number;
	isPublic: boolean;
	updatedAt: string;
	user: {
		id: string;
		fullName: string;
		username: string | null;
		profilePictureUrl: string | null;
	} | null;
}

interface CollectionsResponse {
	collections: Collection[];
	total: number;
	page: number;
	limit: number;
}

async function fetchAdminQuizzes(
	token: string,
	params: {
		search?: string;
		category?: string;
		status?: string;
		page?: number;
		limit?: number;
	},
): Promise<QuizzesResponse> {
	const searchParams = new URLSearchParams();
	if (params.search) searchParams.append("search", params.search);
	if (params.category && params.category !== "all")
		searchParams.append("category", params.category);
	if (params.status && params.status !== "all")
		searchParams.append("status", params.status);
	if (params.page) searchParams.append("page", params.page.toString());
	if (params.limit) searchParams.append("limit", params.limit.toString());

	const response = await fetch(
		`http://localhost:8000/api/admin/quizzes?${searchParams}`,
		{
			headers: {
				Authorization: `Bearer ${token}`,
			},
		},
	);

	if (!response.ok) {
		throw new Error("Failed to fetch quizzes");
	}

	return response.json();
}

async function deleteQuiz(token: string, quizId: string): Promise<void> {
	const response = await fetch(
		`http://localhost:8000/api/admin/quizzes/${quizId}`,
		{
			method: "DELETE",
			headers: {
				Authorization: `Bearer ${token}`,
			},
		},
	);

	if (!response.ok) {
		throw new Error("Failed to delete quiz");
	}
}

async function duplicateQuiz(token: string, quizId: string): Promise<void> {
	const response = await fetch(
		`http://localhost:8000/api/admin/quizzes/${quizId}/duplicate`,
		{
			method: "POST",
			headers: {
				Authorization: `Bearer ${token}`,
			},
		},
	);

	if (!response.ok) {
		throw new Error("Failed to duplicate quiz");
	}
}

async function createCollection(
	token: string,
	data: { title: string; description: string; isPublic: boolean },
): Promise<void> {
	const response = await fetch("http://localhost:8000/api/collection", {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
			Authorization: `Bearer ${token}`,
		},
		body: JSON.stringify(data),
	});

	if (!response.ok) {
		throw new Error("Failed to create collection");
	}
}

async function fetchAdminCollections(
	token: string,
	params: {
		search?: string;
		page?: number;
		limit?: number;
	},
): Promise<CollectionsResponse> {
	const searchParams = new URLSearchParams();
	if (params.search) searchParams.append("search", params.search);
	if (params.page) searchParams.append("page", params.page.toString());
	if (params.limit) searchParams.append("limit", params.limit.toString());

	const response = await fetch(
		`http://localhost:8000/api/admin/collections?${searchParams}`,
		{
			headers: {
				Authorization: `Bearer ${token}`,
			},
		},
	);

	if (!response.ok) {
		throw new Error("Failed to fetch collections");
	}

	return response.json();
}

async function updateCollection(
	token: string,
	collectionId: string,
	data: { title: string; description: string; isPublic: boolean },
): Promise<void> {
	const response = await fetch(
		`http://localhost:8000/api/admin/collections/${collectionId}`,
		{
			method: "PUT",
			headers: {
				"Content-Type": "application/json",
				Authorization: `Bearer ${token}`,
			},
			body: JSON.stringify(data),
		},
	);

	if (!response.ok) {
		throw new Error("Failed to update collection");
	}
}

async function deleteCollection(
	token: string,
	collectionId: string,
): Promise<void> {
	const response = await fetch(
		`http://localhost:8000/api/admin/collections/${collectionId}`,
		{
			method: "DELETE",
			headers: {
				Authorization: `Bearer ${token}`,
			},
		},
	);

	if (!response.ok) {
		throw new Error("Failed to delete collection");
	}
}

async function removeQuizFromCollection(
	token: string,
	collectionId: string,
	quizId: string,
): Promise<void> {
	const response = await fetch(
		`http://localhost:8000/api/collection/${collectionId}/remove-quiz/${quizId}`,
		{
			method: "DELETE",
			headers: {
				Authorization: `Bearer ${token}`,
			},
		},
	);

	if (!response.ok) {
		throw new Error("Failed to remove quiz from collection");
	}
}

function QuizManagerPage() {
	const queryClient = useQueryClient();
	const { session } = useAuth();
	const token = session?.access_token;

	const [searchQuery, setSearchQuery] = useState("");
	const [categoryFilter, setCategoryFilter] = useState("all");
	const [statusFilter, setStatusFilter] = useState("all");
	const [currentPage, setCurrentPage] = useState(1);
	const [collectionsPage, setCollectionsPage] = useState(1);
	const [activeTab, setActiveTab] = useState("all-quizzes");

	const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
	const [quizToDelete, setQuizToDelete] = useState<Quiz | null>(null);

	const [createCollectionOpen, setCreateCollectionOpen] = useState(false);
	const [editCollectionOpen, setEditCollectionOpen] = useState(false);
	const [collectionToEdit, setCollectionToEdit] = useState<Collection | null>(
		null,
	);
	const [deleteCollectionOpen, setDeleteCollectionOpen] = useState(false);
	const [collectionToDelete, setCollectionToDelete] =
		useState<Collection | null>(null);
	const [viewCollectionOpen, setViewCollectionOpen] = useState(false);
	const [collectionToView, setCollectionToView] = useState<string | null>(null);

	const { data, isLoading } = useQuery({
		queryKey: [
			"admin-quizzes",
			{ searchQuery, categoryFilter, statusFilter, currentPage },
		],
		queryFn: () =>
			token
				? fetchAdminQuizzes(token, {
						search: searchQuery,
						category: categoryFilter,
						status: statusFilter,
						page: currentPage,
						limit: 10,
					})
				: Promise.reject("No token"),
		enabled: !!token && activeTab === "all-quizzes",
	});

	const { data: collectionsData, isLoading: collectionsLoading } = useQuery({
		queryKey: ["admin-collections", { searchQuery, collectionsPage }],
		queryFn: () =>
			token
				? fetchAdminCollections(token, {
						search: searchQuery,
						page: collectionsPage,
						limit: 10,
					})
				: Promise.reject("No token"),
		enabled: !!token && activeTab === "collections",
	});

	const deleteMutation = useMutation({
		mutationFn: (quizId: string) =>
			token ? deleteQuiz(token, quizId) : Promise.reject("No token"),
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: ["admin-quizzes"] });
			setDeleteDialogOpen(false);
			setQuizToDelete(null);
		},
	});

	const duplicateMutation = useMutation({
		mutationFn: (quizId: string) =>
			token ? duplicateQuiz(token, quizId) : Promise.reject("No token"),
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: ["admin-quizzes"] });
		},
	});

	const createCollectionMutation = useMutation({
		mutationFn: (data: {
			title: string;
			description: string;
			isPublic: boolean;
		}) => (token ? createCollection(token, data) : Promise.reject("No token")),
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: ["admin-collections"] });
			setCreateCollectionOpen(false);
		},
	});

	const updateCollectionMutation = useMutation({
		mutationFn: ({
			id,
			data,
		}: {
			id: string;
			data: { title: string; description: string; isPublic: boolean };
		}) =>
			token ? updateCollection(token, id, data) : Promise.reject("No token"),
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: ["admin-collections"] });
			queryClient.invalidateQueries({ queryKey: ["collection-quizzes"] });
			setEditCollectionOpen(false);
			setCollectionToEdit(null);
		},
	});

	const deleteCollectionMutation = useMutation({
		mutationFn: (collectionId: string) =>
			token
				? deleteCollection(token, collectionId)
				: Promise.reject("No token"),
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: ["admin-collections"] });
			setDeleteCollectionOpen(false);
			setCollectionToDelete(null);
		},
	});

	const removeQuizMutation = useMutation({
		mutationFn: ({
			collectionId,
			quizId,
		}: {
			collectionId: string;
			quizId: string;
		}) =>
			token
				? removeQuizFromCollection(token, collectionId, quizId)
				: Promise.reject("No token"),
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: ["collection-quizzes"] });
			queryClient.invalidateQueries({ queryKey: ["admin-collections"] });
		},
	});

	const handleEdit = (quizId: string) => {
		console.log("Edit quiz:", quizId);
	};

	const handleCopy = async (quizId: string) => {
		await duplicateMutation.mutateAsync(quizId);
	};

	const handleDelete = (quizId: string) => {
		const quiz = data?.quizzes.find((q) => q.id === quizId);
		if (quiz) {
			setQuizToDelete(quiz);
			setDeleteDialogOpen(true);
		}
	};

	const handleMore = (quizId: string) => {
		console.log("More options for quiz:", quizId);
	};

	const confirmDelete = async () => {
		if (quizToDelete) {
			await deleteMutation.mutateAsync(quizToDelete.id);
		}
	};

	const handleEditCollection = (collectionId: string) => {
		const collection = collectionsData?.collections.find(
			(c) => c.id === collectionId,
		);
		if (collection) {
			setCollectionToEdit(collection);
			setEditCollectionOpen(true);
		}
	};

	const handleViewCollection = (collectionId: string) => {
		setCollectionToView(collectionId);
		setViewCollectionOpen(true);
	};

	const handleDeleteCollection = (collectionId: string) => {
		const collection = collectionsData?.collections.find(
			(c) => c.id === collectionId,
		);
		if (collection) {
			setCollectionToDelete(collection);
			setDeleteCollectionOpen(true);
		}
	};

	const confirmDeleteCollection = async () => {
		if (collectionToDelete) {
			await deleteCollectionMutation.mutateAsync(collectionToDelete.id);
		}
	};

	const handleRemoveQuizFromCollection = async (
		collectionId: string,
		quizId: string,
	) => {
		await removeQuizMutation.mutateAsync({ collectionId, quizId });
	};

	return (
		<div className="flex flex-col gap-6">
			<div className="flex items-center justify-between">
				<div>
					<h1 className="text-white text-[30px] font-bold leading-9">
						Quiz Manager
					</h1>
					<p className="text-[#8b9bab] mt-1 text-[16px] leading-6">
						Create, organize, and manage your quiz content with collections.
					</p>
				</div>

				<div className="flex items-center gap-3">
					<Button
						variant="outline"
						className="h-[36px] bg-[#0a0f1a] border-[#253347] text-white hover:bg-[#253347] text-[14px]"
					>
						<FileUp className="w-4 h-4 mr-2" />
						Import CSV
					</Button>

					<Button className="h-[36px] bg-[#9810fa] hover:bg-[#8710d9] text-white text-[14px]">
						<Sparkles className="w-4 h-4 mr-2" />
						AI Generator
					</Button>

					<Button
						onClick={() => setCreateCollectionOpen(true)}
						className="h-[36px] bg-[#64a7ff] hover:bg-[#5296ee] text-black text-[14px]"
					>
						<FolderPlus className="w-4 h-4 mr-2" />
						New Collection
					</Button>
				</div>
			</div>

			<QuizTableToolbar
				searchQuery={searchQuery}
				onSearchChange={setSearchQuery}
				categoryFilter={categoryFilter}
				onCategoryChange={setCategoryFilter}
				statusFilter={statusFilter}
				onStatusChange={setStatusFilter}
				showFilters={activeTab === "all-quizzes"}
			/>

			<Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
				<TabsList className="bg-[#1a2433] h-[36px] rounded-[14px] p-0">
					<TabsTrigger
						value="collections"
						className="h-[29px] rounded-[14px] data-[state=active]:bg-[rgba(37,51,71,0.3)] data-[state=active]:border data-[state=active]:border-[#253347] text-[14px] text-[#8b9bab] data-[state=active]:text-white"
					>
						<Layers className="w-4 h-4 mr-2" />
						Collections
					</TabsTrigger>
					<TabsTrigger
						value="all-quizzes"
						className="h-[29px] rounded-[14px] data-[state=active]:bg-[rgba(37,51,71,0.3)] data-[state=active]:border data-[state=active]:border-[#253347] text-[14px] text-[#8b9bab] data-[state=active]:text-white"
					>
						<ListChecks className="w-4 h-4 mr-2" />
						All Quizzes
					</TabsTrigger>
				</TabsList>

				<TabsContent value="collections" className="mt-8">
					<CollectionsTable
						collections={collectionsData?.collections || []}
						isLoading={collectionsLoading}
						onEdit={handleEditCollection}
						onView={handleViewCollection}
						onDelete={handleDeleteCollection}
					/>

					{collectionsData && collectionsData.total > collectionsData.limit && (
						<div className="flex items-center justify-center gap-2 mt-6">
							<Button
								variant="outline"
								onClick={() => setCollectionsPage((p) => Math.max(1, p - 1))}
								disabled={collectionsPage === 1}
								className="bg-[#1a2433] border-[#253347] text-white hover:bg-[#253347]"
							>
								Previous
							</Button>
							<span className="text-[#8b9bab] px-4">
								Page {collectionsPage} of{" "}
								{Math.ceil(collectionsData.total / collectionsData.limit)}
							</span>
							<Button
								variant="outline"
								onClick={() => setCollectionsPage((p) => p + 1)}
								disabled={
									collectionsPage >=
									Math.ceil(collectionsData.total / collectionsData.limit)
								}
								className="bg-[#1a2433] border-[#253347] text-white hover:bg-[#253347]"
							>
								Next
							</Button>
						</div>
					)}
				</TabsContent>

				<TabsContent value="all-quizzes" className="mt-8">
					<QuizTable
						quizzes={data?.quizzes || []}
						isLoading={isLoading}
						onEdit={handleEdit}
						onCopy={handleCopy}
						onDelete={handleDelete}
						onMore={handleMore}
					/>

					{data && data.total > data.limit && (
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
				</TabsContent>
			</Tabs>

			<DeleteQuizDialog
				open={deleteDialogOpen}
				onOpenChange={setDeleteDialogOpen}
				onConfirm={confirmDelete}
				isDeleting={deleteMutation.isPending}
				quizTitle={quizToDelete?.title || ""}
			/>

			<CreateCollectionDialog
				open={createCollectionOpen}
				onOpenChange={setCreateCollectionOpen}
				onCreateCollection={createCollectionMutation.mutateAsync}
			/>

			<EditCollectionDialog
				open={editCollectionOpen}
				onOpenChange={setEditCollectionOpen}
				onUpdateCollection={(id, data) =>
					updateCollectionMutation.mutateAsync({ id, data })
				}
				collection={collectionToEdit}
			/>

			<DeleteCollectionDialog
				open={deleteCollectionOpen}
				onOpenChange={setDeleteCollectionOpen}
				onConfirm={confirmDeleteCollection}
				isDeleting={deleteCollectionMutation.isPending}
				collectionTitle={collectionToDelete?.title || ""}
			/>

			<ViewCollectionQuizzesDialog
				open={viewCollectionOpen}
				onOpenChange={setViewCollectionOpen}
				collectionId={collectionToView}
				onRemoveQuiz={handleRemoveQuizFromCollection}
			/>
		</div>
	);
}
