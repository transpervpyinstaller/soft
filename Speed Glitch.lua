local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local TOGGLE_KEY = Enum.KeyCode.G
local FORWARD_DISTANCE = 8      -- how far in front of the root part the center of mass sits
local DENSITY = 200             -- higher = stronger effect
local REQUIRE_EMOTE = true

local enabled = false

local DEFAULT_ANIMS = {
	IdleAnim = true, WalkAnim = true, RunAnim = true, JumpAnim = true,
	FallAnim = true, ClimbAnim = true, SwimAnim = true, SitAnim = true,
	ToolNoneAnim = true, ToolSlashAnim = true, ToolLungeAnim = true,
	Animation1 = true, Animation2 = true, -- idle variants
}

local function isEmotePlaying(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return false end
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if not DEFAULT_ANIMS[track.Name] and track.IsPlaying then
			return true
		end
	end
	return false
end

local function clearWeight(character)
	local old = character:FindFirstChild("COMWeight")
	if old then old:Destroy() end
end

local function shiftCenterOfMass(character, root)
	clearWeight(character)

	local weight = Instance.new("Part")
	weight.Name = "COMWeight"
	weight.Size = Vector3.new(1, 1, 1)
	weight.Transparency = 1
	weight.CanCollide = false
	weight.CanQuery = false
	weight.CanTouch = false
	weight.CustomPhysicalProperties = PhysicalProperties.new(DENSITY, 0.3, 0, 1, 1)
	weight.CFrame = root.CFrame * CFrame.new(0, 0, -FORWARD_DISTANCE)
	weight.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = weight
	weld.Parent = weight
end

local function evaluate(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then return end

	if enabled and (not REQUIRE_EMOTE or isEmotePlaying(humanoid)) then
		shiftCenterOfMass(character, root)
	else
		clearWeight(character)
	end
end

local function setup(character)
	character:WaitForChild("HumanoidRootPart")
	character:WaitForChild("Humanoid")

	local function onToolChange(child)
		if not child:IsA("Tool") then return end
		if not enabled then return end
		evaluate(character)
	end

	character.ChildAdded:Connect(onToolChange)
	character.ChildRemoved:Connect(onToolChange)
end

player.CharacterAdded:Connect(setup)
if player.Character then
	task.spawn(setup, player.Character)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode ~= TOGGLE_KEY then return end

	enabled = not enabled

	local character = player.Character
	if not character then return end

	if enabled then
		if character:FindFirstChildOfClass("Tool") then
			evaluate(character)
		end
	else
		clearWeight(character)
	end

	print("COM toggle:", enabled and "ON" or "OFF")
end)

print("Speed glitch loaded!! :D  (press G to toggle)")