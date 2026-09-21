local GameConfig = {}

-- Genel Oyun ve İnşaat Şirketi Ayarları
GameConfig.GAME_NAME = "Şantiye Tycoon"
GameConfig.MAX_OFFLINE_SECONDS = 4 * 60 * 60 -- Maksimum 4 saatlik çevrimdışı birikim (14.400 sn)
GameConfig.OFFLINE_EFFICIENCY = 0.75 -- Çevrimdışı iken normal gelirin %75'i üretilir
GameConfig.PROGRESS_TO_CASH_RATIO = 1.0 -- 1 İnşaat İlerlemesi = 1 $ Gelir

-- Manuel Çekiç Vurma Turbo Ayarları
GameConfig.BOOST_MULTIPLIER = 2.0 -- Çekiçle vurulduğunda inşaat hızı 2 katına çıkar
GameConfig.BOOST_DURATION = 6.0 -- 6 saniyelik "2x Turbo İnşaat" süresi

-- Başlangıç Değerleri (Yeni Şantiye)
GameConfig.STARTING_CASH = 50
GameConfig.BASE_MATERIAL_FLOW = 5 -- Saniyede teslim edilen temel malzeme miktarı (Birim/sn)

-- 5 Kademeli İnşaat Aşamaları ve Hız Katsayıları (Eski Türbin Dengesi Aynen Korundu)
GameConfig.BUILDINGS = {
	[1] = {
		Name = "Ahşap Kulübe",
		Level = 1,
		Efficiency = 2, -- Malzeme başına 2 birim hız/gelir
		Cost = 0, -- Başlangıç projesi bedava
		Color = Color3.fromRGB(139, 90, 43),
		WallMaterial = Enum.Material.WoodPlanks,
		RoofColor = Color3.fromRGB(160, 82, 45),
		Height = 8,
		Size = Vector3.new(12, 8, 12),
	},
	[2] = {
		Name = "Tuğla Ev",
		Level = 2,
		Efficiency = 6,
		Cost = 150,
		Color = Color3.fromRGB(180, 80, 60),
		WallMaterial = Enum.Material.Brick,
		RoofColor = Color3.fromRGB(70, 70, 70),
		Height = 14,
		Size = Vector3.new(16, 14, 16),
	},
	[3] = {
		Name = "Modern Villa",
		Level = 3,
		Efficiency = 18,
		Cost = 600,
		Color = Color3.fromRGB(240, 240, 245),
		WallMaterial = Enum.Material.Concrete,
		RoofColor = Color3.fromRGB(30, 90, 150),
		Height = 22,
		Size = Vector3.new(20, 22, 20),
	},
	[4] = {
		Name = "Rezidans Apartman",
		Level = 4,
		Efficiency = 50,
		Cost = 2500,
		Color = Color3.fromRGB(200, 200, 210),
		WallMaterial = Enum.Material.Cobblestone,
		RoofColor = Color3.fromRGB(50, 50, 60),
		Height = 36,
		Size = Vector3.new(22, 36, 22),
	},
	[5] = {
		Name = "Gökdelen (Plaza)",
		Level = 5,
		Efficiency = 150,
		Cost = 10000,
		Color = Color3.fromRGB(60, 130, 200),
		WallMaterial = Enum.Material.Glass,
		RoofColor = Color3.fromRGB(0, 220, 255),
		Height = 56,
		Size = Vector3.new(24, 56, 24),
	},
}

-- Malzeme Tedarik / Lojistik Yükseltmeleri (Eski Debi Yükseltmeleri)
GameConfig.LOGISTICS_UPGRADES = {
	[1] = { Name = "Kamyonet Filosu", Cost = 100, AddedDelivery = 5 },
	[2] = { Name = "Beton Mikserleri", Cost = 350, AddedDelivery = 10 },
	[3] = { Name = "Lojistik Deposu", Cost = 1200, AddedDelivery = 25 },
	[4] = { Name = "Ağır Yük Tırları", Cost = 5000, AddedDelivery = 60 },
}

-- Yeni Şantiye Açma Maliyetleri (Katlanarak Artan Sonsuz İlerleme: baseCost * 2.2^(n-1))
GameConfig.BASE_PLOT_COST = 12000
GameConfig.PLOT_COST_MULTIPLIER = 2.2

function GameConfig.GetPlotCost(plotNumber: number): number
	if plotNumber <= 1 then return 0 end
	local exponent = plotNumber - 2
	local cost = GameConfig.BASE_PLOT_COST * (GameConfig.PLOT_COST_MULTIPLIER ^ exponent)
	return math.floor(cost)
end

-- Yeni Kaynaklar (Kristal & Mühendis)
GameConfig.STARTING_CRYSTALS = 25
GameConfig.STARTING_ENGINEERS = 0.0
GameConfig.ENGINEER_PASSIVE_RATE = 0.01 -- saniyede 0.01 mühendis (100 saniyede 1 mühendis)

-- Taşıt Sistemi (Garaj)
GameConfig.VEHICLES = {
	Scooter = {
		Id = "Scooter",
		Name = "Şantiye Scooter'ı",
		Icon = "🛴",
		Speed = 28,
		Cost = 0,
		Currency = "Cash",
		CargoCapacity = 15,
		Color = Color3.fromRGB(245, 180, 0),
		Desc = "Hızlı ve pratik başlangıç taşıtı. Şantiyeler arasında temel ulaşım sağlar.",
	},
	Motorcycle = {
		Id = "Motorcycle",
		Name = "Müteahhit Motoru",
		Icon = "🏍️",
		Speed = 48,
		Cost = 1500,
		Currency = "Cash",
		CargoCapacity = 40,
		Color = Color3.fromRGB(40, 140, 240),
		Desc = "Yüksek hız ve orta düzey malzeme taşıma kapasitesi sunan iş motoru.",
	},
	Car = {
		Id = "Car",
		Name = "Ağır Saha Kamyoneti",
		Icon = "🚗",
		Speed = 72,
		Cost = 8000,
		Currency = "Cash",
		CargoCapacity = 100,
		Color = Color3.fromRGB(220, 60, 50),
		Desc = "Uzak şantiyelere anında ulaşan ve tek seferde devasa malzeme taşıyan ağır araç.",
	},
}

-- Taşıt Malzeme Teslimat Bonusu
GameConfig.CARGO_BOOST_DURATION = 45.0 -- 45 saniyelik turbo kargo etkisi
GameConfig.CARGO_BOOST_MULTIPLIER = 2.5 -- 2.5x inşaat hızı

return GameConfig
