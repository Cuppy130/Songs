--ease.xml
xero()

-- make a self-filling table based on a generator function
local function cache(func)
	return setmetatable({}, {
		__index = function(self, k)
			self[k] = func(k)
			return self[k]
		end
	})
end

-- make a function cache its results from previous calls
local function fncache(func)
	local cache = {}
	return function(arg)
		cache[arg] = cache[arg] or func(arg)
		return cache[arg]
	end
end

local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos
local pow = math.pow
local exp = math.exp
local pi = math.pi
local abs = math.abs

function flip(fn)
	return function(x) return 1 - fn(x) end
end
flip = fncache(flip)

function bounce(t) return 4 * t * (1 - t) end
function tri(t) return 1 - abs(2 * t - 1) end
function bell(t) return inOutQuint(tri(t)) end
function pop(t) return 3.5 * (1 - t) * (1 - t) * sqrt(t) end
function tap(t) return 3.5 * t * t * sqrt(1 - t) end
function pulse(t) return t < .5 and tap(t * 2) or -pop(t * 2 - 1) end

function spike(t) return exp(-10 * abs(2 * t - 1)) end
function inverse(t) return t * t * (1 - t) * (1 - t) / (0.5 - t) end

popElastic = cache(function(damp)
	return cache(function(count)
		return function(t)
			return (1000 ^ -(t ^ damp) - 0.001) * sin(count * pi * t)
		end
	end)
end)
tapElastic = cache(function(damp)
	return cache(function(count)
		return function(t)
			return (1000 ^ -((1 - t) ^ damp) - 0.001) * sin(count * pi * (1 - t))
		end
	end)
end)
pulseElastic = cache(function(damp)
	return cache(function(count)
		local tap_e = tapElastic[damp][count]
		local pop_e = popElastic[damp][count]
		return function(t)
			return t > .5 and -pop_e(t * 2 - 1) or tap_e(t * 2)
		end
	end)
end)

impulse = cache(function(damp)
	return function(t)
		t = t ^ damp
		return t * (1000 ^ -t - 0.001) * 18.6
	end
end)

function instant() return 1 end
if FUCK_EXE then
	function linear(t) return t end
	function inQuad(t) return t * t end
	function outQuad(t) return -t * (t - 2) end
	function inOutQuad(t)
		t = t * 2
		if t < 1 then
			return 0.5 * t ^ 2
		else
			return 1 - 0.5 * (2 - t) ^ 2
		end
	end
	function inCubic(t) return t * t * t end
	function outCubic(t) return 1 - (1 - t) ^ 3 end
	function inOutCubic(t)
		t = t * 2
		if t < 1 then
			return 0.5 * t ^ 3
		else
			return 1 - 0.5 * (2 - t) ^ 3
		end
	end
	function inQuart(t) return t * t * t * t end
	function outQuart(t) return 1 - (1 - t) ^ 4 end
	function inOutQuart(t)
		t = t * 2
		if t < 1 then
			return 0.5 * t ^ 4
		else
			return 1 - 0.5 * (2 - t) ^ 4
		end
	end
	function inQuint(t) return t ^ 5 end
	function outQuint(t) return 1 - (1 - t) ^ 5 end
	function inOutQuint(t)
		t = t * 2
		if t < 1 then
			return 0.5 * t ^ 5
		else
			return 1 - 0.5 * (2 - t) ^ 5
		end
	end
	function inExpo(t) return 1000 ^ (t - 1) - 0.001 end
	function outExpo(t) return 0.999 - 1000 ^ -t end
	function inOutExpo(t)
		t = t * 2
		if t < 1 then
			return 0.5 * 1000 ^ (t - 1) - 0.0005
		else
			return 0.9995 - 0.5 * 1000 ^ (1 - t)
		end
	end
	function inCirc(t) return 1 - sqrt(1 - t * t) end
	function outCirc(t) return sqrt(-t * t + 2 * t) end
	function inOutCirc(t)
		t = t * 2
		if t < 1 then
			return 0.5 - 0.5 * sqrt(1 - t * t)
		else
			t = t - 2
			return 0.5 + 0.5 * sqrt(1 - t * t)
		end
	end

	function inElastic(t)
		t = t - 1
		return -(pow(2, 10 * t) * sin((t - 0.075) * (2 * pi) / 0.3))
	end
	function outElastic(t)
		return pow(2, -10 * t) * sin((t - 0.075) * (2 * pi) / 0.3) + 1
	end
	function inOutElastic(t)
		t = t * 2 - 1
		if t < 0 then
			return -0.5 * pow(2, 10 * t) * sin((t - 0.1125) * 2 * pi / 0.45)
		else
			return pow(2, -10 * t) * sin((t - 0.1125) * 2 * pi / 0.45) * 0.5 + 1
		end
	end

	function inBack(t) return t * t * (2.70158 * t - 1.70158) end
	function outBack(t)
		t = t - 1
		return (t * t * (2.70158 * t + 1.70158)) + 1
	end
	function inOutBack(t)
		t = t * 2
		if t < 1 then
			return 0.5 * (t * t * (3.5864016 * t - 2.5864016))
		else
			t = t - 2
			return 0.5 * (t * t * (3.5864016 * t + 2.5864016) + 2)
		end
	end

	function outBounce(t)
		if t < 1 / 2.75 then
			return 7.5625 * t * t
		elseif t < 2 / 2.75 then
			t = t - 1.5 / 2.75
			return 7.5625 * t * t + 0.75
		elseif t < 2.5 / 2.75 then
			t = t - 2.25 / 2.75
			return 7.5625 * t * t + 0.9375
		else
			t = t - 2.625 / 2.75
			return 7.5625 * t * t + 0.984375
		end
	end
	function inBounce(t) return 1 - outBounce(1 - t) end
	function inOutBounce(t)
		if t < 0.5 then
			return inBounce(t * 2) * 0.5
		else
			return outBounce(t * 2 - 1) * 0.5 + 0.5
		end
	end

	function inSine(x)
		return 1 - cos(x * (pi * 0.5))
	end

	function outSine(x)
		return sin(x * (pi * 0.5))
	end

	function inOutSine(x)
		return 0.5 - 0.5 * cos(x * pi)
	end
else
	local t = Tweens
	function linear(x) return t.linear(x) end
	function inSine(x) return t.insine(x) end
	function outSine(x) return t.outsine(x) end
	function inOutSine(x) return t.inoutsine(x) end
	function inQuad(x) return t.inquad(x) end
	function outQuad(x) return t.outquad(x) end
	function inOutQuad(x) return t.inoutquad(x) end
	function inCubic(x) return t.incubic(x) end
	function outCubic(x) return t.outcubic(x) end
	function inOutCubic(x) return t.inoutcubic(x) end
	function inQuart(x) return t.inquart(x) end
	function outQuart(x) return t.outquart(x) end
	function inOutQuart(x) return t.inoutquart(x) end
	function inQuint(x) return t.inquint(x) end
	function outQuint(x) return t.outquint(x) end
	function inOutQuint(x) return t.inoutquint(x) end
	function inExpo(x) return t.inexpo(x) end
	function outExpo(x) return t.outexpo(x) end
	function inOutExpo(x) return t.inoutexpo(x) end
	function inCirc(x) return t.incircle(x) end
	function outCirc(x) return t.inoutcircle(x) end
	function inOutCirc(x) t.inoutcircle(x) end
	function inBack(x) return t.inback(x) end
	function outBack(x) return t.outback(x) end
	function inOutBack(x) return t.inoutback(x) end
	function inElastic(x) return t.inelastic(x) end
	function outElastic(x) return t.outelastic(x) end
	function inOutElastic(x) return t.inoutelastic(x) end
	function outBounce(x) return t.outbounce(x) end
	function inBounce(x) return t.inbounce(x) end
	function inOutBounce(x) return t.inoutbounce(x) end

end
return Def.Actor {}
