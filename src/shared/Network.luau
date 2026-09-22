local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Network = {}
local FOLDER_NAME = "ConstructionRemotes"

local remoteFolder: Folder

if RunService:IsServer() then
	remoteFolder = ReplicatedStorage:FindFirstChild(FOLDER_NAME) :: Folder
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = FOLDER_NAME
		remoteFolder.Parent = ReplicatedStorage
	end

	local function ensureRemote(name: string, isFunction: boolean)
		local existing = remoteFolder:FindFirstChild(name)
		if not existing then
			local remote = Instance.new(isFunction and "RemoteFunction" or "RemoteEvent")
			remote.Name = name
			remote.Parent = remoteFolder
			return remote
		end
		return existing
	end

	Network.ClaimOfflineEvent = ensureRemote("ClaimOfflineEvent", false)
	Network.HammerHitEvent = ensureRemote("HammerHitEvent", false)
	Network.PurchaseUpgradeEvent = ensureRemote("PurchaseUpgradeEvent", false)
	Network.PurchaseLogisticsEvent = ensureRemote("PurchaseLogisticsEvent", false)
	Network.UnlockNextPlotEvent = ensureRemote("UnlockNextPlotEvent", false)
	Network.TeleportPlotEvent = ensureRemote("TeleportPlotEvent", false)
	Network.SyncTurboStatusEvent = ensureRemote("SyncTurboStatusEvent", false)
	Network.SyncBuildingEvent = ensureRemote("SyncBuildingEvent", false)
	Network.GetBuildingStatusFunction = ensureRemote("GetBuildingStatusFunction", true)

	-- YENİ: 3 Sekmeli Yükseltme, Garaj/Taşıt ve Proje Türü Remoteleri
	Network.BuyUpgradeEvent = ensureRemote("BuyUpgradeEvent", false)
	Network.ClaimAdRewardEvent = ensureRemote("ClaimAdRewardEvent", false)
	Network.SelectProjectTypeEvent = ensureRemote("SelectProjectTypeEvent", false)
	Network.SpawnVehicleEvent = ensureRemote("SpawnVehicleEvent", false)
	Network.BuyVehicleEvent = ensureRemote("BuyVehicleEvent", false)
	Network.DeliverCargoEvent = ensureRemote("DeliverCargoEvent", false)
	Network.LoadCargoEvent = ensureRemote("LoadCargoEvent", false)
	Network.SyncUpgradesEvent = ensureRemote("SyncUpgradesEvent", false)
	Network.SyncResourcesEvent = ensureRemote("SyncResourcesEvent", false)
	Network.OpenProjectSelectionEvent = ensureRemote("OpenProjectSelectionEvent", false)
	Network.UpgradeVehicleEvent = ensureRemote("UpgradeVehicleEvent", false)
	Network.OpenGarageEvent = ensureRemote("OpenGarageEvent", false)
	Network.SyncVehicleUpgradesEvent = ensureRemote("SyncVehicleUpgradesEvent", false)

	-- Cities: Skylines Şehir Sistemi Remoteleri
	Network.SetZoneFunction = ensureRemote("SetZoneFunction", true)
	Network.BuildServiceFunction = ensureRemote("BuildServiceFunction", true)
	Network.SyncCityStatsEvent = ensureRemote("SyncCityStatsEvent", false)
else
	remoteFolder = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder

	Network.ClaimOfflineEvent = remoteFolder:WaitForChild("ClaimOfflineEvent") :: RemoteEvent
	Network.HammerHitEvent = remoteFolder:WaitForChild("HammerHitEvent") :: RemoteEvent
	Network.PurchaseUpgradeEvent = remoteFolder:WaitForChild("PurchaseUpgradeEvent") :: RemoteEvent
	Network.PurchaseLogisticsEvent = remoteFolder:WaitForChild("PurchaseLogisticsEvent") :: RemoteEvent
	Network.UnlockNextPlotEvent = remoteFolder:WaitForChild("UnlockNextPlotEvent") :: RemoteEvent
	Network.TeleportPlotEvent = remoteFolder:WaitForChild("TeleportPlotEvent") :: RemoteEvent
	Network.SyncTurboStatusEvent = remoteFolder:WaitForChild("SyncTurboStatusEvent") :: RemoteEvent
	Network.SyncBuildingEvent = remoteFolder:WaitForChild("SyncBuildingEvent") :: RemoteEvent
	Network.GetBuildingStatusFunction = remoteFolder:WaitForChild("GetBuildingStatusFunction") :: RemoteFunction

	-- YENİ: İstemci Tarafı
	Network.BuyUpgradeEvent = remoteFolder:WaitForChild("BuyUpgradeEvent") :: RemoteEvent
	Network.ClaimAdRewardEvent = remoteFolder:WaitForChild("ClaimAdRewardEvent") :: RemoteEvent
	Network.SelectProjectTypeEvent = remoteFolder:WaitForChild("SelectProjectTypeEvent") :: RemoteEvent
	Network.SpawnVehicleEvent = remoteFolder:WaitForChild("SpawnVehicleEvent") :: RemoteEvent
	Network.BuyVehicleEvent = remoteFolder:WaitForChild("BuyVehicleEvent") :: RemoteEvent
	Network.DeliverCargoEvent = remoteFolder:WaitForChild("DeliverCargoEvent") :: RemoteEvent
	Network.LoadCargoEvent = remoteFolder:WaitForChild("LoadCargoEvent") :: RemoteEvent
	Network.SyncUpgradesEvent = remoteFolder:WaitForChild("SyncUpgradesEvent") :: RemoteEvent
	Network.SyncResourcesEvent = remoteFolder:WaitForChild("SyncResourcesEvent") :: RemoteEvent
	Network.OpenProjectSelectionEvent = remoteFolder:WaitForChild("OpenProjectSelectionEvent") :: RemoteEvent
	Network.UpgradeVehicleEvent = remoteFolder:WaitForChild("UpgradeVehicleEvent") :: RemoteEvent
	Network.OpenGarageEvent = remoteFolder:WaitForChild("OpenGarageEvent") :: RemoteEvent
	Network.SyncVehicleUpgradesEvent = remoteFolder:WaitForChild("SyncVehicleUpgradesEvent") :: RemoteEvent

	-- Cities: Skylines Şehir Sistemi Remoteleri
	Network.SetZoneFunction = remoteFolder:WaitForChild("SetZoneFunction") :: RemoteFunction
	Network.BuildServiceFunction = remoteFolder:WaitForChild("BuildServiceFunction") :: RemoteFunction
	Network.SyncCityStatsEvent = remoteFolder:WaitForChild("SyncCityStatsEvent") :: RemoteEvent
end

return Network
