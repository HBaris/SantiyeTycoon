--!strict
-- ============================================================================
-- ShowroomPaletteBuilder.luau
-- 🎨 Kenar Varlık Sergisi & Showroom Platformu (Asset Staging Palette)
-- Parselin hemen yanına 1-10 seviye binalarını, dükkanları ve ekipmanları
-- düzenli bir showroom rafı olarak dizer.
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShowroomPaletteBuilder = {}

local function createLabel(parent: Instance, text: string, color: Color3?)
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(5, 0, 1.2, 0)
	bg.StudsOffset = Vector3.new(0, 5, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 80
	bg.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	lbl.BackgroundTransparency = 0.2
	lbl.Text = text
	lbl.TextColor3 = color or Color3.fromRGB(255, 230, 90)
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextSize = 12
	lbl.Parent = bg

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = lbl

	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(70, 80, 100)
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

	-- 1. Showroom Zemin Platformu (Parselin Sol Şeridi: X = -54)
	local platformWidth = 26
	local platformLength = 160
	local platformPos = plotOrigin + Vector3.new(-54, 1.8, 0)

	local platform = Instance.new("Part")
	platform.Name = "PalettePlatform"
	platform.Size = Vector3.new(platformWidth, 1.2, platformLength)
	platform.CFrame = CFrame.new(platformPos)
	platform.Color = Color3.fromRGB(45, 48, 55)
	platform.Material = Enum.Material.Concrete
	platform.Anchored = true
	platform.CanCollide = true
	platform.Parent = showroomFolder

	-- Çizgili Kenar Bordürü
	local curb = Instance.new("Part")
	curb.Name = "PaletteCurb"
	curb.Size = Vector3.new(1.5, 1.6, platformLength)
	curb.CFrame = CFrame.new(platformPos + Vector3.new(platformWidth / 2, 0.2, 0))
	curb.Color = Color3.fromRGB(240, 180, 30)
	curb.Material = Enum.Material.SmoothPlastic
	curb.Anchored = true
	curb.CanCollide = true
	curb.Parent = showroomFolder

	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then return showroomFolder end

	local groundY = platformPos.Y + 0.6

	-- ========================================================================
	-- 1. BÖLÜM: 1'DEN 10'A KADAR SEVİYE BİNALARI (Showroom Ön / Orta Şerit)
	-- ========================================================================
	local buildingsFolder = assets:FindFirstChild("Buildings")
	local buildingNames = {
		[1] = "🏠 Kulübe (Lv.1)",
		[2] = "🏡 Malikâne (Lv.2)",
		[3] = "🏰 Lüks Villa (Lv.3)",
		[4] = "🏢 Rezidans (Lv.4)",
		[5] = "🏙️ Gökdelen (Lv.5)",
		[6] = "🏬 İş Merkezi (Lv.6)",
		[7] = "🏛️ Kompleks (Lv.7)",
		[8] = "🏥 Tıp Merkezi (Lv.8)",
		[9] = "🗼 Çift Kule (Lv.9)",
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

				local targetZ = -68 + (lvl - 1) * 14
				local targetPos = Vector3.new(platformPos.X - 4, groundY, targetZ)

				placeModelOnGround(clone, targetPos, groundY, 10)
				createLabel(clone, buildingNames[lvl] or ("Seviye " .. lvl))
				clone.Parent = showroomFolder
			end
		end
	end

	-- ========================================================================
	-- 2. BÖLÜM: TİCARİ ÇARŞI DÜKKANLARI & HAVUZ
	-- ========================================================================
	local commFolder = assets:FindFirstChild("Commercial")
	local shops = {
		{ "Bakery", "🥖 Taş Fırın" },
		{ "Market", "🛒 Süpermarket" },
		{ "Fountain", "⛲ Süs Havuzu" },
		{ "Barber", "💈 Kuaför" },
		{ "PetShop", "🐾 Pet Shop" },
		{ "Restaurant", "🍽️ Bistro Kafe" },
	}

	if commFolder then
		for idx, shop in ipairs(shops) do
			local template = commFolder:FindFirstChild(shop[1])
			if template and template:IsA("Model") then
				local clone = template:Clone()
				clone.Name = "Showcase_" .. shop[1]
				clone:SetAttribute("IsShowcaseAsset", true)
				clone:SetAttribute("Category", "Commercial")
				clone:SetAttribute("AssetId", shop[1])

				local targetZ = -55 + (idx - 1) * 15
				local targetPos = Vector3.new(platformPos.X + 6, groundY, targetZ)

				placeModelOnGround(clone, targetPos, groundY, 9)
				createLabel(clone, shop[2], Color3.fromRGB(120, 240, 160))
				clone.Parent = showroomFolder
			end
		end
	end

	-- ========================================================================
	-- 3. BÖLÜM: ŞANTİYE EKİPMANI, AĞAÇLAR VE SOKAK PROPLARI
	-- ========================================================================
	local equipFolder = assets:FindFirstChild("Equipment")
	local treesFolder = assets:FindFirstChild("Trees")
	local propsFolder = assets:FindFirstChild("Props")

	local miscItems: { { folder: Folder?, id: string, label: string } } = {
		{ folder = equipFolder, id = "TowerCrane", label = "🏗️ Kule Vinç" },
		{ folder = treesFolder, id = "PineTree", label = "🌲 Dağ Çamı" },
		{ folder = treesFolder, id = "GardenTree", label = "🌳 Bahçe Ağacı" },
		{ folder = propsFolder, id = "StreetLamp", label = "🏮 Sokak Lambası" },
		{ folder = propsFolder, id = "Bench", label = "🪑 Park Bankı" },
		{ folder = propsFolder, id = "Planter", label = "🪴 Çiçeklik" },
	}

	for idx, item in ipairs(miscItems) do
		if item.folder then
			local template = item.folder:FindFirstChild(item.id)
			if template and template:IsA("Model") then
				local clone = template:Clone()
				clone.Name = "Showcase_" .. item.id
				clone:SetAttribute("IsShowcaseAsset", true)
				clone:SetAttribute("Category", "Props")
				clone:SetAttribute("AssetId", item.id)

				local targetZ = 38 + (idx - 1) * 7
				local targetPos = Vector3.new(platformPos.X + 6, groundY, targetZ)
				local targetWidth = (item.id == "TowerCrane") and 12 or 6

				placeModelOnGround(clone, targetPos, groundY, targetWidth)
				createLabel(clone, item.label, Color3.fromRGB(240, 200, 110))
				clone.Parent = showroomFolder
			end
		end
	end

	return showroomFolder
end

return ShowroomPaletteBuilder
