local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ağ köprüsünü hazırla
local Network = require(ReplicatedStorage.Shared.Network)
local ConstructionService = require(script.Services.ConstructionService)

print("========================================")
print("🏗️ Şantiye Tycoon (İnşaat Şirketi) Başlatılıyor...")
print("========================================")

ConstructionService.Initialize()

print("✅ Şantiye Tycoon hazır! Müteahhitler projelerine başlayabilir.")
