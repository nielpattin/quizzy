import { Calendar, GitBranch, Plus, Settings } from "lucide-react";
import { Button } from "@/components/ui/button";

export function QuickActions() {
	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-[14px] px-[25px] py-[25px] space-y-6">
			<h3 className="text-white text-[16px] font-normal">Quick Actions</h3>

			<div className="space-y-3">
				<Button className="w-full h-[36px] bg-[#64a7ff] hover:bg-[#5296ee] text-black text-[14px] rounded-[8px]">
					<Plus className="w-4 h-4 mr-2" />
					Quick Match
				</Button>

				<Button
					variant="outline"
					className="w-full h-[36px] bg-[#0a0f1a] border-[#253347] text-white hover:bg-[#253347] text-[14px] rounded-[8px]"
				>
					<GitBranch className="w-4 h-4 mr-2" />
					Tournament Bracket
				</Button>

				<Button
					variant="outline"
					className="w-full h-[36px] bg-[#0a0f1a] border-[#253347] text-white hover:bg-[#253347] text-[14px] rounded-[8px]"
				>
					<Calendar className="w-4 h-4 mr-2" />
					Schedule Contest
				</Button>

				<Button
					variant="outline"
					className="w-full h-[36px] bg-[#0a0f1a] border-[#253347] text-white hover:bg-[#253347] text-[14px] rounded-[8px]"
				>
					<Settings className="w-4 h-4 mr-2" />
					Contest Settings
				</Button>
			</div>
		</div>
	);
}
