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

-- 1. GÜVENLİK TEMİZLİĞİ: Tüm zararlı/gizli Script nesnelerini yok eder
function AssetNormalizer.Sanitize(root: Instance): { string }
	local removedScripts: { string } = {}

	for _, desc in ipairs(root:GetDescendants()) do
		if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
			table.insert(removedScripts, string.format("%s (%s) @ %s", desc.Name, desc.ClassName, desc:GetFullName()))
			desc:Destroy()
		end
	end

	return removedScripts
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
