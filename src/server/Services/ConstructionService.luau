local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Network = require(ReplicatedStorage.Shared.Network)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local ProjectTypeConfig = require(ReplicatedStorage.Shared.ProjectTypeConfig)
local DataService = require(script.Parent.DataService)
local IslandManager = require(script.Parent.IslandManager)
local UpgradeService = require(script.Parent.UpgradeService)
local GarageService = require(script.Parent.GarageService)

local ConstructionService = {}
local activeBoosts = {} -- [Player] = expireTimestamp
local playerSlots = {}
local nextSlot = 1

-- İnşaat Çekici Eşyasını (Tool) Oluşturan Fonksiyon
local function createHammerTool(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "🔨 İnşaat Çekici"
	tool.ToolTip = "İnşaata vurarak 6 saniyelik 2x Turbo İnşaat modunu başlat!"
	tool.CanBeDropped = false
	tool.RequiresHandle = true

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.6, 2.5, 0.6)
	handle.Color = Color3.fromRGB(150, 100, 50)
	handle.Material = Enum.Material.Wood
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.Parent = tool

	-- Çekiç Başlığı (Metal)
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 0.8, 1.8)
	head.CFrame = handle.CFrame * CFrame.new(0, 1.1, 0)
	head.Color = Color3.fromRGB(80, 80, 85)
	head.Material = Enum.Material.Metal
	head.TopSurface = Enum.SurfaceType.Smooth
	head.BottomSurface = Enum.SurfaceType.Smooth
	head.Parent = tool

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = head
	weld.Parent = handle

	return tool
end

-- Bir oyuncunun tüm portföyündeki toplam inşaat hızını/gelirini hesaplayan fonksiyon
local function calculateTotalProductionRate(player: Player, isTurbo: boolean): (number, number)
	local profile = DataService.GetProfile(player)
	if not profile then return 0, 0 end

	local multipliers = UpgradeService.GetMultipliers(player)
	local totalSpeed = 0
	local delivery = profile.MaterialDelivery or GameConfig.BASE_MATERIAL_FLOW

	for plotIdx, plotData in pairs(profile.Plots or {}) do
		local bData = GameConfig.BUILDINGS[plotData.BuildingLevel] or GameConfig.BUILDINGS[1]
		local pTypeData = ProjectTypeConfig.GetType(plotData.ProjectType or "IslandProject")
		local pRewardMultiplier = pTypeData.RewardMultiplier or 1.0

		local plotSpeed = (delivery * bData.Efficiency * pRewardMultiplier)

		-- Taşıtla yapılan kargo teslimat turbo hızlandırması kontrolü
		if GarageService.IsCargoBoostActive(player, tonumber(plotIdx) or 1) then
			plotSpeed *= GameConfig.CARGO_BOOST_MULTIPLIER
		end

		totalSpeed += plotSpeed
	end

	local turboMultiplier = isTurbo and GameConfig.BOOST_MULTIPLIER or 1.0
	local finalSpeed = totalSpeed * turboMultiplier * multipliers.ProductionMultiplier * multipliers.SpeedMultiplier
	local finalCashPerSec = math.floor(finalSpeed * GameConfig.PROGRESS_TO_CASH_RATIO)

	return finalSpeed, finalCashPerSec
end

function ConstructionService.Initialize()
	local function handlePlayer(player: Player)
		if playerSlots[player] then return end
		local slot = nextSlot
		nextSlot += 1
		playerSlots[player] = slot

		-- Veri Yükleme (Hızlı)
		local profile = DataService.LoadPlayer(player)

		-- Standart Roblox Leaderstats
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"

		local cashValue = Instance.new("IntValue")
		cashValue.Name = "💰 Kasa ($)"
		cashValue.Value = profile.Cash
		cashValue.Parent = leaderstats

		local speedValue = Instance.new("IntValue")
		speedValue.Name = "🏗️ Hız (İ/sn)"
		local initialSpeed, _ = calculateTotalProductionRate(player, false)
		speedValue.Value = initialSpeed
		speedValue.Parent = leaderstats

		leaderstats.Parent = player

		-- Oyuncunun Kayıtlı Tüm Şantiye Adalarını Anında Oluştur
		for plotIndex, pData in pairs(profile.Plots) do
			local plot = IslandManager.CreatePlot(player, slot, tonumber(plotIndex) or 1, pData.BuildingLevel)
			ConstructionService.HookPlotPads(player, plot)
		end

		-- Karakter Doğduğunda Çekiç Ver ve Şantiye Başlangıcına Işınla
		local function onCharacter(character)
			local firstPlot = IslandManager.GetPlot(player, 1)
			if firstPlot and firstPlot.Origin then
				local targetCFrame = CFrame.lookAt(
					firstPlot.Origin + Vector3.new(0, 6, 34),
					Vector3.new(firstPlot.Origin.X, 6, firstPlot.Origin.Z)
				)
				character:PivotTo(targetCFrame)
				task.delay(0.1, function()
					if character and character.Parent then
						character:PivotTo(targetCFrame)
					end
				end)
			end

			local backpack = player:WaitForChild("Backpack", 5)
			if backpack then
				local existingHammer = backpack:FindFirstChild("İnşaat Çekici")
				if not existingHammer then
					local hammer = createHammerTool()
					hammer.Parent = backpack
				end
			end
		end

		player.CharacterAdded:Connect(onCharacter)
		if player.Character then
			task.spawn(function()
				onCharacter(player.Character)
			end)
		end

		-- SÜREKLİ OFFLINE GELİR KONTROLÜ (Çevrimdışı Şantiye İlerlemesi)
		local now = os.time()
		local timeAway = math.clamp(now - profile.LastLogoutTime, 0, GameConfig.MAX_OFFLINE_SECONDS)

		if timeAway >= 10 then
			local _, baseCashRate = calculateTotalProductionRate(player, false)
			local offlineEarned = math.floor(timeAway * baseCashRate * GameConfig.OFFLINE_EFFICIENCY)

			if offlineEarned > 0 then
				DataService.AddCash(player, offlineEarned)
				cashValue.Value = profile.Cash

				task.delay(1.0, function()
					Network.ClaimOfflineEvent:FireClient(player, {
						TimeAwaySeconds = timeAway,
						CashEarned = offlineEarned,
					})
				end)
			end
		end

		-- İstemci ekran arayüzünü başlangıç seviyesiyle gecikmesiz senkronize et
		local activePlotIdx = profile.ActivePlotIndex or 1
		local activePlotData = profile.Plots[activePlotIdx] or profile.Plots[1]
		local activeLevel = activePlotData and activePlotData.BuildingLevel or 1
		Network.SyncBuildingEvent:FireClient(player, activeLevel, activePlotIdx)
	end

	-- 1. Oyuncu Katıldığında (PlayerAdded) ve Mevcut Oyuncular İçin
	Players.PlayerAdded:Connect(handlePlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(handlePlayer, player)
	end

	-- 2. Oyuncu Ayrıldığında (PlayerRemoving)
	Players.PlayerRemoving:Connect(function(player)
		activeBoosts[player] = nil
		playerSlots[player] = nil
		IslandManager.RemoveAllPlots(player)
		DataService.UnloadPlayer(player)
	end)

	-- 3. Çekiç Vurma Olayı Dinleyicisi (Turbo Modu)
	Network.HammerHitEvent.OnServerEvent:Connect(function(player)
		activeBoosts[player] = tick() + GameConfig.BOOST_DURATION
		Network.SyncTurboStatusEvent:FireAllClients(player, true, GameConfig.BOOST_DURATION)
	end)

	-- Upgrade ve Garage Servislerini İlklendir
	UpgradeService.Initialize()
	GarageService.Initialize()

	-- 3b. İstemciden Ekran Üzerindeki Butonla Yükseltme İsteği
	Network.PurchaseUpgradeEvent.OnServerEvent:Connect(function(player, plotIndex)
		plotIndex = tonumber(plotIndex) or 1
		ConstructionService.HandleUpgradeBuilding(player, plotIndex)
	end)

	-- 3c. İstemciden Yeni Şantiye Seçim Modalı ve Kilit Açma İsteği
	Network.UnlockNextPlotEvent.OnServerEvent:Connect(function(player)
		local profile = DataService.GetProfile(player)
		if not profile then return end
		local plotCount = 0
		for _ in pairs(profile.Plots) do plotCount += 1 end
		Network.OpenProjectSelectionEvent:FireClient(player, plotCount + 1)
	end)

	Network.SelectProjectTypeEvent.OnServerEvent:Connect(function(player, projectTypeId)
		ConstructionService.HandleUnlockNewPlot(player, projectTypeId)
	end)

	-- 3d. İstemci Açıldığında Aktif Şantiye ve Seviyeyi Sorgulama Fonksiyonu
	Network.GetBuildingStatusFunction.OnServerInvoke = function(player)
		local profile = DataService.GetProfile(player)
		if not profile then return 1, 1 end
		local activePlotIdx = profile.ActivePlotIndex or 1
		local activePlotData = profile.Plots[activePlotIdx] or profile.Plots[1]
		local activeLevel = activePlotData and activePlotData.BuildingLevel or 1
		return activeLevel, activePlotIdx
	end

	-- 4. Sürekli Gelir Döngüsü (Her 1 saniyede bir şantiye ilerlemesi)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local profile = DataService.GetProfile(player)
				local leaderstats = player:FindFirstChild("leaderstats")

				if profile and leaderstats then
					local isTurbo = (activeBoosts[player] or 0) > tick()
					local finalSpeed, cashEarned = calculateTotalProductionRate(player, isTurbo)

					-- Kasaya parayı aktar
					DataService.AddCash(player, cashEarned)

					-- Leaderstats Güncelle
					local cashVal = leaderstats:FindFirstChild("💰 Kasa ($)") :: IntValue
					local speedVal = leaderstats:FindFirstChild("🏗️ Hız (İ/sn)") :: IntValue
					if cashVal then cashVal.Value = profile.Cash end
					if speedVal then speedVal.Value = finalSpeed end

					-- Şantiye Ofis Tabelalarını Güncelle
					local allPlots = IslandManager.GetAllPlots(player)
					for _, plot in pairs(allPlots) do
						if plot.RateLabel then
							if isTurbo then
								plot.RateLabel.Text = string.format("🔥 TURBO İNŞAAT: +%d $/sn! 🏗️", cashEarned)
								plot.RateLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
							else
								plot.RateLabel.Text = string.format("+%d $/sn 🏗️", cashEarned)
								plot.RateLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
							end
						end
					end
				end
			end
		end
	end)
end

-- Şantiye Pad'lerinin Dokunma, Tıklama ve Tuş (E) Olaylarını Dinleme
function ConstructionService.HookPlotPads(player: Player, plot: any)
	local function tryUpgrade(triggerPlayer: Player)
		if triggerPlayer == player then
			ConstructionService.HandleUpgradeBuilding(player, plot.PlotIndex)
		end
	end

	local function tryUnlock(triggerPlayer: Player)
		if triggerPlayer == player then
			local profile = DataService.GetProfile(player)
			if not profile then return end
			local plotCount = 0
			for _ in pairs(profile.Plots) do plotCount += 1 end
			Network.OpenProjectSelectionEvent:FireClient(player, plotCount + 1)
		end
	end

	-- 1. Yükseltme Pad'i: Üstüne basınca (Touched)
	local debounceTouch = false
	plot.UpgradePad.Touched:Connect(function(hit)
		if debounceTouch then return end
		local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
		if hitPlayer == player then
			debounceTouch = true
			tryUpgrade(hitPlayer)
			task.wait(1)
			debounceTouch = false
		end
	end)

	-- 2. Yükseltme Pad'i: Mouse ile tıklayınca (ClickDetector)
	if plot.UpgradePadClick then
		plot.UpgradePadClick.MouseClick:Connect(function(clickPlayer)
			tryUpgrade(clickPlayer)
		end)
	end

	-- 3. Yükseltme Pad'i: E tuşuna basınca (ProximityPrompt)
	if plot.UpgradePadPrompt then
		plot.UpgradePadPrompt.Triggered:Connect(function(promptPlayer)
			tryUpgrade(promptPlayer)
		end)
	end

	-- 4. Binaya Doğrudan Tıklama: Çekiçle vurup Turbo İnşaatı tetikler
	if plot.BuildingClickDetector then
		plot.BuildingClickDetector.MouseClick:Connect(function(clickPlayer)
			if clickPlayer == player then
				activeBoosts[player] = tick() + GameConfig.BOOST_DURATION
				Network.SyncTurboStatusEvent:FireAllClients(player, true, GameConfig.BOOST_DURATION)
			end
		end)
	end

	-- 5. Yeni Şantiye Pad'i: Touched, Click ve Prompt
	local debounceUnlock = false
	plot.UnlockPad.Touched:Connect(function(hit)
		if debounceUnlock then return end
		local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
		if hitPlayer == player then
			debounceUnlock = true
			tryUnlock(hitPlayer)
			task.wait(1.5)
			debounceUnlock = false
		end
	end)

	if plot.UnlockPadClick then
		plot.UnlockPadClick.MouseClick:Connect(function(clickPlayer)
			tryUnlock(clickPlayer)
		end)
	end

	if plot.UnlockPadPrompt then
		plot.UnlockPadPrompt.Triggered:Connect(function(promptPlayer)
			tryUnlock(promptPlayer)
		end)
	end
end

-- Binayı Yükseltme (Ahşap Kulübe -> Tuğla Ev -> Villa -> Apartman -> Gökdelen)
function ConstructionService.HandleUpgradeBuilding(player: Player, plotIndex: number)
	local profile = DataService.GetProfile(player)
	if not profile or not profile.Plots or not profile.Plots[plotIndex] then return end

	local currentLevel = profile.Plots[plotIndex].BuildingLevel
	local nextLevel = currentLevel + 1
	local nextData = GameConfig.BUILDINGS[nextLevel]

	if not nextData then
		-- Zaten Gökdelen seviyesinde
		return
	end

	local multipliers = UpgradeService.GetMultipliers(player)
	local discountedCost = math.floor(nextData.Cost * multipliers.CostDiscountMultiplier)

	if DataService.SpendCash(player, discountedCost) then
		profile.Plots[plotIndex].BuildingLevel = nextLevel
		IslandManager.UpdateBuildingVisuals(player, plotIndex, nextLevel)

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local cashVal = leaderstats:FindFirstChild("💰 Kasa ($)") :: IntValue
			local speedVal = leaderstats:FindFirstChild("🏗️ Hız (İ/sn)") :: IntValue
			if cashVal then cashVal.Value = profile.Cash end
			local newSpeed, _ = calculateTotalProductionRate(player, false)
			if speedVal then speedVal.Value = newSpeed end
		end

		print(string.format("[ConstructionService] %s Proje #%d için inşaat seviyesini %d (%s) yaptı! Ödenen: %s (İndirimli)", player.Name, plotIndex, nextLevel, nextData.Name, NumberFormat.FormatCash(discountedCost)))

		-- İstemci ekran arayüzünü anında güncelle
		Network.SyncBuildingEvent:FireClient(player, nextLevel, plotIndex)
	end
end

-- YENİ: Yeni Şantiye Açma (Katlanarak Artan Maliyet, Proje Türü Seçimi, Işınlanma YOK)
function ConstructionService.HandleUnlockNewPlot(player: Player, projectTypeId: string?)
	local profile = DataService.GetProfile(player)
	if not profile then return end

	local plotCount = 0
	for _ in pairs(profile.Plots) do
		plotCount += 1
	end

	local newPlotIndex = plotCount + 1
	local multipliers = UpgradeService.GetMultipliers(player)
	local baseCost = GameConfig.GetPlotCost(newPlotIndex)
	local finalCost = math.floor(baseCost * multipliers.CostDiscountMultiplier)

	projectTypeId = projectTypeId or "IslandProject"

	if DataService.SpendCash(player, finalCost) then
		profile.Plots[newPlotIndex] = {
			BuildingLevel = 1,
			ProjectType = projectTypeId,
			IsCompleted = false,
		}

		local slot = playerSlots[player] or 1
		local newPlot = IslandManager.CreatePlot(player, slot, newPlotIndex, 1, projectTypeId)
		ConstructionService.HookPlotPads(player, newPlot)

		-- IŞINLANMA YOK! Oyuncu garajdan taşıtına binip otoyoldan gidecek
		profile.ActivePlotIndex = newPlotIndex
		print(string.format("[ConstructionService] %s yeni bir şantiye açtı (Proje #%d, Tür: %s, Maliyet: %s)! Oyuncu taşıtıyla gidebilir.", player.Name, newPlotIndex, projectTypeId, NumberFormat.FormatCash(finalCost)))

		-- İstemci ekran arayüzünü yeni şantiye için senkronize et (Seviye 1, yeni arsa)
		Network.SyncBuildingEvent:FireClient(player, 1, newPlotIndex)
	end
end

return ConstructionService
