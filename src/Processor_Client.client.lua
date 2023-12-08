---!strict

local threadFinishedSignal = game:GetService("ReplicatedStorage"):WaitForChild("ThreadFinished") :: BindableEvent
--This could be done by having it be a value in the main thread module but it would use more memory and be slightly more annoying to type so idc

local selfActor = script:GetActor()
selfActor:BindToMessage("RunThread", function(thread_id: number, execute_module: ModuleScript, ...)
	
	local execute = require(execute_module)

	--Execute execute_module
	task.desynchronize()
	debug.profilebegin("thread_client_processor_execute")
	execute(...)
	debug.profileend()
	task.synchronize()

	--Resume all threads waiting on this
	debug.profilebegin("thread_client_processor_finish")
	threadFinishedSignal:Fire(thread_id, selfActor)
	debug.profileend()
end)
