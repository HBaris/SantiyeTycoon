--!strict
-- ============================================================================
-- CityManager.luau
-- Cities: Skylines Şehir Simülasyon Katmanı Orkestratörü
-- Bölgeleme (Zoning), Nüfus (Population), Memnuniyet (Happiness %),
-- Pasif Gelir Çarpanı ve Yarıçap Tabanlı Hizmet Binaları
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local ZoneConfig = require(ReplicatedStorage.Shared.ZoneConfig)
local Network = require(ReplicatedStorage.Shared.Network)

local DataService = require(script.Parent.DataService)
local ServiceBuildingManager = require(script.Parent.ServiceBuildingManager)

local CityManager = {}

-- Şehir İstatistiklerini Hesaplar (Nüfus, Memnuniyet, Bölge Sayıları, Gelir Çarpanı)
function CityManager.GetCityStats(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return {
			Population = 0,
			Happiness = 70,
			HappinessMultiplier = 0.70,
			Zones = { Residential = 0, Commercial = 0, Industrial = 0, Unassigned = 0 },
			Services = {},
		}
	end

	local plots = profile.Plots or {}
	local services = profile.Services or {}

	local zoneCounts = {
		Residential = 0,
		Commercial = 0,
		Industrial = 0,
		Unassigned = 0,
	}

	local totalPopulation = 0
	local totalPlotsCount = 0

	for _, pData in pairs(plots) do
		totalPlotsCount += 1
		local zone = pData.Zone
		local bLvl = pData.BuildingLevel or 1

		if zone == "Residential" or zone == nil then
			-- Varsayılan veya atanmış konut bölgesi
			zoneCounts.Residential += 1
			totalPopulation += ZoneConfig.GetPopulation(bLvl)
		elseif zone == "Commercial" then
			zoneCounts.Commercial += 1
		elseif zone == "Industrial" then
			zoneCounts.Industrial += 1
		else
			zoneCounts.Unassigned += 1
		end
	end

	-- Memnuniyet Hesabı (Temel: %70)
	local happiness = 70

	-- Aktif Hizmet Binaları Bonusu (+10% her farklı hizmet türü için)
	local activeServiceCount = 0
	for sType, _ in pairs(services) do
		local def = ServiceBuildingManager.SERVICES[sType]
		if def then
			happiness += def.HappinessBonus
			activeServiceCount += 1
		end
	end

	-- Yüksek Nüfus / Hizmetsiz Şehir Baskısı (Nüfus > 300 ve 0 hizmet varsa -15%)
	if totalPopulation > 300 and activeServiceCount == 0 then
		happiness -= 15
	end

	-- Sınırlar: %30 ile %100 arası
	happiness = math.clamp(happiness, 30, 100)
	local multiplier = happiness / 100

	return {
		Population = totalPopulation,
		Happiness = happiness,
		HappinessMultiplier = multiplier,
		Zones = zoneCounts,
		Services = services,
	}
end

-- Gelir Çarpanını Döndürür
function CityManager.GetHappinessMultiplier(player: Player): number
	local stats = CityManager.GetCityStats(player)
	return stats.HappinessMultiplier
end

-- Ticari Kira Çarpanını Döndürür (+%75 bonus)
function CityManager.GetCommercialMultiplier(player: Player, plotIndex: number): number
	local profile = DataService.GetProfile(player)
	if not profile then return 1.0 end
	local pData = profile.Plots and profile.Plots[plotIndex]
	if pData and pData.Zone == "Commercial" then
		return 1.75
	end
	return 1.0
end

-- Sanayi Bölgesi Lojistik/Kargo Bonusunu Döndürür
function CityManager.GetIndustrialBonus(player: Player, plotIndex: number): (number, number)
	local profile = DataService.GetProfile(player)
	if not profile then return 1.0, 1.0 end
	local pData = profile.Plots and profile.Plots[plotIndex]
	if pData and pData.Zone == "Industrial" then
		return 2.0, 1.5 -- 2x Kargo Primi, 1.5x Turbo Süresi
	end
	return 1.0, 1.0
end

-- Şehir İstatistiklerini İstemciye Senkronize Eder
function CityManager.SyncCityStats(player: Player)
	local stats = CityManager.GetCityStats(player)
	Network.SyncCityStatsEvent:FireClient(player, stats)
end

-- Bir Parselin Zonunu Belirleme (Oyuncu İsteği)
function CityManager.SetPlotZone(player: Player, plotIndex: number, zoneType: string): (boolean, string?)
	local profile = DataService.GetProfile(player)
	if not profile then return false, "Profil bulunamadı" end

	local pData = profile.Plots and profile.Plots[plotIndex]
	if not pData then return false, "Şantiye parseli bulunamadı" end

	if not ZoneConfig.ZONES[zoneType] then
		return false, "Geçersiz bölge tipi"
	end

	local currentZone = pData.Zone or "Residential"
	if currentZone == zoneType then
		return true, "Bölge zaten bu tipte"
	end

	-- Yeniden İmar Maliyeti Kontrolü
	local rezoneCost = ZoneConfig.REZONE_COST
	if profile.Cash < rezoneCost then
		return false, string.format("Yeniden imar için %s gerekli!", NumberFormat.FormatCash(rezoneCost))
	end

	if not DataService.SpendCash(player, rezoneCost) then
		return false, "Yetersiz bakiye"
	end

	pData.Zone = zoneType

	-- Leaderstats bakiye güncelle
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cashVal = (leaderstats:FindFirstChild(GameConfig.CURRENCY_NAME) or leaderstats:FindFirstChild("💰 Kasa ($)")) :: IntValue
		if cashVal then cashVal.Value = profile.Cash end
	end

	-- Parsel Üzerindeki 3D Görsel İndikatörü Güncelle
	local IslandManager = require(script.Parent.IslandManager)
	if IslandManager.UpdatePlotZoneVisual then
		IslandManager.UpdatePlotZoneVisual(player, plotIndex, zoneType)
	end

	print(string.format("[CityManager] %s Proje #%d bölgesini '%s' yaptı. (-%s)", player.Name, plotIndex, zoneType, NumberFormat.FormatCash(rezoneCost)))
	CityManager.SyncCityStats(player)
	return true, nil
end

-- Hizmet Binası Satın Alma ve İnşa Etme
function CityManager.BuildService(player: Player, serviceType: string, plotIndex: number): (boolean, string?)
	local profile = DataService.GetProfile(player)
	if not profile then return false, "Profil bulunamadı" end

	local def = ServiceBuildingManager.SERVICES[serviceType]
	if not def then return false, "Geçersiz hizmet tipi" end

	profile.Services = profile.Services or {}
	if profile.Services[serviceType] then
		return false, "Bu hizmet binası zaten şehrinizde aktif!"
	end

	if profile.Cash < def.Cost then
		return false, string.format("Bu hizmet binası için %s gerekli!", NumberFormat.FormatCash(def.Cost))
	end

	if not DataService.SpendCash(player, def.Cost) then
		return false, "Yetersiz bakiye"
	end

	profile.Services[serviceType] = {
		PlotIndex = plotIndex,
		Timestamp = os.time(),
	}

	-- Leaderstats bakiye güncelle
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cashVal = (leaderstats:FindFirstChild(GameConfig.CURRENCY_NAME) or leaderstats:FindFirstChild("💰 Kasa ($)")) :: IntValue
		if cashVal then cashVal.Value = profile.Cash end
	end

	-- Hizmet Binasını Sahneye Yerleştir
	local IslandManager = require(script.Parent.IslandManager)
	if IslandManager.PlaceServiceVisual then
		IslandManager.PlaceServiceVisual(player, plotIndex, serviceType)
	end

	print(string.format("[CityManager] %s %s hizmetini Proje #%d arsasına inşa etti! (+%%%d Memnuniyet)", player.Name, def.Name, plotIndex, def.HappinessBonus))
	CityManager.SyncCityStats(player)
	return true, nil
end

-- Ağ Remotelerini Bağla
function CityManager.Initialize()
	Network.SetZoneFunction.OnServerInvoke = function(player: Player, plotIndex: number, zoneType: string)
		return CityManager.SetPlotZone(player, tonumber(plotIndex) or 1, zoneType)
	end

	Network.BuildServiceFunction.OnServerInvoke = function(player: Player, serviceType: string, plotIndex: number)
		return CityManager.BuildService(player, serviceType, tonumber(plotIndex) or 1)
	end

	Players.PlayerAdded:Connect(function(player: Player)
		task.delay(2, function()
			if player.Parent then
				CityManager.SyncCityStats(player)
			end
		end)
	end)

	print("[CityManager] Cities: Skylines Şehir Sistemi ve Remoteleri Aktif Edildi.")
end

return CityManager
