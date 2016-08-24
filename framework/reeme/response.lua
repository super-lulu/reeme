local writeMembers = {
	status = function(self, value)
		ngx.status = value
	end,
}

local ResponseBase = {
	__index = {
		headers = require("reeme.response.headers")(),
	}
}

local Response = {
	__index = {
		begin = function(self)
			local body = rawget(self, "body")
			if #body > 0 then
				return
			end
			
			rawset(self, "begined", true)
		end,
		
		write = function(self, ...)
			local body = rawget(self, "body")
			local begined = rawget(self, "begined")
			local values = { ... }
			for i = 1, #values do
				local value = values[i]
				if begined then
					body[#body + 1] = tostring(value)
				else
					ngx.say(value)
				end
			end
		end,
		
		clear = function(self)
			rawset(self, "body", { })
		end,
		
		finish = function(self)
			local body = rawget(self, "body")
			ngx.print(body)
			
			rawset(self, "begined", false)
			rawset(self, "body", { })
		end,
		
		view = function(self, tpl, env, method)
			local t = require("reeme.response.view")(rawget(self, "R"), tpl)
			return t:render(env or {}, method)
		end,
		outputView = function(self, tpl, env)
			local t = require("reeme.response.view")(rawget(self, "R"), tpl)
			if env then
				local v, t = view:render(env)
				if t then
					ngx.say(t)
				end
			end
		end
	},
	__newindex = function(self, key, value)
		local f = writeMembers[key]
		if f then
			f(self, value)
		end
	end,
}
setmetatable(Response.__index, ResponseBase)

return function(reeme)
	local response = { R = reeme, body = { } }
	
	return setmetatable(response, Response)
end