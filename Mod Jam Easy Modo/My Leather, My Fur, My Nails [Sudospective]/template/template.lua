local POptions = {}
local ApplyModifiers
if not FUCK_EXE then
	POptions = {
		GAMESTATE:GetPlayerState(0):GetPlayerOptions('ModsLevel_Song'),
		GAMESTATE:GetPlayerState(1):GetPlayerOptions('ModsLevel_Song'),
	}
	ApplyModifiers = function(str, pn)
		if pn then
			POptions[pn]:FromString(str)
		else
			POptions[1]:FromString(str)
			POptions[2]:FromString(str)
		end
	end
end
--template.xml

xero()

if FUCK_EXE then max_pn = 8 else max_pn = 2 end -- default: `8`
local debug_print_applymodifier_input = false -- default: `false`
local debug_print_mod_targets = false -- default: `false`

function copy(src)
	local dest = {}
	for k, v in pairs(src) do
		dest[k] = v
	end
	return dest
end

function clear(t)
	for k, v in pairs(t) do
		t[k] = nil
	end
	return t
end

function iclear(t)
	for i, v in ipairs(t) do
		t[i] = nil
	end
	return t
end

xero = xero
type = type
print = print
pairs = pairs
ipairs = ipairs
unpack = unpack
tonumber = tonumber
tostring = tostring
math = copy(math)
table = copy(table)
string = copy(string)

dw = DISPLAY:GetDisplayWidth()
dh = DISPLAY:GetDisplayHeight()

scx = SCREEN_CENTER_X
scy = SCREEN_CENTER_Y
sw = SCREEN_WIDTH
sh = SCREEN_HEIGHT
e = 'end'
plr = {1, 2}

function sprite(self)
	if FUCK_EXE then
		self:basezoomx(sw / dw)
		self:basezoomy(-sh / dh)
		self:x(scx)
		self:y(scy)
	else
		self:Center()
	end
end

function aft(self)
	if FUCK_EXE	then
		self:SetWidth(dw)
		self:SetHeight(dh)
		self:EnableFloat(false)
		self:EnableDepthBuffer(false)
		self:EnableAlphaBuffer(false)
		self:EnablePreserveTexture(true)
	else
		self:SetWidth(sw)
		self:SetHeight(sh)
		self:EnableFloat(false)
		self:EnableDepthBuffer(true)
		self:EnableAlphaBuffer(true)
		self:EnablePreserveTexture(false)
	end
	self:Create()
end

function aftrecursive(self)
	self:SetWidth(sw)
	self:SetHeight(sh)
	self:EnableDepthBuffer(true)
	self:EnableAlphaBuffer(false)
	self:EnableFloat(false)
	self:EnablePreserveTexture(true)
	self:Create()
end

function aftsprite(aft, sprite)
	sprite:SetTexture(aft:GetTexture())
end

function aftdiffuse(self, a)
	local mult = 1
	if string.lower(DISPLAY:GetVendor()) == 'nvidia' then mult = 0.9 end
	self:diffusealpha(a * mult)
end

function pivot(self)
	if FUCK_EXE then
		self:x2(scx)
		self:y2(scy)
	else
		if self:GetNumWrapperStates() == 0 then self:AddWrapperState() end
		local wrap = self:GetWrapperState(1)
		wrap:Center()
	end
end

function offset(self)
	if FUCK_EXE then
		self:x2(-scx)
		self:y2(-scy)
	else
		self:Center()
		if self:GetNumWrapperStates() == 0 then self:AddWrapperState() end
		local wrap = self:GetWrapperState(1)
		wrap:x(-scx)
		wrap:y(-scy)
	end
end

function setupJudgeProxy(proxy, target, pn)
	proxy:SetTarget(target)
	if FUCK_EXE then
		proxy:xy(scx * (pn-.5), scy)
		target:hidden(1)
	else
		proxy:x(scx * (pn-.5))
		proxy:y(scy)
		target:visible(false)
	end
	target:sleep(9e9)
end

function screen_error(output, depth, name)
	local depth = 3 + (type(depth) == 'number' and depth or 0)
	local _, err = pcall(error, type(name) == 'string' and (name .. ':' .. output) or output, depth)
	SCREENMAN:SystemMessage(err)
end

local function push(self, obj)
	self.n = self.n + 1
	self[self.n] = obj
end

local default_plr = {1, 2}

function get_plr()
	return rawget(xero, 'plr') or default_plr
end

-- mod aliases, or ease vars
local aliases = {}
local reverse_aliases = {}

-- alias a mod
function alias(self, depth, name)
	local depth = 1 + (type(depth) == 'number' and depth or 0)
	local name = name or 'alias'
	if type(self) ~= 'table' then
		screen_error('curly braces expected', depth, name)
		return alias
	end
	local a, b = self[1], self[2]
	if type(a) ~= 'string' then
		screen_error('unexpected argument 1', depth, name)
		return alias
	end
	if type(b) ~= 'string' then
		screen_error('unexpected argument 2', depth, name)
		return alias
	end
	a, b = string.lower(a), string.lower(b)
	-- TODO make alias logic clearer
	local collection = {a}
	while aliases[b] do
		if reverse_aliases[b] then
			for _, item in ipairs(reverse_aliases[b]) do
				table.insert(collection, item)
			end
			reverse_aliases[b] = nil
		end
		b = aliases[b]
	end
	reverse_aliases[b] = reverse_aliases[b] or {}
	for _, name in ipairs(collection) do
		aliases[name] = b
		table.insert(reverse_aliases[b], name)
	end
	return alias
end

function normalize_mod(name)
	name = string.lower(name)
	return aliases[name] or name
end

-- eases are loaded after the template, so this needs to be declared early
local function instant()
	return 1
end

-- the table of default mod values
local default_mods = setmetatable({}, {
	__index = function(self, i)
		self[i] = 0
		return 0
	end
})
local modtable_mt = {__index = default_mods}

function setdefault(self, depth, name)
	local depth = 1 + (type(depth) == 'number' and depth or 0)
	local name = name or 'setdefault'
	if type(self) ~= 'table' then
		screen_error('curly braces expected', depth, name)
		return setdefault
	end
	for i = 1, #self, 2 do
		if type(self[i]) ~= 'number' then
			screen_error('invalid mod percent', depth, name)
			return setdefault
		end
		if type(self[i + 1]) ~= 'string' then
			screen_error('invalid mod name', depth, name)
			return setdefault
		end
		default_mods[self[i + 1]] = self[i]
		add ({0, 0, instant, 0, self[i + 1]}, depth, name)
	end
end

-- the previously set value of a mod
local prev_mods = {}
for pn = 1, max_pn do
	prev_mods[pn] = setmetatable({}, modtable_mt)
end

-- get the previously set value of a mod
function get(modname, pn)
	return prev_mods[pn or 1][modname]
end

-- the table of eases/add/set
local eases = {n = 0}

function ease(self, depth, name)
	local depth = 1 + (type(depth) == 'number' and depth or 0)
	local name = name or 'ease'
	if type(self) ~= 'table' then
		screen_error('curly braces expected', depth, name)
		return ease
	end
	if type(self[1]) ~= 'number' then
		screen_error('beat missing', depth, name)
		return ease
	end
	if type(self[2]) ~= 'number' then
		screen_error('len / end missing', depth, name)
		return ease
	end
	if type(self[3]) ~= 'function' then
		screen_error('invalid ease function', depth, name)
		return ease
	end
	local i = 4
	while self[i] do
		if type(self[i]) ~= 'number' then
			screen_error('invalid mod percent', depth, name)
			return ease
		end
		if type(self[i + 1]) ~= 'string' then
			screen_error('invalid mod', depth, name)
			return ease
		end
		i = i + 2
	end
	self.n = i - 1
	local result = self[3](1)
	if type(result) ~= 'number' then
		screen_error('invalid ease function', depth, name)
		return ease
	end
	if result < 0.5 then
		self.transient = 1
	end
	if self.mode or self.m then
		self[2] = self[2] - self[1]
	end
	local plr = self.plr or get_plr()
	if type(plr) == 'number' then
		self.plr = plr
		push(eases, self)
	elseif type(plr) == 'table' then
		self.plr = nil
		for _, plr in ipairs(plr) do
			local copy = copy(self)
			copy.plr = plr
			push(eases, copy)
		end
	else
		screen_error('invalid plr', depth, name)
	end
	-- update prev_mods table
	if not self.transient then
		for _, pn in ipairs(type(plr) == 'table' and plr or {plr}) do
			for n = 5, self.n, 2 do
				if self.relative then
					prev_mods[pn][self[n]] = prev_mods[pn][self[n]] + self[n - 1]
				else
					prev_mods[pn][self[n]] = self[n - 1]
				end
			end
		end
	end
	return ease
end

function add(self, depth, name)
	local depth = 1 + (type(depth) == 'number' and depth or 0)
	local name = name or 'add'
	self.relative = true
	ease(self, depth, name)
	return add
end

function set(self, depth, name)
	local depth = 1 + (type(depth) == 'number' and depth or 0)
	local name = name or 'set'
	local a, b, i = 0, instant, 2
	while a do
		a, self[i] = self[i], a
		b, self[i + 1] = self[i + 1], b
		i = i + 2
	end
	ease(self, depth, name)
	return set
end

function reset(self, depth, name)
	local depth = 1 + (type(depth) == 'number' and depth or 0)
	local name = name or 'reset'
	if type(self) ~= 'table' then
		screen_error('curly braces expected', depth, name)
	end
	self[2] = self[2] or 0
	self[3] = self[3] or instant
	self.reset = true
	self.exclude = self.exclude or {}
	for _, v in ipairs(self.exclude) do
		self.exclude[v] = true
	end
	ease(self, depth, name)
end

-- the table of scheduled functions and perframes
local funcs = {n = 0}

function func(self, depth, name)
	local name = name or 'func'
	local depth = 1 + (type(depth) == 'number' and depth or 0)
	if type(self) ~= 'table' then
		screen_error('curly braces expected', depth, name)
		return func
	end

	if self.mode or self.m then
		if type(self[2]) == number then
			self[2] = self[2] - self[1]
		end
		if type(self.persist) == 'number' then
			self.persist = self.persist - self[1]
		end
	end

	local can_use_poptions = false
	local a, b, c, d, e, f = self[1], self[2], self[3], self[4], self[5], self[6]
	-- function ease, type 3
	if type(a) == 'number' and type(b) == 'number' and type(c) == 'function' and type(d) == 'number' and type(e) == 'number' and type(f) == 'function' then
		local eas = c
		a, b, c = a, b, function(beat)
			f(d + (e - d) * eas((beat - a) / b))
		end
	-- function ease, type 2
	elseif type(a) == 'number' and type(b) == 'number' and type(c) == 'function' and type(d) == 'number' and type(e) == 'function' then
		local eas = c
		a, b, c = a, b, function(beat)
			e(d * eas((beat - a) / b))
		end
	-- function ease, type 1
	elseif type(a) == 'number' and type(b) == 'number' and type(c) == 'function' and type(d) == 'function' then
		local eas = c
		a, b, c = a, b, function(beat)
			d(eas((beat - a) / b))
		end
	-- perframe
	elseif type(a) == 'number' and type(b) == 'number' and type(c) == 'function' then
		a, b, c = a, b, c
		can_use_poptions = true
	-- scheduling a message
	elseif type(a) == 'number' and type(b) == 'function' then
		a, b, c = a, nil, b
		local fn = c
		if self.persist ~= nil and self.persist ~= true then
			if self.persist == false then
				self.persist = 0.5
			end
			local len = self.persist
			c = function(beat)
				if beat < a + len then
					fn(beat)
				end
			end
		end
	else
		screen_error('overload resolution failed: check argument types', depth, name)
		return func
	end
	self[1], self[2], self[3], self[4], self[5], self[6] = a, b, c, nil, nil, nil
	if can_use_poptions then
		self.mods = {}
		for pn = 1, max_pn do
			self.mods[pn] = {}
		end
	end
	push(funcs, self)
	if self.defer then
		self.priority = -funcs.n
	else
		self.priority = funcs.n
	end
	-- if it's a function-ease variant then make it persist
	if d then
		local end_beat = a + b
		func {end_beat, function() c(end_beat) end, persist = self.persist, defer = self.defer}
	end
	return func
end

-- auxilliary variables
local auxes = {}

function aux(self, depth, name)
	local depth = 1 + (type(depth) == 'number' and depth or 0)
	local name = name or 'aux'
	if type(self) == 'string' then
		local v = self
		auxes[v] = true
	elseif type(self) == 'table' then
		for i = 1, #self do
			aux(self[i], depth, name)
		end
	else
		screen_error('aux var name must be a string', depth, name)
	end
	return aux
end

-- the table of nodes
local nodes = {n = 0}
local node_start

function node(self, depth, name)
	local depth = 1 + (type(depth) == 'number' and depth or 0)
	local name = name or 'node'
	if type(self) ~= 'table' then
		screen_error('curly braces expected', depth, name)
		return node
	end
	local i = 1
	local inputs = {}
	local reverse_in = {}
	while type(self[i]) == 'string' do
		table.insert(inputs, self[i])
		add({0, 0, instant, 0, self[i]}, depth, name)
		i = i + 1
	end
	if i == 1 then
		screen_error('inputs to node expected', depth, name)
	end
	local fn = self[i]
	if type(fn) ~= 'function' then
		screen_error('node function expected', depth, name)
	end
	i = i + 1
	local out = {}
	while type(self[i]) == 'string' do
		table.insert(out, self[i])
		i = i + 1
	end
	local result = {inputs, out, fn}
	result.priority = self.defer and -nodes.n or nodes.n
	push(nodes, result)
	return node
end

-- used to create your own mods.
-- calls aux and node on the provided arguments
function definemod(self, depth, name)
	local depth = 1 + (type(depth) == 'number' and depth or 0)
	local name = name or 'definemod'
	for i = 1, #self do
		if type(self[i]) ~= 'string' then
			break
		end
		aux(self[i], depth, name)
	end
	node(self, depth, name)
	return definemod
end

local mods = {}
mod_buffer = stringbuilder()

function compile_nodes()
	local terminators = {}
	for _, nd in ipairs(nodes) do
		for _, mod in ipairs(nd[2]) do
			terminators[mod] = true
		end
	end
	for k, _ in pairs(terminators) do
		push(nodes, {{k}, {}, nil, nil, nil, nil, nil, true})
	end
	local start = {}
	local locked = {}
	local last = {}
	for _, nd in ipairs(nodes) do
		-- struct node {
		--     list<string> inputs;
		--     list<string> out;
		--     lua_function fn;
		--     list<struct node> children;
		--     list<list<struct node>> parents; // the inner lists also have a [0] field that is a boolean
		--     lua_function real_fn;
		--     list<map<string, float>> outputs;
		--     bool terminator;
		--     int seen;
		-- }
		local terminator = nd[8]
		if not terminator then
			nd[4] = {} -- children
			nd[7] = {} -- outputs
			for pn = 1, max_pn do
				nd[7][pn] = {}
			end
		end
		nd[5] = {} -- parents
		local inputs = nd[1]
		local out = nd[2]
		local fn = nd[3]
		local parents = nd[5]
		local outputs = nd[7]
		local reverse_in = {}
		for i, v in ipairs(inputs) do
			reverse_in[v] = true
			start[v] = start[v] or {}
			parents[i] = {}
			if not start[v][locked] then
				table.insert(start[v], nd)
			end
			if start[v][locked] then
				parents[i][0] = true
			end
			for _, pre in ipairs(last[v] or {}) do
				table.insert(pre[4], nd)
				table.insert(parents[i], pre[7])
			end
		end
		for i, v in ipairs(out) do
			if reverse_in[v] then
				start[v][locked] = true
				last[v] = {nd}
			elseif not last[v] then
				last[v] = {nd}
			else
				table.insert(last[v], nd)
			end
		end

		local function escapestr(s)
			return '\'' .. string.gsub(s, '[\\\']', '\\%1') .. '\''
		end
		local function list(code, i, sep)
			if i ~= 1 then code(sep) end
		end

		local code = stringbuilder()
		local function emit_inputs()
			for i, mod in ipairs(inputs) do
				list(code, i, ',')
				for j = 1, #parents[i] do
					list(code, j, '+')
					code'parents['(i)']['(j)'][pn]['(escapestr(mod))']'
				end
				if not parents[i][0] then
					list(code, #parents[i] + 1, '+')
					code'mods[pn]['(escapestr(mod))']'
				end
			end
		end
		local function emit_outputs()
			for i, mod in ipairs(out) do
				list(code, i, ',')
				code'outputs[pn]['(escapestr(mod))']'
			end
			return out[1]
		end
		code
		'return function(outputs, parents, mods, fn)\n'
			'return function(pn)\n'
				if terminator then
					code'mods[pn]['(escapestr(inputs[1]))'] = ' emit_inputs() code'\n'
				else
					if emit_outputs() then code' = ' end code 'fn(' emit_inputs() code', pn)\n'
				end
				code
			'end\n'
		'end\n'

		local compiled = assert(loadstring(code:build()))()
		nd[6] = compiled(outputs, parents, mods, fn)
		if not terminator then
			for pn = 1, max_pn do
				nd[6](pn)
			end
		end
	end
	for mod, v in pairs(start) do
		v[locked] = nil
	end
	node_start = start
end

-- replaces aliases with their respective mods
local function resolve_aliases()
	-- ease
	for _, e in ipairs(eases) do
		for i = 5, e.n, 2 do e[i] = normalize_mod(e[i]) end
	end
	-- aux
	local old_auxes = copy(auxes)
	clear(auxes)
	for mod, _ in pairs(old_auxes) do
		auxes[normalize_mod(mod)] = true
	end
	-- node
	for _, node_entry in ipairs(nodes) do
		local input = node_entry[1]
		local output = node_entry[2]
		for i = 1, #input do input[i] = normalize_mod(input[i]) end
		for i = 1, #output do output[i] = normalize_mod(output[i]) end
	end
	-- default_mods
	local old_default_mods = copy(default_mods)
	clear(default_mods)
	for mod, percent in pairs(old_default_mods) do
		default_mods[normalize_mod(mod)] = percent
	end
end

-- takes every actor with a Name= and places it in the xero table
local function scan_named_actors()
	local mt = {}
	function mt.__index(self, k)
		self[k] = setmetatable({}, mt)
		return self[k]
	end
	local actors = setmetatable({}, mt)
	local list = {n = 0}
	local code = stringbuilder()
	local function sweep(actor, skip)
		if actor.GetNumChildren then
			for i = 0, actor:GetNumChildren() - 1 do
				sweep(actor:GetChildAt(i + ((FUCK_EXE and 0) or 1)))
			end
		end
		if skip then
			return
		end
		local name = actor:GetName()
		if name and name ~= '' then
			if loadstring('t.'..name..'=t') then
				push(list, actor)
				code'actors.'(name)' = list['(list.n)']\n'
			else
				SCREENMAN:SystemMessage('invalid actor name: \''..name..'\'')
			end
		end
	end

	code'return function(list, actors)\n'
		sweep(foreground, true)
	code'end'

	local load_actors = xero(assert(loadstring(code:build())))()
	load_actors(list, actors)

	local function clear_metatables(tab)
		setmetatable(tab, nil)
		for _, obj in pairs(tab) do
			if type(obj) == 'table' and getmetatable(obj) == mt then
				clear_metatables(obj)
			end
		end
	end
	clear_metatables(actors)

	for name, actor in pairs(actors) do
		xero[name] = actor
	end

end

function on_command(self)
	scan_named_actors()
	self:queuecommand('BeginUpdate')
end

function begin_update_command(self)

	for _, element in ipairs {
		'Overlay', 'Underlay',
		'ScoreP1', 'ScoreP2',
		'LifeP1', 'LifeP2',
	} do
		local child = SCREENMAN:GetTopScreen():GetChild(element)
		if FUCK_EXE then
			if child then child:hidden(1) end
		else
			if child then child:visible(false) end
		end

	end

	P = {}
	for pn = 1, max_pn do
		local player = SCREENMAN:GetTopScreen():GetChild('PlayerP' .. pn)
		xero['P' .. pn] = player
		P[pn] = player
	end

	foreground:playcommand('Load')

	stable_sort(eases, function(a, b) return a[1] < b[1] end)
	stable_sort(funcs, function(a, b)
		if a[1] == b[1] then
			local x, y = a.priority, b.priority
			return x * x * y < x * y * y
		else
			return a[1] < b[1]
		end
	end)
	stable_sort(nodes, function(a, b)
		local x, y = a.priority, b.priority
		return x * x * y < x * y * y
	end)
	resolve_aliases()
	compile_nodes()

	self:luaeffect('Update')
end

-- make zoom and move nodes NotITG-only - kino
if FUCK_EXE then
	-- zoom
	aux 'zoom'
	node {
		'zoom', 'zoomx', 'zoomy',
		function(zoom, x, y)
			local m = zoom * 0.01
			return m * x, m * y
		end,
		'zoomx', 'zoomy',
		defer = true,
	}

	-- movex
	for _, a in ipairs {'x', 'y', 'z'} do
		aux {'move' .. a}
		node {
			'move' .. a,
			function(a)
				return a, a, a, a, a, a, a, a
			end,
			'move'..a..'0', 'move'..a..'1', 'move'..a..'2', 'move'..a..'3',
			'move'..a..'4', 'move'..a..'5', 'move'..a..'6', 'move'..a..'7',
			defer = true,
		}
	end
end

setdefault {100, 'zoom', 100, 'zoomx', 100, 'zoomy', 100, 'zoomz'}

-- xmod
aux 'xmod' 'cmod'
node {
	'xmod', 'cmod',
	function(xmod, cmod)
		if cmod == 0 then
			mod_buffer(string.format('*-1 %fx', xmod))
		else
			mod_buffer(string.format('*-1 %fx,*-1 c%f', xmod, cmod))
		end
	end,
	defer = true,
}
setdefault {1, 'xmod'}

local targets = {}
for pn = 1, max_pn do
	targets[pn] = setmetatable({}, modtable_mt)
end

local mods_mt = {}
for pn = 1, max_pn do
	mods_mt[pn] = {__index = targets[pn]}
end
-- defined earlier
local mods = mods
for pn = 1, max_pn do
	mods[pn] = setmetatable({}, mods_mt[pn])
end

local poptions = {}
local poptions_mt = {}
local poptions_logging_target
for pn = 1, max_pn do
	local pn = pn
	local mods_pn = mods[pn]
	local mt = {
		__index = function(self, k)
			return mods_pn[normalize_mod(k)]
		end,
		__newindex = function(self, k, v)
			k = normalize_mod(k)
			mods_pn[k] = v
			if v then
				poptions_logging_target[pn][k] = true
			end
		end,
	}
	poptions_mt[pn] = mt
	poptions[pn] = setmetatable({}, mt)
end

local eases_index = 1
local funcs_index = 1

local active_eases = {n = 0}
local active_funcs = perframe_data_structure(function(a, b)
	local x, y = a.priority, b.priority
	return x * x * y < x * y * y
end)

if FUCK_EXE then
	GAMESTATE:ApplyModifiers('clearall,*0 0x,*-1 overhead')
else
	ApplyModifiers('clearall,*0 0x,*-1 overhead')
end
-- default eases

local function apply_modifiers(str, pn)
	if FUCK_EXE then
		GAMESTATE:ApplyModifiers(str, pn)
	else
		ApplyModifiers(str, pn)
	end
end

if debug_print_applymodifier_input then
	local old_apply_modifiers = apply_modifiers
	apply_modifiers = function(str, pn)
		if debug_print_applymodifier_input == true or debug_print_applymodifier_input < beat then
			print('PLAYER ' .. pn .. ': ' .. str)
			if debug_print_mod_targets ~= true then
				apply_modifiers = old_apply_modifiers
			end
		end
		old_apply_modifiers(str, pn)
	end
end

local seen = 1
local active_nodes = {}
local active_terminators = {}
local propagateAll, propagate
function propagateAll(nodes)
	if nodes then
		for _, nd in ipairs(nodes) do
			propagate(nd)
		end
	end
end
function propagate(nd)
	if nd[9] ~= seen then
		nd[9] = seen
		if nd[8] then
			table.insert(active_terminators, nd)
		else
			propagateAll(nd[4])
			table.insert(active_nodes, nd)
		end
	end
end

local oldbeat = 0
function update_command(self)

	local beat = GAMESTATE:GetSongBeat()
	if beat <= oldbeat then return end
	oldbeat = beat

	while eases_index <= eases.n and eases[eases_index][1] < beat do
		local e = eases[eases_index]
		local plr = e.plr
		if e.reset then
			for mod, pecent in pairs(targets[plr]) do
				if not e.exclude[mod] and targets[plr][mod] ~= default_mods[mod] then
					push(e, default_mods[mod])
					push(e, mod)
				end
			end
		end
		e.offset = e.transient and 0 or 1
		if not e.relative then
			for i = 4, e.n, 2 do
				local mod = e[i + 1]
				e[i] = e[i] - targets[plr][mod]
			end
		end
		if not e.transient then
			for i = 4, e.n, 2 do
				local mod = e[i + 1]
				targets[plr][mod] = targets[plr][mod] + e[i]
			end
		end
		push(active_eases, e)
		eases_index = eases_index + 1
	end

	local active_eases_index = 1
	while active_eases_index <= active_eases.n do
		local e = active_eases[active_eases_index]
		local plr = e.plr
		if beat < e[1] + e[2] then
			local e3 = e[3]((beat - e[1]) / e[2]) - e.offset
			for i = 4, e.n, 2 do
				local mod = e[i + 1]
				mods[plr][mod] = mods[plr][mod] + e3 * e[i]
			end
			active_eases_index = active_eases_index + 1
		else
			for i = 4, e.n, 2 do
				local mod = e[i + 1]
				mods[plr][mod] = mods[plr][mod] + 0
			end
			active_eases[active_eases_index] = active_eases[active_eases.n]
			active_eases[active_eases.n] = nil
			active_eases.n = active_eases.n - 1
		end
	end

	while funcs_index <= funcs.n and funcs[funcs_index][1] < beat do
		local e = funcs[funcs_index]
		if not e[2] then
			e[3](beat)
		elseif beat < e[1] + e[2] then
			active_funcs:add(e)
		end
		funcs_index = funcs_index + 1
	end

	while true do
		local e = active_funcs:next()
		if not e then break end
		if beat < e[1] + e[2] then
			poptions_logging_target = e.mods
			e[3](beat, poptions)
		else
			if e.mods then
				for pn = 1, max_pn do
					for mod, _ in pairs(e.mods[pn]) do
						mods[pn][mod] = mods[pn][mod] + 0
					end
				end
			end
			active_funcs:remove()
		end
	end

	for pn = 1, max_pn do
		if P[pn] and (not FUCK_EXE or P[pn]:IsAwake()) then
			mod_buffer = stringbuilder()
			seen = seen + 1
			for k in pairs(mods[pn]) do
				-- identify all nodes to execute this frame
				propagateAll(node_start[k])
			end
			for i = 1, #active_nodes do
				-- run all the nodes
				table.remove(active_nodes)[6](pn)
			end
			for i = 1, #active_terminators do
				-- run all the nodes marked as 'terminator'
				table.remove(active_terminators)[6](pn)
			end
			for mod, percent in pairs(mods[pn]) do
				if not auxes[mod] then
					mod_buffer('*-1 '..percent..' '..mod)
				end
				mods[pn][mod] = nil
			end
			if mod_buffer[1] then
				apply_modifiers(mod_buffer:build(','), pn)
			end
		end
	end

	if debug_print_mod_targets then
		if debug_print_mod_targets == true or debug_print_mod_targets < beat then
			for pn = 1, max_pn do
				if P[pn] and (P[pn]:IsAwake() or not FUCK_EXE) then
					local outputs = {}
					local i = 0
					for k, v in pairs(targets[pn]) do
						if v ~= 0 then
							i = i + 1
							outputs[i] = tostring(k) .. ': ' .. tostring(v)
						end
					end
					print('Player ' .. pn .. ' at beat ' .. beat .. ' --> ' .. table.concat(outputs, ', '))
				end
			end
			debug_print_mod_targets = (debug_print_mod_targets == true)
		end
	end
end
return Def.ActorFrame {
	OnCommand = xero.on_command,
	BeginUpdateCommand = xero.begin_update_command,
	UpdateCommand = xero.update_command,
}
