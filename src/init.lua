--!strict
--!native
--!optimize 2

local thread = {}
local runContextIsClient = game:GetService("RunService"):IsClient()
local processorToUse = if runContextIsClient then script.Processor_Client else script.Processor_Server
local processorParent = script

-- Get thread finished signal
local threadFinishedSignal = script.ThreadFinished

-- Thread tracking
local highestThreadId = 0
local yieldingThreads: {{thread}} = {}
local signalProcessors: {[BindableEvent]: Script} = {}

-- Actor tracking
local signalCache: {[Script]: {BindableEvent}} = {}
local function BuildVM(processor: Script): BindableEvent
	
	-- Build processor and actor
	local actor = Instance.new("Actor")
	actor.Name = "ThreadActor"
	actor.Parent = processorParent
	
	local processor = processor:Clone()
	processor.Parent = actor
	
	-- Create event
	local communication_signal = Instance.new("BindableEvent")
	communication_signal.Name = "ThreadCommunicationSignal"
	communication_signal.Parent = actor

	--Enable processor
	processor.Enabled = true
	
	signalProcessors[communication_signal] = processor
	return communication_signal :: any
end

--[[
	Public
]]

function thread.spawn(execute_module: ModuleScript, ...): number

	return thread.spawn_custom(processorToUse, execute_module, ...)
end

function thread.spawn_custom(processor: Script, execute_module: ModuleScript, ...): number

	highestThreadId += 1
	
	-- Ensure there is a signal cache for the given processor
	if not signalCache[processor] then
		
		signalCache[processor] = {}
	end

	-- Get the last available signal or build new one
	local signal = table.remove(signalCache[processor]) or BuildVM(processor)

	-- Mark the current ID as active and start the thread
	yieldingThreads[highestThreadId] = {}; --TODO this can be made a buffer and yielding threads can be tracked using an id hashmap
	signal:Fire(highestThreadId, execute_module, ...)

	return highestThreadId
end

function thread.join(thread_id: number | { number })

	if type(thread_id) == "table" then

		for _, thread_id in thread_id do

			-- Continue if the given thread has already finished
			local active_thread = yieldingThreads[thread_id]
			if not active_thread then

				continue
			end

			-- Stop current thread and add to active coroutine tracker
			table.insert(active_thread, coroutine.running())
			coroutine.yield()
		end
	else

		-- Return instantly if the given thread has already finished
		local active_thread = yieldingThreads[thread_id]
		if not active_thread then

			return
		end

		-- Stop current thread and add to active coroutine tracker
		table.insert(active_thread, coroutine.running())
		coroutine.yield()
	end
end

-- Connect to the thread finished signal to respawn join coroutines
threadFinishedSignal.Event:Connect(function(id: number, signal: BindableEvent)
	
	local yielding_threads = yieldingThreads[id]
	for _, v in yielding_threads do
		
		coroutine.resume(v)
	end

	-- Disconnect and clean up
	yieldingThreads[id] = nil

	-- Add the signal back to the signal cache
	table.insert(signalCache[signalProcessors[signal]], signal)
end)

return table.freeze(thread)
