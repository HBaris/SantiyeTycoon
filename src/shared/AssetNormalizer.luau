--!strict
-- ============================================================================
-- AssetNormalizer.luau
-- Roblox Studio Toolbox / Creator Store Hazır Varlıklarını Güvenlikten
-- Geçirme (Anti-Backdoor / Anti-Malware), Boyutlandırma ve Standardizasyon
-- ============================================================================

local AssetNormalizer = {}

export type NormalizationOptions = {
	MaxHorizontalSize: number?,
	TargetHeight: number?,
	EnforceAnchored: boolean?,
	MakeNonCollidableDecoration: boolean?,
	DefaultPrimaryPart: boolean?,
}

-- 1. GÜVENLİK VE GÖRSEL TEMİZLİK: Zararlı scriptleri, aşırı ışıkları ve çöp modelleri yok eder
function AssetNormalizer.Sanitize(root: Instance): { string }
	local removed: { string } = {}

	for _, desc in ipairs(root:GetDescendants()) do
		if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
			table.insert(removed, string.format("%s (%s)", desc.Name, desc.ClassName))
			desc:Destroy()
		elseif desc:IsA("Light") or desc:IsA("ParticleEmitter") or desc:IsA("Beam") or desc:IsA("Highlight") then
			-- Model küçüldüğünde üst üste binip kör edici parlama yapan hazır ışık/efektleri temizle
			desc:Destroy()
		elseif desc.Name == "ThreeDTextObject" or desc.Name == "realisticTree" or desc.Name == "Leaves Bush Grass" then
			-- Hazır modellerdeki havada asılı köklü ağaçlar ve 3D yazı çöplerini temizle
			desc:Destroy()
		elseif desc:IsA("BasePart") and desc.Material == Enum.Material.Neon then
			-- Aşırı parlak neon yüzeyleri parlamayan pürüzsüz plastiğe çevir
			local c = desc.Color
			if (c.R + c.G + c.B) / 3 > 0.6 then
				desc.Material = Enum.Material.SmoothPlastic
			end
		end
	end

	return removed
end

-- 2. NORMALİZASYON: Anchored durumu, PrimaryPart ve ScaleTo standardizasyonu
function AssetNormalizer.Normalize(model: Model, options: NormalizationOptions?): Model
	local opts: NormalizationOptions = options or {}
	local enforceAnchored = if opts.EnforceAnchored ~= nil then opts.EnforceAnchored else true

	-- Güvenlik temizliğini uygula
	AssetNormalizer.Sanitize(model)

	-- Parça özelliklerini standardize et
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			if enforceAnchored then
				desc.Anchored = true
			end
			if opts.MakeNonCollidableDecoration then
				desc.CanCollide = false
			end
		end
	end

	-- PrimaryPart yoksa en büyük taban parçasını veya ilk BasePart'ı seç
	if not model.PrimaryPart then
		local bestPart: BasePart? = nil
		local maxVol = 0
		for _, desc in ipairs(model:GetDescendants()) do
			if desc:IsA("BasePart") then
				local vol = desc.Size.X * desc.Size.Y * desc.Size.Z
				if vol > maxVol then
					maxVol = vol
					bestPart = desc
				end
			end
		end
		model.PrimaryPart = bestPart
	end

	-- Dinamik BoundingBox ve ScaleTo
	local _, currentSize = model:GetBoundingBox()

	-- Yatay sınır ölçekleme
	if opts.MaxHorizontalSize and opts.MaxHorizontalSize > 0 then
		local maxHoriz = math.max(currentSize.X, currentSize.Z)
		if maxHoriz > opts.MaxHorizontalSize then
			local scale = opts.MaxHorizontalSize / maxHoriz
			model:ScaleTo(scale)
			_, currentSize = model:GetBoundingBox()
		end
	end

	-- Dikey sınır ölçekleme
	if opts.TargetHeight and opts.TargetHeight > 0 then
		if currentSize.Y > opts.TargetHeight then
			local scale = opts.TargetHeight / currentSize.Y
			model:ScaleTo(scale)
		end
	end

	return model
end

-- 3. ZEMİNE YERLEŞTİRME (Ground Alignment)
function AssetNormalizer.PlaceOnGround(model: Model, targetCF: CFrame): ()
	local _, size = model:GetBoundingBox()
	local placedCF = targetCF * CFrame.new(0, size.Y / 2, 0)
	model:PivotTo(placedCF)
end

return AssetNormalizer
