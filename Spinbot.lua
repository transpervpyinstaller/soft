local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local TOGGLE_KEY = Enum.KeyCode.P
local SPIN_SPEED = 1030 --spin speed :)

local spinning = false
local currentAngle = 0
local character, humanoid, rootJoint, hrp
local connection
local usingJoint = false

local function findRootJoint(char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local joint = hrp:FindFirstChild("RootJoint")
	if joint then return joint end

	joint = hrp:FindFirstChild("Root")
	if joint then return joint end

	local lowerTorso = char:FindFirstChild("LowerTorso")
	if lowerTorso then
		joint = lowerTorso:FindFirstChild("Root")
		if joint then return joint end
		joint = lowerTorso:FindFirstChild("RootJoint")
		if joint then return joint end
	end

	for _, v in ipairs(hrp:GetChildren()) do
		if v:IsA("AnimationConstraint") or v:IsA("Motor6D") then
			if v.Name:lower():find("root") then
				return v
			end
		end
	end

	if lowerTorso then
		for _, v in ipairs(lowerTorso:GetChildren()) do
			if v:IsA("AnimationConstraint") or v:IsA("Motor6D") then
				if v.Name:lower():find("root") then
					return v
				end
			end
		end
	end

	return nil
end

local function cleanup()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	spinning = false
	currentAngle = 0
	usingJoint = false

	if rootJoint and rootJoint.Parent and rootJoint:IsA("Motor6D") then
		pcall(function()
			rootJoint.Transform = CFrame.new()
		end)
	end
	if humanoid then
		humanoid.AutoRotate = true
	end
end

local function onCharacterAdded(char)
	cleanup()

	character = char
	humanoid = character:WaitForChild("Humanoid", 8)
	hrp = character:WaitForChild("HumanoidRootPart", 8)
	rootJoint = findRootJoint(character)

	if not humanoid or not hrp then
		warn("Spinbot: Character not ready")
		return
	end

	if rootJoint then
		usingJoint = true
		print("Spinbot: Found joint →", rootJoint:GetFullName(), "(" .. rootJoint.ClassName .. ")")
	else
		usingJoint = false
		print("Spinbot: No root joint found — falling back to HRP.CFrame (this WILL be visible to others)")
	end

	connection = RunService.PreSimulation:Connect(function(dt)
		if not spinning then return end

		if usingJoint and rootJoint and rootJoint.Parent then
			currentAngle = (currentAngle + SPIN_SPEED * dt) % 360
			pcall(function()
				rootJoint.Transform = CFrame.Angles(0, math.rad(currentAngle), 0)
			end)
		elseif hrp and hrp.Parent then
			hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(SPIN_SPEED * dt), 0)
		end
	end)
end

if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode ~= TOGGLE_KEY then return end

	spinning = not spinning

	if humanoid then
		humanoid.AutoRotate = not spinning
	end

	if not spinning then
		currentAngle = 0
		if usingJoint and rootJoint and rootJoint.Parent then
			pcall(function()
				rootJoint.Transform = CFrame.new()
			end)
		end
	end

	print(spinning and "Spinbot ON" or "Spinbot OFF")
end)

print("Press P to toggle")