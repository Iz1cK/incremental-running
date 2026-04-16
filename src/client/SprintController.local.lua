local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local network = require(shared:WaitForChild("ZapClient"))

local ACTION_NAME = "FootyenSprint"

local function handleSprint(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	network.RequestSprint.Fire()

	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction(ACTION_NAME, handleSprint, false, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.ButtonL3)

script.Destroying:Connect(function()
	ContextActionService:UnbindAction(ACTION_NAME)
end)
