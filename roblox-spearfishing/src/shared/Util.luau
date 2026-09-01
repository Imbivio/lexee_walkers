--[[
	Util — small shared helpers.
]]

local Util = {}

-- 12345 -> "12,345"
function Util.Comma(n: number): string
	local s = tostring(math.floor(n + 0.5))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	formatted = formatted:gsub("^,", "")
	return formatted
end

function Util.RoundKg(kg: number): number
	if kg >= 10 then
		return math.floor(kg * 10 + 0.5) / 10
	end
	return math.floor(kg * 100 + 0.5) / 100
end

function Util.FormatKg(kg: number): string
	return tostring(Util.RoundKg(kg)) .. " kg"
end

function Util.FormatCm(cm: number): string
	return tostring(math.floor(cm + 0.5)) .. " cm"
end

function Util.FormatTime(seconds: number): string
	local m = math.floor(seconds / 60)
	local s = math.floor(seconds % 60)
	if m > 0 then
		return string.format("%d:%02d", m, s)
	end
	return tostring(s) .. "s"
end

-- Weighted random pick. entries = { { weight = n, ... }, ... }
function Util.WeightedPick(entries: { any }, rng: Random): any?
	local total = 0
	for _, entry in ipairs(entries) do
		total += entry.weight
	end
	if total <= 0 then
		return nil
	end
	local roll = rng:NextNumber() * total
	for _, entry in ipairs(entries) do
		roll -= entry.weight
		if roll <= 0 then
			return entry
		end
	end
	return entries[#entries]
end

-- Simple signal implementation (server-side event bus & client UI events)
export type Signal = {
	Connect: (self: Signal, fn: (...any) -> ()) -> { Disconnect: (any) -> () },
	Fire: (self: Signal, ...any) -> (),
}

function Util.CreateSignal(): Signal
	local signal = {}
	local handlers: { [number]: (...any) -> () } = {}
	local nextId = 0

	function signal:Connect(fn)
		nextId += 1
		local id = nextId
		handlers[id] = fn
		return {
			Disconnect = function()
				handlers[id] = nil
			end,
		}
	end

	function signal:Fire(...)
		for _, fn in pairs(handlers) do
			task.spawn(fn, ...)
		end
	end

	return signal :: any
end

return Util
