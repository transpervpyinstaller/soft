local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local ENABLED = false -- true if you want it on by default
local COOLDOWN = 0.25
local lastToggle = 0

local originals = setmetatable({}, { __mode = "k" })

local function setPart(part, on)
	if not part:IsA("BasePart") then return end
	if on then
		if not originals[part] then
			originals[part] = { part.CanCollide, part.CanTouch, part.CanQuery }
		end
		part.CanCollide = true
		part.CanTouch = true
		part.CanQuery = true
	else
		local o = originals[part]
		if o then
			part.CanCollide, part.CanTouch, part.CanQuery = o[1], o[2], o[3]
			originals[part] = nil
		end
	end
end

local function setTool(tool, on)
	for _, d in ipairs(tool:GetDescendants()) do
		setPart(d, on)
	end
end

local function setPlayerTools(on)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character

	if backpack then
		for _, child in ipairs(backpack:GetChildren()) do
			if child:IsA("Tool") then
				setTool(child, on)
			end
		end
	end

	if character then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				setTool(child, on)
			end
		end
	end
end

local function startLoop()
	RunService.Heartbeat:Connect(function()
		if ENABLED then
			setPlayerTools(true)
		end
	end)
end

local function watch(container)
	if not container then return end
	container.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and ENABLED then
			setTool(child, true)
		end
	end)
end

local function onCharacter(character)
	watch(character)
	local backpack = player:WaitForChild("Backpack", 5)
	watch(backpack)
	if ENABLED then
		setPlayerTools(true)
	end
end

local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.C then
		local now = tick()
		if now - lastToggle < COOLDOWN then return end
		lastToggle = now

		ENABLED = not ENABLED
		setPlayerTools(ENABLED)
		print("Tool collision:", ENABLED and "ON" or "OFF")
	end
end)

player.CharacterAdded:Connect(onCharacter)
if player.Character then
	task.spawn(onCharacter, player.Character)
end

startLoop()
print("Press C to toggle.")