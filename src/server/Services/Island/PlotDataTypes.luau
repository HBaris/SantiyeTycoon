--!strict
-- ============================================================================
-- PlotDataTypes.luau
-- Ortak Şantiye Tipleri, Geometrik Parça Üreticiler ve Sabitler
-- ============================================================================

local PlotDataTypes = {}

-- Şantiyeler ve parseller arası varsayılan mesafe aralıkları
PlotDataTypes.PLOT_SPACING_X = 140
PlotDataTypes.PLOT_SPACING_Z = 120

export type PlotData = {
	Folder: Folder,
	PlotIndex: number,
	BuildingModel: Model?,
	BuildingOrigin: Vector3,
	CraneModel: Model?,
	CraneJib: Part?,
	CraneOrigin: Vector3,
	BuildingClickDetector: ClickDetector?,
	RateLabel: TextLabel?,
	UpgradePad: Part,
	UpgradePadLabel: TextLabel,
	UpgradePadClick: ClickDetector,
	UpgradePadPrompt: ProximityPrompt,
	UnlockPad: Part,
	UnlockPadLabel: TextLabel,
	UnlockPadClick: ClickDetector,
	UnlockPadPrompt: ProximityPrompt,
	UnlockGui: BillboardGui,
	CargoPad: Part,
	Origin: Vector3,
	ProjectType: string?,
}

-- Genel Parça Oluşturucu Yardımcı (Kutu / Prizma)
function PlotDataTypes.createPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	anchored: boolean?,
	canCollide: boolean?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = anchored ~= false
	part.CanCollide = canCollide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Genel Silindir Parça Oluşturucu Yardımcı
function PlotDataTypes.createCylinder(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	anchored: boolean?,
	canCollide: boolean?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = anchored ~= false
	part.CanCollide = canCollide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

return PlotDataTypes
