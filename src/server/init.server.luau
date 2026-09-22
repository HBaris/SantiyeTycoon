local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ağ köprüsünü hazırla
local Network = require(ReplicatedStorage.Shared.Network)
local ConstructionService = require(script.Services.ConstructionService)
local CityManager = require(script.Services.CityManager)
local CustomizerService = require(script.Services.CustomizerService)

print("========================================")
print("🏗️ Şantiye Tycoon (İnşaat Şirketi) Başlatılıyor...")
print("========================================")

ConstructionService.Initialize()
CityManager.Initialize()
CustomizerService.Initialize()

print("✅ Şantiye Tycoon hazır! Müteahhitler projelerine başlayabilir.")
