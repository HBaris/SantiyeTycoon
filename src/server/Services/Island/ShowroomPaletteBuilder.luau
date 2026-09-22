--!strict
-- ============================================================================
-- ShowroomPaletteBuilder.luau
-- 🎨 Zengin Varlık Fuar Alanı & Showroom Plaza (Showroom Grounds)
-- Parselin hemen yanında mimari binalar, şantiye araçları, yük taşıma modelleri,
-- çarşı dükkanları ve doğa peyzaj varlıklarını kategorize edilmiş stantlarda sergiler.
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShowroomPaletteBuilder = {}

local function createLabel(parent: Instance, text: string, color: Color3?)
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(5.2, 0, 1.2, 0)
	bg.StudsOffset = Vector3.new(0, 4.5, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 85
	bg.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	lbl.BackgroundTransparency = 0.15
	lbl.Text = text
	lbl.TextColor3 = color or Color3.fromRGB(255, 230, 90)
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextSize = 11
	lbl.Parent = bg

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = lbl

	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(65, 75, 95)
	s.Thickness = 1.5
	s.Parent = lbl
end

local function placeModelOnGround(model: Model, targetPos: Vector3, groundY: number, targetWidth: number?)
	if targetWidth then
		local _, aabbSize = model:GetBoundingBox()
		local maxHoriz = math.max(aabbSize.X, aabbSize.Z)
		if maxHoriz > 0.1 then
			model:ScaleTo(targetWidth / maxHoriz)
		end
	end
	local aabbCF, aabbSize = model:GetBoundingBox()
	local pivot = model:GetPivot()
	local bottomY = aabbCF.Position.Y - (aabbSize.Y / 2)
	local pivotOffset = pivot.Position.Y - bottomY
	model:PivotTo(CFrame.new(targetPos.X, groundY + pivotOffset, targetPos.Z))
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
		end
	end
end

function ShowroomPaletteBuilder.build(plotFolder: Instance, plotOrigin: Vector3): Folder
	local showroomFolder = Instance.new("Folder")
	showroomFolder.Name = "ShowroomPalette"
	showroomFolder.Parent = plotFolder

	-- 1. Büyük Showroom Fuar Zemin Platformu (X = -42 ile -96 arası: 54 stud genişlik, 180 stud boy)
	local platformWidth = 56
	local platformLength = 184
	local platformPos = plotOrigin + Vector3.new(-70, 1.8, 0)

	local platform = Instance.new("Part")
	platform.Name = "PalettePlatform"
	platform.Size = Vector3.new(platformWidth, 1.2, platformLength)
	platform.CFrame = CFrame.new(platformPos)
	platform.Color = Color3.fromRGB(42, 45, 52)
	platform.Material = Enum.Material.Concrete
	platform.Anchored = true
	platform.CanCollide = true
	platform.Parent = showroomFolder

	-- Sarı/Siyah Şantiye Güvenlik Bordürü
	local curb = Instance.new("Part")
	curb.Name = "PaletteCurb"
	curb.Size = Vector3.new(1.8, 1.8, platformLength)
	curb.CFrame = CFrame.new(platformPos + Vector3.new(platformWidth / 2, 0.3, 0))
	curb.Color = Color3.fromRGB(245, 185, 30)
	curb.Material = Enum.Material.SmoothPlastic
	curb.Anchored = true
	curb.CanCollide = true
	curb.Parent = showroomFolder

	-- Orta Yürüyüş Yolu (Pavement Strip)
	local strip = Instance.new("Part")
	strip.Name = "CenterWalkway"
	strip.Size = Vector3.new(6, 1.22, platformLength)
	strip.CFrame = CFrame.new(platformPos.X, platformPos.Y + 0.05, platformPos.Z)
	strip.Color = Color3.fromRGB(60, 65, 75)
	strip.Material = Enum.Material.Cobblestone
	strip.Anchored = true
	strip.CanCollide = true
	strip.Parent = showroomFolder

	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then return showroomFolder end

	local groundY = platformPos.Y + 0.65

	-- ========================================================================
	-- BÖLÜM 1: 🏛️ MİMARİ BULVARI (1 - 10 SEVİYE BİNALAR) - Dış Sol Hat (X = -84)
	-- ========================================================================
	local buildingsFolder = assets:FindFirstChild("Buildings")
	local buildingNames = {
		[1] = "🏠 Kulübe (Lv.1)", [2] = "🏡 Malikâne (Lv.2)", [3] = "🏰 Lüks Villa (Lv.3)",
		[4] = "🏢 Rezidans (Lv.4)", [5] = "🏙️ Gökdelen (Lv.5)", [6] = "🏬 İş Merkezi (Lv.6)",
		[7] = "🏛️ Kompleks (Lv.7)", [8] = "🏥 Tıp Merkezi (Lv.8)", [9] = "🗼 Çift Kule (Lv.9)",
		[10] = "👑 Metropolis (Lv.10)",
	}

	if buildingsFolder then
		for lvl = 1, 10 do
			local template = buildingsFolder:FindFirstChild("Level_" .. lvl)
			if template and template:IsA("Model") then
				local clone = template:Clone()
				clone.Name = string.format("Showcase_Level_%d", lvl)
				clone:SetAttribute("IsShowcaseAsset", true)
				clone:SetAttribute("Category", "Buildings")
				clone:SetAttribute("AssetId", "Level_" .. lvl)

				local targetZ = -82 + (lvl - 1) * 18
				local targetPos = Vector3.new(platformPos.X - 14, groundY, targetZ)

				placeModelOnGround(clone, targetPos, groundY, 11)
				createLabel(clone, buildingNames[lvl] or ("Seviye " .. lvl), Color3.fromRGB(255, 220, 80))
				clone.Parent = showroomFolder
			end
		end
	end

	-- ========================================================================
	-- BÖLÜM 2: 🚜 MÜTEAHHİT ARAÇLARI FİLOSU - İç Sol Hat (X = -75, Z: -80 .. -20)
	-- ========================================================================
	local vehiclesFolder = assets:FindFirstChild("Vehicles")
	local equipFolder = assets:FindFirstChild("Equipment")

	local vehicleItems = {
		{ folder = vehiclesFolder, id = "Scooter", label = "🛵 Şantiye Scooter'ı", width = 5 },
		{ folder = vehiclesFolder, id = "Pickup", label = "🛻 Şantiye Kamyoneti", width = 8 },
		{ folder = vehiclesFolder, id = "Forklift", label = "🚜 Şantiye Forklifti", width = 6.5 },
		{ folder = vehiclesFolder, id = "DumpTruck", label = "🚛 Damperli Kamyon", width = 10 },
		{ folder = equipFolder, id = "TowerCrane", label = "🏗️ Kule Vinç", width = 12 },
	}

	for idx, item in ipairs(vehicleItems) do
		if item.folder then
			local template = item.folder:FindFirstChild(item.id)
			if template and template:IsA("Model") then
				local clone = template:Clone()
				clone.Name = "Showcase_" .. item.id
				clone:SetAttribute("IsShowcaseAsset", true)
				clone:SetAttribute("Category", (item.id == "TowerCrane") and "Equipment" or "Vehicles")
				clone:SetAttribute("AssetId", item.id)

				local targetZ = -78 + (idx - 1) * 15
				local targetPos = Vector3.new(platformPos.X - 3, groundY, targetZ)

				placeModelOnGround(clone, targetPos, groundY, item.width)
				createLabel(clone, item.label, Color3.fromRGB(255, 175, 40))
				clone.Parent = showroomFolder
			end
		end
	end

	-- ========================================================================
	-- BÖLÜM 3: 📦 YÜK TAŞIMA & MALZEME DEPOSU - İç Sağ Hat (X = -67, Z: -80 .. -10)
	-- ========================================================================
	local cargoFolder = assets:FindFirstChild("Cargo")
	local cargoItems = {
		{ id = "BrickPallet", label = "🧱 Tuğla Paleti", width = 5.5 },
		{ id = "CementBags", label = "📦 Çimento Torbaları", width = 5.5 },
		{ id = "CargoCrate", label = "🧰 Kargo Sandığı", width = 5 },
		{ id = "SteelRebar", label = "⛓️ İnşaat Demiri", width = 7 },
		{ id = "OilBarrels", label = "🛢️ Yakıt/Yağ Varilleri", width = 5.5 },
		{ id = "SiteContainer", label = "🏠 Şantiye Konteyneri", width = 9 },
	}

	if cargoFolder then
		for idx, item in ipairs(cargoItems) do
			local template = cargoFolder:FindFirstChild(item.id)
			if template and template:IsA("Model") then
				local clone = template:Clone()
				clone.Name = "Showcase_" .. item.id
				clone:SetAttribute("IsShowcaseAsset", true)
				clone:SetAttribute("Category", "Cargo")
				clone:SetAttribute("AssetId", item.id)

				local targetZ = -78 + (idx - 1) * 14
				local targetPos = Vector3.new(platformPos.X + 8, groundY, targetZ)

				placeModelOnGround(clone, targetPos, groundY, item.width)
				createLabel(clone, item.label, Color3.fromRGB(110, 210, 255))
				clone.Parent = showroomFolder
			end
		end
	end

	-- ========================================================================
	-- BÖLÜM 4: 🏪 ÇARŞI & SOSYAL YAŞAM ALANI - Dış Sağ Hat (X = -56, Z: -78 .. 0)
	-- ========================================================================
	local commFolder = assets:FindFirstChild("Commercial")
	local shops = {
		{ "Bakery", "🥖 Taş Fırın Dükkanı" },
		{ "Market", "🛒 Süpermarket" },
		{ "Fountain", "⛲ Süs Havuzu" },
		{ "Barber", "💈 VIP Kuaför" },
		{ "PetShop", "🐾 Pet Shop" },
		{ "Restaurant", "🍽️ Bistro Kafe" },
	}

	if commFolder then
		for idx, shop in ipairs(shops) do
			local template = commFolder:FindFirstChild(shop[1])
			if template then
				local clone = template:Clone()
				if clone:IsA("Folder") then
					local inner = clone:FindFirstChildWhichIsA("Model")
					if inner then clone = inner:Clone() else continue end
				end
				if clone:IsA("Model") then
					clone.Name = "Showcase_" .. shop[1]
					clone:SetAttribute("IsShowcaseAsset", true)
					clone:SetAttribute("Category", "Commercial")
					clone:SetAttribute("AssetId", shop[1])

					local targetZ = -76 + (idx - 1) * 15
					local targetPos = Vector3.new(platformPos.X + 20, groundY, targetZ)

					placeModelOnGround(clone, targetPos, groundY, 8.5)
					createLabel(clone, shop[2], Color3.fromRGB(120, 240, 160))
					clone.Parent = showroomFolder
				end
			end
		end
	end

	-- ========================================================================
	-- BÖLÜM 5: 🌲 DOĞA, PEYZAJ & SOKAK PROPLARI - Güney Alanı (Z: 15 .. 82)
	-- ========================================================================
	local treesFolder = assets:FindFirstChild("Trees")
	local propsFolder = assets:FindFirstChild("Props")

	local natureItems = {
		{ folder = treesFolder, id = "PineTree", label = "🌲 Dağ Çamı", width = 6, xOff = -12, z = 22 },
		{ folder = treesFolder, id = "GardenTree", label = "🌳 Bahçe Meşesi", width = 6.5, xOff = 2, z = 22 },
		{ folder = treesFolder, id = "CypressTree", label = "🌲 Selvi Ağacı", width = 5.5, xOff = 16, z = 22 },
		{ folder = treesFolder, id = "BoulevardTree", label = "🌴 Bulvar Ağacı", width = 6, xOff = -12, z = 40 },
		{ folder = treesFolder, id = "HedgeBush", label = "🌿 Çit Çalılığı", width = 6.5, xOff = 2, z = 40 },
		{ folder = propsFolder, id = "StoneRock", label = "🪨 Peyzaj Kayası", width = 5.5, xOff = 16, z = 40 },
		{ folder = propsFolder, id = "StreetLamp", label = "🏮 Sokak Lambası", width = 4.5, xOff = -12, z = 58 },
		{ folder = propsFolder, id = "Bench", label = "🪑 Park Bankı", width = 5.5, xOff = 2, z = 58 },
		{ folder = propsFolder, id = "Planter", label = "🪴 Çiçeklik", width = 4.5, xOff = 16, z = 58 },
	}

	for _, item in ipairs(natureItems) do
		if item.folder then
			local template = item.folder:FindFirstChild(item.id)
			if template and template:IsA("Model") then
				local clone = template:Clone()
				clone.Name = "Showcase_" .. item.id
				clone:SetAttribute("IsShowcaseAsset", true)
				clone:SetAttribute("Category", (item.folder == treesFolder) and "Trees" or "Props")
				clone:SetAttribute("AssetId", item.id)

				local targetPos = Vector3.new(platformPos.X + item.xOff, groundY, item.z)
				placeModelOnGround(clone, targetPos, groundY, item.width)
				createLabel(clone, item.label, Color3.fromRGB(240, 200, 110))
				clone.Parent = showroomFolder
			end
		end
	end

	return showroomFolder
end

return ShowroomPaletteBuilder
