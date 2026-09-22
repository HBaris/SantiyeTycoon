--!strict
-- ============================================================================
-- CustomizerService.luau
-- 🛠️ Tasarım & Geliştirme Motoru Sunucu Servisi (In-Game Dev & Sandbox Engine)
-- Model Seçimi, Canlı Ölçeklendirme (ScaleTo), Döndürme, Yaşam Alanı Slotları
-- ve Kalıcı Ayar Yönetimi
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Network = require(ReplicatedStorage.Shared.Network)
local AssetNormalizer = require(ReplicatedStorage.Shared.AssetNormalizer)
local DataService = require(script.Parent.DataService)

local CustomizerService = {}

-- Oyuncunun parselini bulur
local function getPlayerPlot(player: Player, plotIndex: number?): (Instance?, Vector3?)
	local idx = plotIndex or 1
	local plotFolder = Workspace:FindFirstChild(string.format("Plot_%s_%d", player.Name, idx))
	if plotFolder then
		local plate = (plotFolder:FindFirstChild("PlotGround") or plotFolder:FindFirstChild("PlotPlate")) :: BasePart?
		local origin = plate and plate.Position or Vector3.new(0, 4.4, 0)
		return plotFolder, origin
	end
	return nil, nil
end

-- Oyuncunun parseli içindeki belirli bir modeli bulur (Bina, Çarşı dükkanı veya dekorasyon)
local function findTargetModel(plotFolder: Instance, targetName: string): Model?
	for _, desc in ipairs(plotFolder:GetDescendants()) do
		if desc:IsA("Model") and (desc.Name == targetName or desc.Name:lower() == targetName:lower() or desc.Name:find(targetName)) then
			return desc
		end
	end
	return nil
end

function CustomizerService.Initialize()
	-- 1. Model Düzenleme İsteği (Ölçek, Döndürme, Kaydırma)
	Network.CustomizeModelEvent.OnServerEvent:Connect(function(player: Player, plotIndex: number, targetName: string, action: string, value: any)
		local plotFolder, origin = getPlayerPlot(player, plotIndex)
		if not plotFolder or not origin then return end

		local model = findTargetModel(plotFolder, targetName)
		if not model then
			warn(string.format("[CustomizerService] Hedef model bulunamadı: %s (Oyuncu: %s)", targetName, player.Name))
			return
		end

		if action == "Scale" then
			local scaleRatio = tonumber(value)
			if scaleRatio and scaleRatio > 0.05 and scaleRatio < 10.0 then
				local prevScale = DataService.GetModelScale(player, targetName)
				local newScale = math.clamp(prevScale * scaleRatio, 0.2, 5.0)

				local currentScale = (model.GetScale and model:GetScale()) or 1.0
				model:ScaleTo(currentScale * scaleRatio)

				-- Modelin tabanını zemine sıfırla (Havada uçmayı veya batmayı önler)
				local currentPivot = model:GetPivot()
				local minY = math.huge
				for _, p in ipairs(model:GetDescendants()) do
					if p:IsA("BasePart") then
						minY = math.min(minY, p.Position.Y - (p.Size.Y / 2))
					end
				end

				-- Zemin kotu (Çarşı içindeyse +2.2, parsel üzerindeyse +2.0)
				local isPromenade = model:IsDescendantOf(plotFolder:FindFirstChild("CommercialPromenade") or plotFolder)
				local groundY = origin.Y + (isPromenade and 2.2 or 2.0)
				local shiftY = groundY - minY
				model:PivotTo(currentPivot + Vector3.new(0, shiftY, 0))

				DataService.SetModelScale(player, targetName, newScale)
				print(string.format("[CustomizerService] %s modeli %s için yeniden boyutlandırıldı: %.2fx (Yeni: %.2fx)", targetName, player.Name, scaleRatio, newScale))
			end

		elseif action == "Rotate" then
			local angleDeg = tonumber(value) or 90
			local pivot = model:GetPivot()
			model:PivotTo(pivot * CFrame.Angles(0, math.rad(angleDeg), 0))
			print(string.format("[CustomizerService] %s modeli %s için %d° döndürüldü.", targetName, player.Name, angleDeg))

		elseif action == "SetCFrame" or action == "Move" then
			if typeof(value) == "table" then
				local targetX = tonumber(value.X)
				local targetZ = tonumber(value.Z)
				local targetYaw = tonumber(value.Yaw) or 0

				if targetX and targetZ then
					local clampedX = math.clamp(targetX, origin.X - 36, origin.X + 36)
					local clampedZ = math.clamp(targetZ, origin.Z - 36, origin.Z + 36)

					local newRot = CFrame.Angles(0, math.rad(targetYaw), 0)
					model:PivotTo(CFrame.new(clampedX, origin.Y, clampedZ) * newRot)

					-- Zemin hizalama (minY'yi parsel zemin kotuna sıfırla)
					local currentPivot = model:GetPivot()
					local minY = math.huge
					for _, p in ipairs(model:GetDescendants()) do
						if p:IsA("BasePart") then
							minY = math.min(minY, p.Position.Y - (p.Size.Y / 2))
						end
					end

					local isPromenade = model:IsDescendantOf(plotFolder:FindFirstChild("CommercialPromenade") or plotFolder)
					local groundY = origin.Y + (isPromenade and 2.2 or 2.0)
					local shiftY = groundY - minY
					local finalCF = currentPivot + Vector3.new(0, shiftY, 0)
					model:PivotTo(finalCF)

					DataService.SetModelPosition(player, targetName, {
						X = finalCF.Position.X,
						Y = finalCF.Position.Y,
						Z = finalCF.Position.Z,
						Yaw = targetYaw
					})
					print(string.format("[CustomizerService] %s modeli %s için (%.1f, %.1f) konumuna yerleştirildi.", targetName, player.Name, clampedX, clampedZ))
				end
			end

		elseif action == "Nudge" then
			if typeof(value) == "Vector3" then
				local clamped = Vector3.new(
					math.clamp(value.X, -10, 10),
					0,
					math.clamp(value.Z, -10, 10)
				)
				model:PivotTo(model:GetPivot() + clamped)
			end
		end
	end)

	-- 2. Çarşı Yaşam Alanı Slotu Değiştirme İsteği
	local pendingRebuilds: { [Player]: boolean } = {}
	Network.ChangePromenadeSlotEvent.OnServerEvent:Connect(function(player: Player, plotIndex: number, slotIndex: number, shopId: string)
		if slotIndex < 1 or slotIndex > 6 then return end

		DataService.SetPromenadeSlot(player, slotIndex, shopId)
		print(string.format("[CustomizerService] %s Çarşı Yuvası #%d'i %s olarak değiştirdi.", player.Name, slotIndex, shopId))

		-- Çarşıyı canlı olarak yeniden inşa et (Debounce ile 0.2s sonra tek seferde)
		if not pendingRebuilds[player] then
			pendingRebuilds[player] = true
			task.delay(0.2, function()
				pendingRebuilds[player] = nil
				pcall(function()
					local IslandManager = require(script.Parent.IslandManager)
					if IslandManager and IslandManager.RebuildPromenade then
						IslandManager.RebuildPromenade(player, plotIndex)
					end
				end)
			end)
		end
	end)

	-- 3. Katalogdan Parsel Üzerine Varlık Yerleştirme / Test İsteği
	Network.SpawnAssetOnPlotEvent.OnServerEvent:Connect(function(player: Player, plotIndex: number, category: string, assetName: string)
		local plotFolder, origin = getPlayerPlot(player, plotIndex)
		if not plotFolder or not origin then return end

		local assets = ReplicatedStorage:FindFirstChild("Assets")
		local catFolder = assets and assets:FindFirstChild(category)
		local template = catFolder and catFolder:FindFirstChild(assetName)
		if not template then return end

		local clone = template:Clone()
		if clone:IsA("Folder") then
			local inner = clone:FindFirstChildWhichIsA("Model")
			if inner then
				clone = inner:Clone()
			else
				return
			end
		end

		if clone:IsA("Model") then
			clone.Name = string.format("Custom_%s_%d", assetName, tick() % 10000)
			AssetNormalizer.Normalize(clone, { MaxHorizontalSize = 35, EnforceAnchored = true })

			-- Parsel üzerine yerleştir
			local targetCF = CFrame.new(origin + Vector3.new(0, 2.0, 0))
			AssetNormalizer.PlaceOnGround(clone, targetCF)
			clone.Parent = plotFolder
			print(string.format("[CustomizerService] %s yeni varlık spawnladı: %s", player.Name, clone.Name))
		end
	end)

	-- 4. Özel Durum Sorgulama Fonksiyonu
	Network.GetCustomizerStateFunction.OnServerInvoke = function(player: Player)
		local cust = DataService.GetCustomizer(player)
		return {
			Scales = cust.Scales or {},
			Slots = cust.Slots or {},
		}
	end

	print("🛠️ CustomizerService (Tasarım & Geliştirme Motoru Servisi) Aktif Edildi.")
end

return CustomizerService
