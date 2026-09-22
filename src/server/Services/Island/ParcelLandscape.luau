--!strict
-- ============================================================================
-- ParcelLandscape.luau
-- Parsel İnşaat Aşamalarına (Seviye 1-5) Göre Dinamik Peyzaj ve Ağaç Yönetimi
-- ============================================================================

local PlotDataTypes = require(script.Parent.PlotDataTypes)
local createPart = PlotDataTypes.createPart
local createCylinder = PlotDataTypes.createCylinder

local ParcelLandscape = {}

-- ============================================================================
-- YARDIMCI AĞAÇ VE PEYZAJ BİLEŞENLERİ
-- ============================================================================

-- 1. Yabani Dağ Çamı (Seviye 1 - Doğal Kulübe Çevresi)
local function buildPineTree(parent: Instance, pos: Vector3, scale: number?): Model
	local s = scale or 1.0
	local tree = Instance.new("Model")
	tree.Name = "LandscapePine"

	local trunkH = 8 * s
	createPart(tree, "Trunk", Vector3.new(1.8 * s, trunkH, 1.8 * s), CFrame.new(pos + Vector3.new(0, trunkH / 2, 0)), Color3.fromRGB(90, 60, 35), Enum.Material.Wood, true, true)
	createPart(tree, "Leaves1", Vector3.new(10 * s, 5 * s, 10 * s), CFrame.new(pos + Vector3.new(0, trunkH + (2 * s), 0)), Color3.fromRGB(45, 95, 45), Enum.Material.Grass, true, false)
	createPart(tree, "Leaves2", Vector3.new(7 * s, 4 * s, 7 * s), CFrame.new(pos + Vector3.new(0, trunkH + (5 * s), 0)), Color3.fromRGB(50, 110, 50), Enum.Material.Grass, true, false)
	createPart(tree, "LeavesTop", Vector3.new(4 * s, 4 * s, 4 * s), CFrame.new(pos + Vector3.new(0, trunkH + (8 * s), 0)), Color3.fromRGB(55, 125, 55), Enum.Material.Grass, true, false)

	tree.Parent = parent
	return tree
end

-- 2. Konut Bahçe Ağacı (Seviye 2 - Banliyö Meyve/Süs Ağacı)
local function buildGardenTree(parent: Instance, pos: Vector3, folColor: Color3?): Model
	local tree = Instance.new("Model")
	tree.Name = "LandscapeGardenTree"

	local c = folColor or Color3.fromRGB(60, 140, 55)
	createPart(tree, "Trunk", Vector3.new(1.5, 7, 1.5), CFrame.new(pos + Vector3.new(0, 3.5, 0)), Color3.fromRGB(105, 75, 45), Enum.Material.Wood, true, true)
	createPart(tree, "FoliageMain", Vector3.new(7.5, 6, 7.5), CFrame.new(pos + Vector3.new(0, 8.5, 0)), c, Enum.Material.Grass, true, false)
	createPart(tree, "FoliageTop", Vector3.new(5.5, 3.5, 5.5), CFrame.new(pos + Vector3.new(0, 11.5, 0)), c, Enum.Material.Grass, true, false)

	tree.Parent = parent
	return tree
end

-- 3. Modern Lüks Selvi Ağacı (Seviye 3 - Villa Giriş Peyzajı)
local function buildCypressTree(parent: Instance, pos: Vector3): Model
	local tree = Instance.new("Model")
	tree.Name = "LandscapeCypress"

	createPart(tree, "Trunk", Vector3.new(1.2, 4, 1.2), CFrame.new(pos + Vector3.new(0, 2, 0)), Color3.fromRGB(80, 55, 35), Enum.Material.Wood, true, true)
	createPart(tree, "CypressBase", Vector3.new(3.6, 9, 3.6), CFrame.new(pos + Vector3.new(0, 7.5, 0)), Color3.fromRGB(35, 100, 50), Enum.Material.Grass, true, false)
	createPart(tree, "CypressTip", Vector3.new(2.4, 5, 2.4), CFrame.new(pos + Vector3.new(0, 13.5, 0)), Color3.fromRGB(40, 115, 60), Enum.Material.Grass, true, false)

	tree.Parent = parent
	return tree
end

-- 4. Prestij Bulvar Ağacı ve Taş Saksısı (Seviye 4 & 5 - Kentsel Peyzaj)
local function buildBoulevardTree(parent: Instance, pos: Vector3): Model
	local tree = Instance.new("Model")
	tree.Name = "LandscapeBoulevardTree"

	-- Mermer/Bazalt Kare Saksı
	createPart(tree, "PlanterBox", Vector3.new(4.5, 1.4, 4.5), CFrame.new(pos + Vector3.new(0, 0.7, 0)), Color3.fromRGB(65, 70, 75), Enum.Material.Slate, true, true)
	createPart(tree, "PlanterSoil", Vector3.new(3.9, 0.3, 3.9), CFrame.new(pos + Vector3.new(0, 1.3, 0)), Color3.fromRGB(85, 55, 35), Enum.Material.Ground, true, true)

	-- Gövde ve Geniş Taç
	createPart(tree, "Trunk", Vector3.new(1.6, 9, 1.6), CFrame.new(pos + Vector3.new(0, 5.5, 0)), Color3.fromRGB(95, 70, 45), Enum.Material.Wood, true, true)
	createPart(tree, "Crown1", Vector3.new(8.5, 5.5, 8.5), CFrame.new(pos + Vector3.new(0, 11.5, 0)), Color3.fromRGB(45, 135, 60), Enum.Material.Grass, true, false)
	createPart(tree, "Crown2", Vector3.new(6.0, 3.5, 6.0), CFrame.new(pos + Vector3.new(0, 14.5, 0)), Color3.fromRGB(50, 145, 65), Enum.Material.Grass, true, false)

	tree.Parent = parent
	return tree
end

-- 5. Çiçeklik / Çalı Bordürü
local function buildBushBorder(parent: Instance, cf: CFrame, size: Vector3, col: Color3)
	local bush = createPart(parent, "BushBorder", size, cf, col, Enum.Material.Grass, true, true)
	return bush
end

-- ============================================================================
-- AŞAMAYA GÖRE PEYZAJ GÜNCELLEME (Seviye 1 - 5)
-- ============================================================================
function ParcelLandscape.UpdateLandscape(plotFolder: Instance, plotOrigin: Vector3, level: number): Folder
	local oldLandscape = plotFolder:FindFirstChild("ParcelLandscape")
	if oldLandscape then
		oldLandscape:Destroy()
	end

	local landscapeFolder = Instance.new("Folder")
	landscapeFolder.Name = "ParcelLandscape"

	local pX = plotOrigin.X
	local pY = plotOrigin.Y + 2.0 -- Zemin platformu üst kotu (~6.00)
	local pZ = plotOrigin.Z

	if level == 1 then
		-- ====================================================================
		-- SEVİYE 1: AHŞAP KULÜBE (Doğal, Yabani Dağ Parseli)
		-- Kulübe arka parselde, köşelerde doğal dağ çamları
		-- ====================================================================
		buildPineTree(landscapeFolder, Vector3.new(pX - 30, pY, pZ - 28), 1.1)
		buildPineTree(landscapeFolder, Vector3.new(pX + 32, pY, pZ - 30), 0.95)
		buildPineTree(landscapeFolder, Vector3.new(pX - 28, pY, pZ + 8), 0.85)

		-- Odun kütüğü oturma alanı
		createPart(landscapeFolder, "RusticLogBench", Vector3.new(7, 1.2, 1.8), CFrame.new(pX - 20, pY + 0.6, pZ + 18), Color3.fromRGB(110, 75, 45), Enum.Material.Wood, true, true)

	elseif level == 2 then
		-- ====================================================================
		-- SEVİYE 2: MÜSTAKİL BANLİYÖ EVİ (Konut Bahçesi Düzeni)
		-- Ev merkezde, sol tarafta bahçe çimi ve meyve ağaçları
		-- ====================================================================
		buildGardenTree(landscapeFolder, Vector3.new(pX - 26, pY, pZ + 10), Color3.fromRGB(60, 140, 55))
		buildGardenTree(landscapeFolder, Vector3.new(pX - 28, pY, pZ - 20), Color3.fromRGB(55, 130, 50))
		buildPineTree(landscapeFolder, Vector3.new(pX + 32, pY, pZ - 30), 0.8)

		-- Bahçe Çiçeklik Bordürü (Ön yaya yolu kenarı)
		buildBushBorder(landscapeFolder, CFrame.new(pX + 16, pY + 0.5, pZ + 22), Vector3.new(8, 1.0, 1.6), Color3.fromRGB(50, 125, 45))

	elseif level == 3 then
		-- ====================================================================
		-- SEVİYE 3: MODERN LÜKS VİLLA (Özel Mülk Peyzajı)
		-- Villayı çevreleyen zarif selvi ağaçları ve modern çitler
		-- ====================================================================
		buildCypressTree(landscapeFolder, Vector3.new(pX - 28, pY, pZ + 12))
		buildCypressTree(landscapeFolder, Vector3.new(pX - 28, pY, pZ - 18))
		buildCypressTree(landscapeFolder, Vector3.new(pX + 32, pY, pZ + 6))
		buildGardenTree(landscapeFolder, Vector3.new(pX + 32, pY, pZ - 28), Color3.fromRGB(45, 120, 55))

		-- Villa Giriş Modern Çalı Bordürleri
		buildBushBorder(landscapeFolder, CFrame.new(pX - 16, pY + 0.6, pZ + 24), Vector3.new(12, 1.2, 1.4), Color3.fromRGB(40, 110, 45))

	elseif level == 4 then
		-- ====================================================================
		-- SEVİYE 4: REZİDANS (Kentsel Karma Yaşam Düzeni)
		-- Sol aksta Açık Hava Çarşısı başlar, bulvar ağaçları caddeyi tanımlar
		-- ====================================================================
		buildBoulevardTree(landscapeFolder, Vector3.new(pX - 12, pY, pZ + 24))
		buildBoulevardTree(landscapeFolder, Vector3.new(pX + 16, pY, pZ + 24))
		buildGardenTree(landscapeFolder, Vector3.new(pX + 32, pY, pZ - 28), Color3.fromRGB(50, 130, 60))

	elseif level >= 5 then
		-- ====================================================================
		-- SEVİYE 5: METROPOL GÖKDELEN (Prestij Kentsel Meydan & Park Peyzajı)
		-- %100 Proje Tamamlandı! İnşaat pisliği yok, şık bulvar ağaçları & meydan
		-- ====================================================================
		buildBoulevardTree(landscapeFolder, Vector3.new(pX - 10, pY, pZ + 26))
		buildBoulevardTree(landscapeFolder, Vector3.new(pX + 16, pY, pZ + 26))
		buildBoulevardTree(landscapeFolder, Vector3.new(pX + 32, pY, pZ + 6))

		-- Arka Sağ Prestij Bahçe Adası (Eski şantiye konteynerinin arkası)
		local gardenCenter = Vector3.new(pX + 30, pY, pZ - 26)
		createPart(landscapeFolder, "GardenPlazaLawn", Vector3.new(14, 0.4, 14), CFrame.new(gardenCenter + Vector3.new(0, 0.2, 0)), Color3.fromRGB(55, 145, 55), Enum.Material.Grass, true, true)
		buildBoulevardTree(landscapeFolder, gardenCenter)
		buildBushBorder(landscapeFolder, CFrame.new(gardenCenter + Vector3.new(0, 0.6, 6)), Vector3.new(12, 1.0, 1.4), Color3.fromRGB(40, 115, 50))
	end

	landscapeFolder.Parent = plotFolder
	return landscapeFolder
end

return ParcelLandscape
