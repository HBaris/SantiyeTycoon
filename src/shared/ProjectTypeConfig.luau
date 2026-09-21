local ProjectTypeConfig = {}

ProjectTypeConfig.TYPES = {
	SingleBuilding = {
		Id = "SingleBuilding",
		Name = "Tekli Hızlı Bina",
		Icon = "🏠",
		Badge = "HIZLI BAŞLANGIÇ",
		Difficulty = "⭐ Kolay",
		CostMultiplier = 0.6,
		RewardMultiplier = 1.0,
		MaxStages = 3,
		Description = "Düşük maliyetli ve hızlı nakit akışı sağlayan kompakt proje. Yeni şantiyeler için en hızlı başlangıç.",
		Features = {
			"⚡ %50 Daha Hızlı Tamamlanma",
			"💰 Düşük Başlangıç Maliyeti",
			"👷 2 Aktif İşçi Ekibi",
		}
	},
	IslandProject = {
		Id = "IslandProject",
		Name = "Ada Projesi (Klasik)",
		Icon = "🏝️",
		Badge = "DENGELİ KLASİK",
		Difficulty = "⭐⭐ Dengeli",
		CostMultiplier = 1.0,
		RewardMultiplier = 1.8,
		MaxStages = 5,
		Description = "Kulübeden gökdelene uzanan 5 kademeli mimari serüven. İnşaat bitiminde kule vinç sökülür ve prestij meydanı açılır.",
		Features = {
			"🏛️ 5 Kademeli Mimari İlerleme",
			"🏗️ Dönen Kule Vinç & Çevre Düzenlemesi",
			"🚁 Çatıda Helikopter Pisti (Helipad)",
		}
	},
	HousingEstate = {
		Id = "HousingEstate",
		Name = "Konut Sitesi Projesi",
		Icon = "🏘️",
		Badge = "YÜKSEK GETİRİ",
		Difficulty = "⭐⭐⭐ Zorlu",
		CostMultiplier = 1.8,
		RewardMultiplier = 3.5,
		MaxStages = 5,
		Description = "Aynı arsa üzerinde 3 bağımsız konut bloğundan oluşan modern yaşam sitesi. Çift kule vinç ve geniş işçi filosu gerektirir.",
		Features = {
			"🏢 3 Bloklu Eş Zamanlı İnşaat",
			"🏗️🏗️ Çift Kule Vinç Sistemi",
			"📈 x3.5 Kat Yüksek Kira Geliri",
		}
	},
	MegaComplex = {
		Id = "MegaComplex",
		Name = "Mega Ticaret & Plaza Kompleksi",
		Icon = "🌆",
		Badge = "EN YÜKSEK PRESTİJ",
		Difficulty = "⭐⭐⭐⭐ Mega",
		CostMultiplier = 3.0,
		RewardMultiplier = 7.2,
		MaxStages = 5,
		Description = "İkiz cam gökdelenler, modern pavyonlar ve çevre peyzajı içeren fütüristik mega proje. Uzun soluklu devasa kâr marjı!",
		Features = {
			"🏙️ İkiz İkiz Gökdelenler & AVM Plazası",
			"✨ 4'lü Kule Vinç Ağı ve İşçi Ordusu",
			"💎 Ekstra Kristal ve Prestij Ödülü",
		}
	},
}

ProjectTypeConfig.ORDER = {
	"SingleBuilding",
	"IslandProject",
	"HousingEstate",
	"MegaComplex",
}

function ProjectTypeConfig.GetType(id: string)
	return ProjectTypeConfig.TYPES[id] or ProjectTypeConfig.TYPES.IslandProject
end

return ProjectTypeConfig
