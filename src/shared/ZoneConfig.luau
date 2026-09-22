--!strict
-- ============================================================================
-- ZoneConfig.luau
-- Cities: Skylines Tarzı Bölgeleme (Zoning) Konfigürasyonu
-- 🏠 Konut (Nüfus), 🏪 Ticaret (Kira Bonusu), 🏭 Sanayi (Lojistik/Hız Bonusu)
-- ============================================================================

export type ZoneType = "Residential" | "Commercial" | "Industrial"

export type ZoneInfo = {
	Type: ZoneType,
	Name: string,
	Icon: string,
	Color: Color3,
	Description: string,
	PopulationYield: { [number]: number }?, -- Sadece Konut için
	CommercialBonus: number?,               -- Sadece Ticaret için (örn: 0.75 = +%75)
	CargoBonusMultiplier: number?,          -- Sadece Sanayi için
	TurboDurationMultiplier: number?,       -- Sadece Sanayi için
}

local ZoneConfig = {}

-- Yeniden İmar (Rezone) Maliyeti (İP)
ZoneConfig.REZONE_COST = 2500

-- 3 Temel Bölge Tanımı
ZoneConfig.ZONES = {
	Residential = {
		Type = "Residential" :: ZoneType,
		Name = "Konut Bölgesi",
		Icon = "🏠",
		Color = Color3.fromRGB(75, 180, 85), -- Cities: Skylines Yeşil
		Description = "Şehre yeni sakinler çeker, nüfusu ve cadde yaya kalabalığını artırır.",
		PopulationYield = {
			[1] = 25,    -- Ahşap Kulübe
			[2] = 100,   -- Tuğla Malikane
			[3] = 350,   -- Modern Villa
			[4] = 800,   -- Rezidans Apartman
			[5] = 2000,  -- Prestij Gökdelen
		},
	},
	Commercial = {
		Type = "Commercial" :: ZoneType,
		Name = "Ticaret Bölgesi",
		Icon = "🏪",
		Color = Color3.fromRGB(60, 145, 230), -- Cities: Skylines Açık Mavi
		Description = "Açık Hava Çarşısı dükkanlarının kira gelirini +%75 artırır.",
		CommercialBonus = 0.75, -- +%75 kira bonusu
	},
	Industrial = {
		Type = "Industrial" :: ZoneType,
		Name = "Sanayi Bölgesi",
		Icon = "🏭",
		Color = Color3.fromRGB(235, 160, 45), -- Cities: Skylines Sarı/Turuncu
		Description = "Kargo primini 2x yapar ve Turbo İnşaat süresini %50 uzatır.",
		CargoBonusMultiplier = 2.0,
		TurboDurationMultiplier = 1.5,
	},
}

-- Yardımcı Fonksiyonlar
function ZoneConfig.GetZone(zoneType: string?): ZoneInfo?
	if not zoneType then return nil end
	return ZoneConfig.ZONES[zoneType]
end

function ZoneConfig.GetPopulation(buildingLevel: number): number
	local yields = ZoneConfig.ZONES.Residential.PopulationYield
	return (yields and yields[buildingLevel]) or 25
end

return ZoneConfig
