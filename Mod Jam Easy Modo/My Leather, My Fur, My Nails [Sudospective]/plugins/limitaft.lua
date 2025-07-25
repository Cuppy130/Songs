return Def.Actor {
	OnCommand = xero(function(self)

		---------------------
		----Documentation----
		---------------------
	
		--[[
	
			Globals:
				-- Takes in an AFT and converts it into a LimitAft Object
				LimitAft(AFT) --> LimitAft
	
	
			LimitAft Methods:
				-- Toggles the auto updating of the AFT's texture
				AutoUpdate(boolean) --> Void
	
				-- Returns the current state of `AutoUpadate`
				GetAutoUpdate() --> boolean
	
				-- Sets the `AutoUpdate` rate of the AFT's texture, minimum value of 1 FPS
				SetFPS(float) --> Void
	
				-- Returns the current FPS of the AFT
				GetFPS() --> float
	
				-- Forces the AFT to update its texture
				update() --> Void
	
		--]]
	
		-------------------------
		----Plugin User Guide----
		-------------------------
	
		--[[
	
			The `LimitAft` table is the constructor for adding LimitAFT methods to a pre-existing AFT.
			To use it simply call `LimitAft` as a function with the AFT as input.
	
			```
				-- This is all you need to make `MyAft` limited
				LimitAft(MyAft)
			```
	
			`MyAft` is now an AFT with limited update rate,
			by default it will auto update at 60 fps but this can be changed via the `SetFPS` method.
			The `SetFPS` method and other custom methods can be called just like other standard actor methods.
	
			```
				-- This will set `MyAft` to only update 30 times per second
				MyAft:SetFPS(30)
			```
	
			That is all you need to know to use the basic functionality of this plugin.
	
			This plugin's other main feature is the ability to manually update the AFT using a method call.
			Typically you'll want to turn auto updating off via the `AutoUpdate` method,
			then you can manually tell it to update whenever you want using the `update` method.
	
			```
				-- This function disables auto updating on `MyAft` at beat 0
				func{0,function()
					MyAft:AutoUpdate(false)
				}
	
				-- This will manually update `MyAft` on beats 1, 2, 3, and 4
				for i = 1,4 do
					func{i,function()
						MyAft:update()
					end}
				end
	
				-- This function re-enables auto updating on `MyAft` at beat 5
				func{5,function()
					MyAft:AutoUpdate(true)
				end}
			```
	
			Note: if the AFT is hidden it will never update it's texture no matter what.
	
			There are also two debug methods to aid with debugging code,`GetFPS` and `GetAutoUpdate`,
			these methods return the current FPS of the ActorFrameTexture and weither AutoUpdate is enabled or not.
	
			Finally, here is a complete example of how one might use everything in this plugin.
	
			```
				-- Limit `MyAft`
				LimitAft(MyAft)
							  
				-- Do the default sprite setup on `MySprite`
				sprite(MySprite)
	
				-- Tell the sprite which AFT to get its texture from
				MySprite:SetTexture(MyAft:GetTexture())
	
				-- Set FPS to 30
				MyAft:SetFPS(30)
	
				-- Disable auto updating on beat 12
				func{12,function()
					MyAft:AutoUpdate(false)
				end}
	
				-- Manually update the AFT from beats 12 to 24 (inclusive) every 0.5 beats
				for i = 12,24,0.5 do
					func{i,function()
						MyAft:update()
					end}
				end
	
				-- Re-enable auto updating on beat 24
				func{24,function()
					MyAft:AutoUpate(true)
				end}
			```
	
		--]]
	
		-----------------
		----Main Code----
		-----------------
	
		----[[Variable Definitions]]----
	
		-- Main Namespace
		LimitAft = {}
	
		-- List of all limited AFTs
		local aftlist = {}
	
		-- Predefined metatable for LimitAft objects
		local mt = {
			-- Function to allow the use of custom and inbuilt functions on the created object
			__index = function(self,k)
				if LimitAft[k] then
					return LimitAft[k]
				elseif self._actor[k] then
					return function(self,...)
						-- Error handling so that errors point to the correct file and line number
						local output = {pcall(self._actor[k],self._actor,unpack(arg))}
						local ok = table.remove(output,1)
	
						if ok then -- If the function ran sucessfully return the results if any
							return unpack(output)
						else -- If the function failed cause a crash with the error message returned
							error(string.gsub(output[1],'?',k),2)
						end
					end
				end
			end
		}
	
		-- [[Object Methods]] --
	
		function LimitAft:hidden(bool) -- Replaces default hidden
			if type(bool) == 'number' then
				 self._hide = math.abs(bool) >= 1
			else
				error('calling `hidden\' on bad self (number expected, got '..type(bool)..')',2)
			end
		end
	
		function LimitAft:visible(bool) -- Replaces default visible
			if type(bool) == 'number' then
				self._hide = math.abs(bool) < 1
			else
				error('calling `visible\' on bad self (number expected, got '..type(bool)..')',2)
			end
		end
	
		function LimitAft:AutoUpdate(bool) -- Toggles the auto updating of the AFT's texture
			if type(bool) == 'boolean' then
				self._autoupdate = bool
			else
				error('calling `AutoUpdate\' on bad self (boolean expected, got '..type(bool)..')',2)
			end
		end
	
		function LimitAft:SetFPS(fps) -- Sets the `AutoUpdate` rate of the AFT's texture, minimum value of 1 FPS
			if type(fps) == 'number' then
				self._fps = math.max(1,fps)
			else
				error('calling `SetFPS\' on bad self (number expected, got '..type(fps)..')',2)
			end
		end
	
		function LimitAft:GetHidden() -- Replaces default GetHidden
			return self._hide
		end
	
		function LimitAft:GetFPS() -- Returns the current FPS of the AFT
			return self._fps
		end
	
		function LimitAft:GetAutoUpdate() -- Returns the current state of `AutoUpadate`
			return self._autoupdate
		end
	
		function LimitAft:update() -- Forces the AFT to update its texture
			self._framewait = 2
			self._frameuptime = 0
			self._framedelay = 1/self._fps
	
			if not self._hide then
				self._actor:hidden(0)
			end
		end
	
		---- [[Object Setup Code]] ----
	
		-- Make namespace a callable function for object creation
		setmetatable(LimitAft,{
			__call = function(_,self)
				-- Check if the input to the function is an ActorFrameTexture userdata
				if type(self) == 'userdata' and string.find(tostring(self),'ActorFrameTexture') then
					-- Create object
					local obj = setmetatable({},mt)
	
					-- Define instanced variables
					obj._actor = self
					obj._fps = 60
					obj._hide = obj._actor:GetHidden()
					obj._autoupdate = true
	
					obj._framedelay = 1/60
					obj._frameuptime = 0
					obj._framewait = 1
	
					-- Setup AFT using inbuilt `aft` function
					aft(obj)
	
					-- Replace current global with the new object
					local name = obj:GetName()
					if name and name ~= '' then
						xero(assert(loadstring('return function(obj)'..name..'=obj end')))()(obj)
					end
	
					-- Place object to the list of AFTs to limit
					table.insert(aftlist,obj)
					return obj
				else
					error('bad argument #1 to `LimitAft\' (ActorFrameTexture expected, got '..type(self)..')',2)
				end
			end
		})
	
		-- Add the update loop that will update the object instances
		self:addcommand('update',function()
			local dt = self:GetEffectDelta() -- deltatime
	
			-- For all LimitAfts created update their textures when needed
			for _,aft in ipairs(aftlist) do
				aft._frameuptime = aft._frameuptime + dt
				if aft._frameuptime >= aft._framedelay then -- Update when the current frame is expired
					aft._frameuptime = aft._frameuptime % aft._framedelay
					aft._framedelay = 1/aft._fps
					if not aft._hide and aft._autoupdate then
						aft._framewait = 1
						aft._actor:hidden(0)
					end
				elseif aft._framewait > 0 then -- Stop Updating the frame once it's been updated
					aft._framewait = aft._framewait - 1
					if aft._framewait == 0 then
						aft._actor:hidden(1)
					end
				end
			end
		end)
	
		-- Set the newly added command to be run every frame
		self:luaeffect('update')
	end)
}
