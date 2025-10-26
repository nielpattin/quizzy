import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

interface ContestTabsProps {
	activeTab: string;
	onTabChange: (tab: string) => void;
	children: React.ReactNode;
}

export function ContestTabs({
	activeTab,
	onTabChange,
	children,
}: ContestTabsProps) {
	return (
		<Tabs value={activeTab} onValueChange={onTabChange} className="w-full">
			<TabsList className="bg-[#1a2433] h-[36px] rounded-[14px] p-0">
				<TabsTrigger
					value="active"
					className="h-[29px] rounded-[14px] data-[state=active]:bg-[rgba(37,51,71,0.3)] data-[state=active]:border data-[state=active]:border-[#253347] text-[14px] text-[#8b9bab] data-[state=active]:text-white"
				>
					Active (2)
				</TabsTrigger>
				<TabsTrigger
					value="upcoming"
					className="h-[29px] rounded-[14px] data-[state=active]:bg-[rgba(37,51,71,0.3)] data-[state=active]:border data-[state=active]:border-[#253347] text-[14px] text-[#8b9bab] data-[state=active]:text-white"
				>
					Upcoming (1)
				</TabsTrigger>
				<TabsTrigger
					value="completed"
					className="h-[29px] rounded-[14px] data-[state=active]:bg-[rgba(37,51,71,0.3)] data-[state=active]:border data-[state=active]:border-[#253347] text-[14px] text-[#8b9bab] data-[state=active]:text-white"
				>
					Completed (1)
				</TabsTrigger>
			</TabsList>

			<TabsContent value={activeTab} className="mt-8">
				{children}
			</TabsContent>
		</Tabs>
	);
}
