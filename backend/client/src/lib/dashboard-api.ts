import { apiGet } from "./api-client";
import { API_BASE_URL } from "./constants";

export interface DashboardStats {
	totalUsers: number;
	activeQuizzes: number;
	totalAttempts: number;
	avgScore: number;
	userGrowth: number;
	quizGrowth: number;
	attemptsGrowth: number;
	scoreGrowth: number;
}

export interface UserGrowthData {
	month: string;
	activeUsers: number;
	newUsers: number;
	quizzesTaken: number;
}

export interface RoleDistribution {
	members: number;
	employees: number;
	total: number;
	growthRate: number;
}

export interface CategoryData {
	name: string;
	percentage: number;
	count: number;
	color: string;
}

export interface TopPerformer {
	rank: number;
	name: string;
	initials: string;
	points: number;
}

export interface Activity {
	id: string;
	user: string;
	action: string;
	target?: string;
	detail?: string;
	time: string;
	color: string;
}

export interface DashboardData {
	stats: DashboardStats;
	userGrowth: UserGrowthData[];
	roleDistribution: RoleDistribution;
	categories: CategoryData[];
	topPerformers: TopPerformer[];
	recentActivities: Activity[];
}

export async function getDashboardData(): Promise<DashboardData> {
	return apiGet<DashboardData>(`${API_BASE_URL}/api/admin/dashboard`);
}
