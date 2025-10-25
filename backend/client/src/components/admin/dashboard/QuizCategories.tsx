interface Category {
	name: string;
	percentage: number;
	count: number;
	color: string;
}

interface QuizCategoriesProps {
	categories: Category[];
}

export function QuizCategories({ categories }: QuizCategoriesProps) {
	let currentAngle = -90;
	const paths = categories.map((cat) => {
		const angle = (cat.percentage / 100) * 360;
		const startAngle = currentAngle;
		const endAngle = currentAngle + angle;
		currentAngle = endAngle;

		const startX = 128 + 90 * Math.cos((startAngle * Math.PI) / 180);
		const startY = 128 + 90 * Math.sin((startAngle * Math.PI) / 180);
		const endX = 128 + 90 * Math.cos((endAngle * Math.PI) / 180);
		const endY = 128 + 90 * Math.sin((endAngle * Math.PI) / 180);

		const largeArcFlag = angle > 180 ? 1 : 0;

		return {
			...cat,
			path: `M 128 128 L ${startX} ${startY} A 90 90 0 ${largeArcFlag} 1 ${endX} ${endY} Z`,
		};
	});

	return (
		<div className="bg-[#1a2433] border border-[#253347] rounded-3xl p-6">
			<h3 className="text-white text-base mb-8">Quiz Categories</h3>

			<div className="space-y-6">
				<div className="flex items-center justify-center">
					<svg
						width="256"
						height="256"
						viewBox="0 0 256 256"
						role="img"
						aria-label="Quiz categories pie chart"
					>
						<title>Quiz Categories Distribution</title>
						<circle cx="128" cy="128" r="60" fill="#0a0f1a" />
						{paths.map((cat) => (
							<path key={cat.name} d={cat.path} fill={cat.color} />
						))}
					</svg>
				</div>

				<div className="space-y-2">
					{categories.map((cat) => (
						<div key={cat.name} className="flex items-center justify-between">
							<div className="flex items-center gap-2">
								<div
									className="size-3 rounded-full"
									style={{ backgroundColor: cat.color }}
								/>
								<span className="text-white text-sm">{cat.name}</span>
							</div>
							<div className="flex items-center gap-2">
								<span className="text-[#8b9bab] text-sm">
									{cat.percentage}%
								</span>
								<span className="text-[#8b9bab] text-xs">({cat.count})</span>
							</div>
						</div>
					))}
				</div>
			</div>
		</div>
	);
}
