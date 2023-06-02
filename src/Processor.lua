---!strict

local threadFinishedSignal = script.Parent.Parent:FindFirstChild("ThreadFinished") :: BindableEvent
--This could be done by having it be a value in the main thread module but it would use more memory and be slightly more annoying to type so idc

local selfActor = script:GetActor()
selfActor:BindToMessage("RunThread", function(thread_id: number, execute_module: ModuleScript, ...)
	
	local execute = require(execute_module)

	--Execute execute_module
	task.desynchronize()
	execute(shared_table, ...)
	task.synchronize()

	--Resume all threads waiting on this
	threadFinishedSignal:Fire(thread_id, selfActor)
end)
