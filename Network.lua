local module = {}
module.__index = {}

local Framework
local RunService = game:GetService("RunService")

function module:Start(Module)
	Framework = Module
end

local function find_instance(Type, Name, Parent)
	local Items = Parent:GetChildren()
	local Found

	for i,v in pairs(Items) do
		if v:IsA(Type) and v.Name == Name then
			Found = v
			break
		end
	end

	return Found
end

local function find_or_create(Type, Name, Parent)
	local Found = find_instance(Type, Name, Parent)
	
	if not Framework.IsServer and not Found then
		repeat 
			Found = find_instance(Type, Name, Parent) 
			warn(Name.." has not been initially found, attempting again.")
			wait(.1) 
		until Found
	end

	if not Found and Framework.IsServer then
		Found = Instance.new(Type)
		Found.Name = Name
		Found.Parent = Parent
	end

	return Found
end

module.new = function(Name, Parent)
	local self = setmetatable({}, module)
	local Remotes = find_or_create("Folder", "Remotes", Parent or Framework.Services.ReplicatedStorage)

	self.RemoteEvent = find_or_create("RemoteEvent", Name.."_Event", Remotes)
	self.RemoteFunction = find_or_create("RemoteFunction", Name.."_Function", Remotes)
	self.BindableEvent = find_or_create("BindableEvent", Name.."_BEvent", Remotes)
	self.BindableFunction = find_or_create("BindableFunction", Name.."_BFunction", Remotes)
	
	local EventCallbacks = {}
	local FunctionCallbacks = {}
	local BEventCallbacks = {}
	local BFunctionCallbacks = {}

	local PlaceFire = Framework.IsServer and "Client" or "Server"
	local PlaceListen = Framework.IsServer and "Server" or "Client"

	function self:Listen(Method, Function)
		if Method:sub(1,1) == "." then
			if Method:sub(2,2) ~= "_" then
				if not self.BEventConnection then
					self.BEventConnection = self.BindableEvent.Event:Connect(function(Name, ...)
						for name,func in pairs(BEventCallbacks) do
							if name == Name then
								func(...)
							end
						end
					end)
				end
				
				BEventCallbacks[Method] = Function
			else
				if not self.BFunction then
					self.BFunction = true
					self.BindableFunction.OnInvoke = function(Name, ...)
						for name,func in pairs(BFunctionCallbacks) do
							if name == Name then
								return func(...)
							end
						end
					end
				end
				BFunctionCallbacks[Method] = Function
			end
		else
			if Method:sub(1,1) ~= "_" then
				if not self.EventConnection then
					self.EventConnection = self.RemoteEvent["On"..PlaceListen.."Event"]:Connect(function(Name, ...)
						local Arguments = {...}
						if typeof(Name) == "Instance" then
							local Plr = Name
							Name = Arguments[1]
							Arguments[1] = Plr
						end
						for name,func in pairs(EventCallbacks) do
							if name == Name then
								func(unpack(Arguments))
							end
						end
					end)
				end

				EventCallbacks[Method] = Function
			else
				if not self.Function then
					self.Function = true
					self.RemoteFunction["On"..PlaceListen.."Invoke"] = function(Name, ...)
						local Arguments = {...}
						if typeof(Name) == "Instance" then
							local Plr = Name
							Name = Arguments[1]
							Arguments[1] = Plr
						end
						
						for name,func in pairs(FunctionCallbacks) do
							if name == Name then
								return func(unpack(Arguments))
							end
						end
					end
				end
				FunctionCallbacks[Method] = Function
			end
		end
	end
	
	function self:Stop(Method)
		FunctionCallbacks[Method] = nil
		EventCallbacks[Method] = nil
		BEventCallbacks[Method] = nil
		BFunctionCallbacks[Method] = nil
	end
	
	function self:Send(Method, ...)
		if Method:sub(1,1) == "." then
			if Method:sub(2,2) ~= "_" then
				self.BindableEvent:Fire(Method, ...)
			else
				return self.BindableFunction:Invoke(Method, ...)
			end
		else
			if Method:sub(1,1) ~= "_" then
				local functionname = "Fire"..PlaceFire
				if PlaceFire == "Client" then
					local Args = {...}
					local Players = Args[1]
					table.remove(Args, 1)
					
					if typeof(Players) ~= "Instance" or not Players:IsA("Player") then
						if typeof(Players) ~= "table" then
							self.RemoteEvent:FireAllClients(Method, unpack(Args))
						else
							for i,v in pairs(Players) do
								self.RemoteEvent:FireClient(v, Method, unpack(Args))
							end
						end
						return
					else
						self.RemoteEvent:FireClient(Players, Method, unpack(Args))
						return
					end
				end
				self.RemoteEvent[functionname](self.RemoteEvent, Method, ...)
			else
				local functionname = "Invoke"..PlaceFire
				if PlaceFire == "Client" then
					local Args = {...}
					local Players = Args[1]
					table.remove(Args, 1)

					if typeof(Players) ~= "Instance" or not Players:IsA("Player") then
						local returnlist = {}
						if typeof(Players) ~= "table" then
							for i,v in pairs(Framework.Services.Players) do
								returnlist[#returnlist+1] = self.RemoteFunction[functionname](self.RemoteFunction, v, Method, unpack(Args))
							end
						else
							for i,v in pairs(Players) do
								returnlist[#returnlist+1] = self.RemoteFunction[functionname](self.RemoteFunction, v, Method, unpack(Args))
							end
						end
						return returnlist
					else
						local res = self.RemoteFunction:InvokeClient(Players, Method, unpack(Args))
						
						return res
					end
				end
				local res = self.RemoteFunction:InvokeServer(Method, ...)
				
				return res
			end
		end
	end
	
	return self
end

return module
