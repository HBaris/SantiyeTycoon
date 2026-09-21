local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Network = require(ReplicatedStorage.Shared.Network)
local UpgradeConfig = require(ReplicatedStorage.Shared.UpgradeConfig)
local DataService = require(script.Parent.DataService)

local UpgradeService = {}
local adClaimDebounce = {} -- [Player] = nextClaimTick

function UpgradeService.Initialize()
	-- 1. Oyuncu Katıldığında Çevrimdışı Mühendis Hesabı ve Senkronizasyon
	local function onPlayerAdded(player: Player)
		task.wait(0.5) -- DataService yüklenmesini bekle
		local profile = DataService.GetProfile(player)
		if not profile then return end

		-- Çevrimdışı geçen sürede biriken mühendisleri hesapla
		local now = os.time()
		local timeAway = math.clamp(now - (profile.LastEngineerTime or now), 0, GameConfig.MAX_OFFLINE_SECONDS)
		local offlineEngineers = timeAway * (GameConfig.ENGINEER_PASSIVE_RATE or 0.01)

		if offlineEngineers > 0 then
			DataService.AddEngineers(player, offlineEngineers)
		end
		profile.LastEngineerTime = now

		-- İstemciye mevcut yükseltme ve kaynak durumunu aktar
		Network.SyncUpgradesEvent:FireClient(player, profile.Upgrades or {})
		Network.SyncResourcesEvent:FireClient(
			player,
			profile.Cash or 0,
			profile.Crystals or 0,
			profile.Engineers or 0.0
		)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		adClaimDebounce[player] = nil
	end)

	-- 2. Mühendis Pasif Birikim Döngüsü (Her saniye 0.01 Mühendis)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local profile = DataService.GetProfile(player)
				if profile then
					DataService.AddEngineers(player, GameConfig.ENGINEER_PASSIVE_RATE or 0.01)
					profile.LastEngineerTime = os.time()

					-- Her 2 saniyede bir veya değer değiştikçe kaynakları senkronize et
					Network.SyncResourcesEvent:FireClient(
						player,
						profile.Cash or 0,
						profile.Crystals or 0,
						profile.Engineers or 0.0
					)
				end
			end
		end
	end)

	-- 3. İstemciden Gelen Yükseltme Satın Alma İsteği (Sunucu Taraflı Güvenli Doğrulama)
	Network.BuyUpgradeEvent.OnServerEvent:Connect(function(player: Player, tabName: string, categoryId: string)
		if type(tabName) ~= "string" or type(categoryId) ~= "string" then return end
		if not UpgradeConfig.TABS[tabName] or not UpgradeConfig.CATEGORIES[categoryId] then return end

		local profile = DataService.GetProfile(player)
		if not profile then return end

		local currentLevel = DataService.GetUpgradeLevel(player, tabName, categoryId)
		local cost = UpgradeConfig.GetCost(tabName, categoryId, currentLevel)

		local purchaseSuccess = false
		if tabName == "Cash" then
			purchaseSuccess = DataService.SpendCash(player, cost)
		elseif tabName == "Crystals" then
			purchaseSuccess = DataService.SpendCrystals(player, cost)
		elseif tabName == "Engineers" then
			purchaseSuccess = DataService.SpendEngineers(player, cost)
		end

		if purchaseSuccess then
			local newLevel = currentLevel + 1
			DataService.SetUpgradeLevel(player, tabName, categoryId, newLevel)

			-- Leaderstats güncelle (Kasa değiştiyse)
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats and tabName == "Cash" then
				local cashVal = leaderstats:FindFirstChild("💰 Kasa ($)") :: IntValue
				if cashVal then cashVal.Value = profile.Cash end
			end

			-- İstemciye onay ve güncel tabloyu gönder
			Network.SyncUpgradesEvent:FireClient(player, profile.Upgrades)
			Network.SyncResourcesEvent:FireClient(
				player,
				profile.Cash,
				profile.Crystals,
				profile.Engineers
			)
			print(string.format("[UpgradeService] %s %s:%s yükseltmesini aldı (Yeni Seviye: %d)", player.Name, tabName, categoryId, newLevel))
		end
	end)

	-- 4. Opsiyonel Reklam / Günlük Ödül İle Kristal Kazanma
	Network.ClaimAdRewardEvent.OnServerEvent:Connect(function(player: Player)
		local nextAllowed = adClaimDebounce[player] or 0
		if tick() < nextAllowed then return end

		adClaimDebounce[player] = tick() + 60 -- 60 saniyede bir kullanılabilir
		local rewardCrystals = 10
		DataService.AddCrystals(player, rewardCrystals)

		local profile = DataService.GetProfile(player)
		if profile then
			Network.SyncResourcesEvent:FireClient(player, profile.Cash, profile.Crystals, profile.Engineers)
		end
		print(string.format("[UpgradeService] %s reklam izleme ödülü kazandı (+%d 💎)", player.Name, rewardCrystals))
	end)
end

-- Oyuncunun tüm sekmelerdeki yükseltmelerinden gelen kümülatif çarpanları hesaplar
function UpgradeService.GetMultipliers(player: Player)
	local result = {
		ProductionMultiplier = 1.0,
		CostDiscountMultiplier = 1.0,
		SpeedMultiplier = 1.0,
		OfflineCapHours = 4.0,
	}

	local profile = DataService.GetProfile(player)
	if not profile or not profile.Upgrades then return result end

	local totalDiscountPercent = 0

	for tabName, categories in pairs(profile.Upgrades) do
		for categoryId, level in pairs(categories) do
			if level and level > 0 then
				local tabDef = UpgradeConfig.DEFINITIONS[tabName]
				local catDef = tabDef and tabDef[categoryId]
				if catDef then
					local bonus = level * catDef.BonusPerLevel
					if categoryId == "Income" then
						result.ProductionMultiplier += (bonus / 100)
					elseif categoryId == "Discount" then
						totalDiscountPercent += bonus
					elseif categoryId == "Speed" then
						result.SpeedMultiplier += (bonus / 100)
					elseif categoryId == "Capacity" then
						result.OfflineCapHours += bonus
					end
				end
			end
		end
	end

	-- İndirim çarpanı maksimum %70 ile sınırlandırılır
	totalDiscountPercent = math.min(70, totalDiscountPercent)
	result.CostDiscountMultiplier = 1.0 - (totalDiscountPercent / 100)

	return result
end

return UpgradeService
