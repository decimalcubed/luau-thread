--!strict

local thread = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local runContextIsClient = game:GetService("RunService"):IsClient()
local processorToUse = if runContextIsClient then script.Processor_Client else script.Processor_Server
local processorParent = if runContextIsClient then game:GetService("Players").LocalPlayer.PlayerScripts else game:GetService("ServerScriptService")

-- Get thread finished signal (Or create it if it already exists, which could be the case if it was placed there in the editor or if the server made it)
local threadFinishedSignal = ReplicatedStorage:FindFirstChild("ThreadFinished") :: BindableEvent?
if not threadFinishedSignal then
	
	threadFinishedSignal = Instance.new("BindableEvent")
	assert(threadFinishedSignal) --Typechecker wack
	
	threadFinishedSignal.Name = "ThreadFinished"
	threadFinishedSignal.Parent = ReplicatedStorage
end
assert(threadFinishedSignal)

-- Thread tracking
local highestThreadId = 0
local activeThreads: {{thread}} = {}

-- Actor tracking
local actorCache: {Actor} = {}
local function BuildActor(): Actor
	
	debug.profilebegin("thread_BuildActor")
	
	--Build processor and actor
	local actor = Instance.new("Actor")
	actor.Name = "ThreadActor"
	actor.Parent = processorParent

	local processor = processorToUse:Clone()
	processor.Parent = actor

	--Enable processor
	processor.Enabled = true
	
	debug.profileend()

	return actor
end

--[[
	Public
]]

function thread.spawn(execute_module: ModuleScript, ...): number
	
	debug.profilebegin("thread_spawn")

	highestThreadId += 1

	--Get the last available actor or a new one
	local actor = table.remove(actorCache) or BuildActor()

	--Mark the current ID as active and start the thread
	activeThreads[highestThreadId] = {};

	actor:SendMessage("RunThread", highestThreadId, execute_module, ...)
	
	debug.profileend()
	
	return highestThreadId
end

function thread.join(thread_id: number | { number })

	if type(thread_id) == "table" then

		for _, thread_id in thread_id do

			--Continue if the given thread has already finished
			local active_thread = activeThreads[thread_id]
			if not active_thread then

				continue
			end

			--Stop current thread and add to active coroutine tracker
			table.insert(active_thread, coroutine.running())
			coroutine.yield()
		end
	else

		--Return instantly if the given thread has already finished
		local active_thread = activeThreads[thread_id]
		if not active_thread then

			return
		end

		--Stop current thread and add to active coroutine tracker
		table.insert(active_thread, coroutine.running())
		coroutine.yield()
	end
end

-- Connect to the thread finished signal to respawn join coroutines
threadFinishedSignal.Event:Connect(function(id: number, actor: Actor)
	
	debug.profilebegin("thread_internal_ResumeYieldedThreads")
	
	local active_thread = activeThreads[id]
	for _, v in active_thread do

		task.spawn(v)
	end

	--Disconnect and clean up
	activeThreads[id] = nil

	--Add the actor back to the actor cache
	table.insert(actorCache, actor)
	debug.profileend()
end)

return table.freeze(thread)
