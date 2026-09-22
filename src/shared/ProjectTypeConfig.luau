local ProjectTypeConfig = {}

ProjectTypeConfig.TYPES = {
	SingleBuilding = {
		Id = "SingleBuilding",
		Name = "Müstakil / Tekli Proje",
		Icon = "🏢",
		Badge = "DENGELİ TEKLİ BİNA",
		Difficulty = "⭐ Standart",
		CostMultiplier = 1.0,
		RewardMultiplier = 1.0,
		MaxStages = 5,
		IsMultiBuilding = false,
		Description = "Parsel üzerinde tek heybetli bir ana bina yükselir. Standart inşaat maliyeti ve dengeli kira geliri.",
		Features = {
			"🏢 Tek Bağımsız Ana Yapı",
			"⚖️ Dengeli İnşaat Maliyeti",
			"🏗️ Standart Kule Vinç & Şantiye",
		}
	},
	MultiBuilding = {
		Id = "MultiBuilding",
		Name = "Çoklu Bina / Toplu Konut Kompleksi",
		Icon = "🏙️",
		Badge = "DEV KOMPLEKS (2-6 BİNA)",
		Difficulty = "⭐⭐⭐ Zorlu & Prestijli",
		CostMultiplier = 2.8,
		RewardMultiplier = 3.2,
		MaxStages = 5,
		IsMultiBuilding = true,
		Description = "Aynı parselde aşama aşama 2 ila 6 binadan oluşan devasa konut ve kule sitesi! Çok daha yüksek maliyet, katlanan nüfus ve devasa kira!",
		Features = {
			"🏘️ 2 ila 6 Eşzamanlı Bina Yerleşimi",
			"📈 x3.2 Kat Şehir Nüfusu & Kira",
			"⚠️ x2.8 Kat Daha Yüksek İnşaat Maliyeti",
		}
	},
}

ProjectTypeConfig.ORDER = {
	"SingleBuilding",
	"MultiBuilding",
}

function ProjectTypeConfig.GetType(id: string)
	return ProjectTypeConfig.TYPES[id] or ProjectTypeConfig.TYPES.SingleBuilding
end

return ProjectTypeConfig
