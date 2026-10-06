--!strict
-- Per-player rate limit for RemoteEvent handlers: at most one accepted call per `interval`.
local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type RateLimiter = typeof(setmetatable(
	{} :: { interval: number, last: { [Player]: number } },
	RateLimiter
))

function RateLimiter.new(interval: number): RateLimiter
	return setmetatable(
		{ interval = interval, last = setmetatable({}, { __mode = "k" }) :: any },
		RateLimiter
	)
end

function RateLimiter.allow(self: RateLimiter, player: Player): boolean
	local now = os.clock()
	local last = self.last[player]
	if last and now - last < self.interval then
		return false
	end
	self.last[player] = now
	return true
end

return RateLimiter
