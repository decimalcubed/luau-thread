--!strict
--!optimize 2

local threadFinishedSignal = game:GetService("ReplicatedStorage"):WaitForChild("ThreadFinished") :: BindableEvent
local threadCommunicationSignal = script.Parent:FindFirstChild("ThreadCommunicationSignal") :: BindableEvent
--This could be done by having it be a value in the main thread module but it would use more memory and be slightly more annoying to type so idc

threadCommunicationSignal.Event:Connect(function(thread_id: number, execute_module: ModuleScript, ...)

	local execute = (require :: any)(execute_module)

	--Execute execute_module
	task.desynchronize()
	execute(...)
	task.synchronize()

	--Resume all threads waiting on this
	threadFinishedSignal:Fire(thread_id, threadCommunicationSignal)
end)
