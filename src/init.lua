--!strict

local thread = {}
local runContextIsClient = game:GetService("RunService"):IsClient()
local processorToUse = if runContextIsClient then script.Processor_Client else script.Processor_Server
local processorParent = if runContextIsClient then game:GetService("Players").LocalPlayer.PlayerScripts else game:GetService("ServerScriptService")

--- << Make instances

local threadFinishedSignal = Instance.new("BindableEvent")
threadFinishedSignal.Name = "ThreadFinished"
threadFinishedSignal.Parent = script

--- << thread tracking

local highestThreadId = 0
local activeThreads: {{thread}} = {}

--- << Actor tracking

local actorCache: {Actor} = {}

--- << Private functions
local function BuildActor(): Actor
	
	--Build processor and actor
	local actor = Instance.new("Actor")
	actor.Name = "ThreadActor"
	actor.Parent = processorParent
	
	local processor = processorToUse:Clone()
	processor.Parent = actor
	
	--Enable processor
	processor.Enabled = true
	
	return actor
end

--- << Public variables

function thread.spawn(execute_module: ModuleScript, ...): number
	
	highestThreadId += 1

	--Get the last available actor or a new one
	local actor = table.remove(actorCache) or BuildActor()

	--Mark the current ID as active and start the thread
	activeThreads[highestThreadId] = {};
	
	actor:SendMessage("RunThread", highestThreadId, execute_module, ...)
	
	return highestThreadId
end

function thread.join(thread_id: number | { number })

	if type(thread_id) == "table" then

		for _, thread_id in thread_id do

			--Return instantly if the given thread has allready finished
			local active_thread = activeThreads[thread_id]
			if not active_thread then

				return
			end

			--Stop current thread and add to active coroutine tracker
			table.insert(active_thread, coroutine.running())
			coroutine.yield()
		end
	else

		--Return instantly if the given thread has allready finished
		local active_thread = activeThreads[thread_id]
		if not active_thread then

			return
		end

		--Stop current thread and add to active coroutine tracker
		table.insert(active_thread, coroutine.running())
		coroutine.yield()
	end
end

--Connect to the thread finished signal to respawn join coroutines
threadFinishedSignal.Event:Connect(function(id: number, actor: Actor)

	local active_thread = activeThreads[id]
	for _, v in active_thread do

		task.spawn(v)
	end

	--Disconnect and clean up
	activeThreads[id] = nil

	--Add the actor back to the actor cache
	table.insert(actorCache, actor)
end)

return table.freeze(thread)
