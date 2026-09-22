--!strict
-- ============================================================================
-- IslandEnvironment.luau
-- Devasa Şantiye Vadisi, Doğal Ada, Otoyol ve Çevre Peyzajı
-- ============================================================================

local Workspace = game:GetService("Workspace")
local PlotDataTypes = require(script.Parent.PlotDataTypes)
local createPart = PlotDataTypes.createPart

local IslandEnvironment = {}

function IslandEnvironment.EnsureEnvironment(): Folder
	local existing = Workspace:FindFirstChild("TycoonEnvironment")
	if existing and existing:IsA("Folder") then
		return existing
	end

	-- Varsayılan küçük Baseplate varsa kaldır (araziyle çakışmayı ve parsel dışı boşluk hissini önle)
	local defaultBaseplate = Workspace:FindFirstChild("Baseplate")
	if defaultBaseplate and defaultBaseplate:IsA("BasePart") then
		defaultBaseplate:Destroy()
	end

	local envFolder = Instance.new("Folder")
	envFolder.Name = "TycoonEnvironment"
	envFolder.Parent = Workspace

	-- 1. Ana Vadi / Ada Çim Zemin (1600 x 800 stud - Tüm şantiyeleri içine alır, boşluğu yok eder)
	createPart(
		envFolder, "MainIslandGround",
		Vector3.new(1600, 6, 800),
		CFrame.new(500, 1, 40),
		Color3.fromRGB(75, 145, 65),
		Enum.Material.Grass,
		true, true
	)

	-- 2. Kıyı Doğal Kaya Falezleri (Arka ve Kenar Sınırlar)
	createPart(
		envFolder, "NorthCliff",
		Vector3.new(1620, 14, 20),
		CFrame.new(500, 5, -360),
		Color3.fromRGB(110, 115, 120),
		Enum.Material.Rock,
		true, true
	)
	createPart(
		envFolder, "SouthBeach",
		Vector3.new(1620, 4, 30),
		CFrame.new(500, 1.5, 435),
		Color3.fromRGB(220, 205, 160),
		Enum.Material.Sand,
		true, true
	)

	-- 3. Ana Asfalt Şantiye Otoyolu (Şantiyelerin önünden boylu boyunca geçer)
	local roadCenterZ = 55
	createPart(
		envFolder, "MainHighway",
		Vector3.new(1500, 0.4, 26),
		CFrame.new(500, 4.2, roadCenterZ),
		Color3.fromRGB(45, 45, 50),
		Enum.Material.Asphalt,
		true, true
	)

	-- 4. Otoyol Beyaz Kenar Çizgileri ve Orta Sarı Kesikli Çizgiler
	createPart(
		envFolder, "RoadCenterLine",
		Vector3.new(1500, 0.42, 0.8),
		CFrame.new(500, 4.22, roadCenterZ),
		Color3.fromRGB(240, 190, 30),
		Enum.Material.SmoothPlastic,
		true, false
	)
	createPart(
		envFolder, "RoadEdgeNorth",
		Vector3.new(1500, 0.42, 0.6),
		CFrame.new(500, 4.22, roadCenterZ - 12),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic,
		true, false
	)
	createPart(
		envFolder, "RoadEdgeSouth",
		Vector3.new(1500, 0.42, 0.6),
		CFrame.new(500, 4.22, roadCenterZ + 12),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic,
		true, false
	)

	-- 5. Otoyol Kaldırımı (Kuzey Yaya Kaldırımı)
	createPart(
		envFolder, "HighwaySidewalk",
		Vector3.new(1500, 0.8, 6),
		CFrame.new(500, 4.4, roadCenterZ - 16),
		Color3.fromRGB(180, 180, 185),
		Enum.Material.Concrete,
		true, true
	)

	-- 6. Yol Kenarı Sokak Lambaları ve Çevre Çam Ağaçları
	for x = -60, 1100, 90 do
		-- Sokak Lambası
		local lampPost = createPart(
			envFolder, "StreetLamp_Post",
			Vector3.new(1, 14, 1),
			CFrame.new(x, 11, roadCenterZ - 17),
			Color3.fromRGB(80, 85, 90),
			Enum.Material.Metal,
			true, true
		)
		local lampArm = createPart(
			envFolder, "StreetLamp_Arm",
			Vector3.new(4, 0.8, 0.8),
			CFrame.new(x + 1.5, 17.5, roadCenterZ - 17),
			Color3.fromRGB(80, 85, 90),
			Enum.Material.Metal,
			true, false
		)
		local lampBulb = createPart(
			envFolder, "StreetLamp_Bulb",
			Vector3.new(1.6, 0.8, 1.6),
			CFrame.new(x + 3, 17, roadCenterZ - 17),
			Color3.fromRGB(255, 240, 180),
			Enum.Material.Neon,
			true, false
		)
		local pl = Instance.new("PointLight")
		pl.Color = Color3.fromRGB(255, 235, 180)
		pl.Brightness = 1.2
		pl.Range = 30
		pl.Parent = lampBulb

		-- Otoyol Güney Kıyı Çam Ağacı (Parsellerin Dışında, Güney Kumsalı Sınırında)
		local treeZ = roadCenterZ + 18
		local trunk = createPart(
			envFolder, "PineTrunk",
			Vector3.new(2.5, 10, 2.5),
			CFrame.new(x + 35, 9, treeZ),
			Color3.fromRGB(90, 60, 35),
			Enum.Material.Wood,
			true, true
		)
		createPart(
			envFolder, "PineLeaves1",
			Vector3.new(14, 7, 14),
			CFrame.new(x + 35, 16, treeZ),
			Color3.fromRGB(45, 95, 45),
			Enum.Material.Grass,
			true, false
		)
		createPart(
			envFolder, "PineLeaves2",
			Vector3.new(10, 6, 10),
			CFrame.new(x + 35, 21, treeZ),
			Color3.fromRGB(50, 110, 50),
			Enum.Material.Grass,
			true, false
		)
		createPart(
			envFolder, "PineLeavesTop",
			Vector3.new(6, 6, 6),
			CFrame.new(x + 35, 25, treeZ),
			Color3.fromRGB(55, 125, 55),
			Enum.Material.Grass,
			true, false
		)
	end

	return envFolder
end

return IslandEnvironment
