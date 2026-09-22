--!strict
-- ============================================================================
-- CommercialBuilder.luau
-- Zemin Kat Otomatik Ticari Dükkanlar, Vitrinler, Tenteler ve Sokak Detayları
-- (Taş Fırın, Gross Market, Berber & Kuaför, PetShop, Kafe & Restoran)
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlotDataTypes = require(script.Parent.PlotDataTypes)

local createPart = PlotDataTypes.createPart
local createCylinder = PlotDataTypes.createCylinder

local CommercialBuilder = {}

function CommercialBuilder.buildStorefront(
	parent: Instance,
	centerCF: CFrame,
	shopId: string,
	width: number,
	height: number
): Model?
	local shopData = GameConfig.COMMERCIAL_SHOPS[shopId]
	if not shopData then return nil end

	local shopModel = Instance.new("Model")
	shopModel.Name = "Shop_" .. shopId

	local halfW = width / 2

	-- 1. Vitrin Camı ve Çerçevesi
	createPart(shopModel, "ShopFrame", Vector3.new(width, height, 0.6), centerCF, Color3.fromRGB(40, 45, 50), Enum.Material.Metal, true, true)
	createPart(shopModel, "ShowcaseGlass", Vector3.new(width - 1.2, height - 1.4, 0.4), centerCF * CFrame.new(0, 0, 0.1), Color3.fromRGB(180, 230, 255), Enum.Material.Glass, true, false)

	-- İç Mekan Sıcak Işığı
	local interiorLight = createPart(shopModel, "InteriorLight", Vector3.new(1, 1, 1), centerCF * CFrame.new(0, height * 0.25, -2), Color3.fromRGB(255, 245, 200), Enum.Material.Neon, true, false)
	interiorLight.Transparency = 0.5
	local pt = Instance.new("PointLight")
	pt.Color = Color3.fromRGB(255, 240, 200)
	pt.Brightness = 1.2
	pt.Range = 22
	pt.Parent = interiorLight

	-- İç Mekan Tezgahı
	createPart(shopModel, "ShopCounter", Vector3.new(width - 2.5, 2.2, 1.6), centerCF * CFrame.new(0, -height/2 + 1.1, -1.8), Color3.fromRGB(120, 85, 45), Enum.Material.WoodPlanks, true, true)

	-- 2. Çizgili Kumaş Tente (Awning)
	local awningY = (height / 2) + 0.3
	local awningZ = 2.0
	local stripeCount = math.max(4, math.floor(width / 1.6))
	local stripeW = width / stripeCount
	for s = 1, stripeCount do
		local sColor = (s % 2 == 1) and shopData.AwningColor or shopData.AwningStripeColor
		local sOffset = -halfW + (s - 0.5) * stripeW
		createPart(
			shopModel, "AwningStripe_"..s,
			Vector3.new(stripeW, 0.3, 3.6),
			centerCF * CFrame.new(sOffset, awningY, awningZ) * CFrame.Angles(math.rad(22), 0, 0),
			sColor,
			Enum.Material.Fabric,
			true, true
		)
	end

	-- 3. 3D Neon Tabela
	local signBoard = createPart(
		shopModel, "SignBoard",
		Vector3.new(width - 0.6, 1.8, 0.6),
		centerCF * CFrame.new(0, (height / 2) + 1.6, 0.4),
		shopData.Color,
		Enum.Material.SmoothPlastic,
		true, true
	)
	local sGui = Instance.new("SurfaceGui")
	sGui.Face = Enum.NormalId.Front
	sGui.Parent = signBoard
	local sTxt = Instance.new("TextLabel")
	sTxt.Size = UDim2.new(1, 0, 1, 0)
	sTxt.BackgroundTransparency = 1
	sTxt.Text = string.format("%s %s", shopData.Icon, shopData.Name:upper())
	sTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
	sTxt.TextStrokeTransparency = 0.2
	sTxt.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
	sTxt.Font = Enum.Font.FredokaOne
	sTxt.TextScaled = true
	sTxt.Parent = sGui

	-- 4. Dükkana Özel Zengin Detaylar
	if shopId == "Restaurant" then
		-- Dış Mekan Kafe Masaları ve Güneş Şemsiyesi
		for _, tx in ipairs({ -halfW + 1.8, halfW - 1.8 }) do
			local tableCF = centerCF * CFrame.new(tx, -height/2 + 1.3, 5.2)
			createCylinder(shopModel, "CafeTable", Vector3.new(0.4, 2.6, 2.6), tableCF * CFrame.Angles(0, 0, math.pi/2), Color3.fromRGB(70, 50, 30), Enum.Material.WoodPlanks, true, true)
			createPart(shopModel, "CafeChair1", Vector3.new(1.1, 1.1, 1.1), tableCF * CFrame.new(-1.6, -0.6, 0), Color3.fromRGB(60, 60, 65), Enum.Material.Metal, true, true)
			createPart(shopModel, "CafeChair2", Vector3.new(1.1, 1.1, 1.1), tableCF * CFrame.new(1.6, -0.6, 0), Color3.fromRGB(60, 60, 65), Enum.Material.Metal, true, true)
		end
		-- Dev Kafe Şemsiyesi
		createPart(shopModel, "UmbrellaPole", Vector3.new(0.4, 6.2, 0.4), centerCF * CFrame.new(0, -height/2 + 3.1, 5.2), Color3.fromRGB(200, 200, 200), Enum.Material.Metal, true, true)
		createPart(shopModel, "UmbrellaTop", Vector3.new(6.5, 0.8, 6.5), centerCF * CFrame.new(0, -height/2 + 6.3, 5.2), Color3.fromRGB(180, 50, 50), Enum.Material.Fabric, true, false)

	elseif shopId == "Barber" then
		-- Dönen Klasik Kırmızı-Beyaz-Mavi Berber Silindiri
		createCylinder(shopModel, "BarberPole", Vector3.new(2.6, 0.8, 0.8), centerCF * CFrame.new(halfW + 0.7, 0, 0.6) * CFrame.Angles(0, 0, math.pi/2), Color3.fromRGB(220, 50, 50), Enum.Material.Neon, true, true)
		createPart(shopModel, "BarberCapTop", Vector3.new(1.1, 0.3, 1.1), centerCF * CFrame.new(halfW + 0.7, 1.4, 0.6), Color3.fromRGB(230, 230, 235), Enum.Material.Metal, true, true)
		createPart(shopModel, "BarberCapBot", Vector3.new(1.1, 0.3, 1.1), centerCF * CFrame.new(halfW + 0.7, -1.4, 0.6), Color3.fromRGB(230, 230, 235), Enum.Material.Metal, true, true)

	elseif shopId == "Bakery" then
		-- Kara Tahta Menü ve Ekmek Kasaları
		local chalk = createPart(shopModel, "ChalkBoard", Vector3.new(2.0, 3.0, 0.2), centerCF * CFrame.new(halfW + 1.0, -height/2 + 1.5, 2.2), Color3.fromRGB(35, 40, 45), Enum.Material.SmoothPlastic, true, true)
		local cGui = Instance.new("SurfaceGui")
		cGui.Face = Enum.NormalId.Front
		cGui.Parent = chalk
		local cLbl = Instance.new("TextLabel")
		cLbl.Size = UDim2.new(1, 0, 1, 0)
		cLbl.BackgroundTransparency = 1
		cLbl.Text = "🥖 TAZE\nSİMİT & EKMEK\nFIRINDAN YENİ\nÇIKTI!"
		cLbl.TextColor3 = Color3.fromRGB(255, 230, 180)
		cLbl.Font = Enum.Font.FredokaOne
		cLbl.TextScaled = true
		cLbl.Parent = cGui

	elseif shopId == "PetShop" then
		-- Kulübe & Mama Kaseleri
		createPart(shopModel, "DogHouse", Vector3.new(2.2, 2.0, 2.2), centerCF * CFrame.new(-halfW - 1.2, -height/2 + 1.0, 2.0), Color3.fromRGB(160, 90, 45), Enum.Material.Wood, true, true)
		createPart(shopModel, "DogRoof", Vector3.new(2.6, 0.5, 2.6), centerCF * CFrame.new(-halfW - 1.2, -height/2 + 2.2, 2.0), Color3.fromRGB(180, 50, 50), Enum.Material.WoodPlanks, true, true)

	elseif shopId == "Market" then
		-- Meyve Kasaları
		for i, crateX in ipairs({ -halfW - 1.1, -halfW - 2.5 }) do
			createPart(shopModel, "FruitCrate_"..i, Vector3.new(1.3, 1.1, 1.3), centerCF * CFrame.new(crateX, -height/2 + 0.55, 2.0), Color3.fromRGB(170, 110, 55), Enum.Material.Wood, true, true)
		end
	end

	shopModel.Parent = parent
	return shopModel
end

return CommercialBuilder
