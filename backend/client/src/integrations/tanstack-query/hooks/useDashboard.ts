import { useQuery } from "@tanstack/react-query";
import { getDashboardData } from "@/lib/dashboard-api";

export function useDashboard() {
	return useQuery({
		queryKey: ["dashboard"],
		queryFn: getDashboardData,
		staleTime: 1000 * 60 * 5,
	});
}
