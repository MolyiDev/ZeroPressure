return function(map: { [any]: any }): number
	local count = 0

	for _ in map do
		count += 1
	end

	return count
end
