local UpgradeConfig = {}

UpgradeConfig.LEVELS_PER_TIER = 10 -- Her teknoloji 10 seviye sonra bir sonrakine geçer

UpgradeConfig.TABS = {
	Cash = {
		Id = "Cash",
		Name = "Para",
		Icon = "💰",
		Color = Color3.fromRGB(72, 215, 110),
		CurrencyName = "Kasa",
	},
	Crystals = {
		Id = "Crystals",
		Name = "Kristal",
		Icon = "💎",
		Color = Color3.fromRGB(80, 190, 255),
		CurrencyName = "Kristal",
	},
	Engineers = {
		Id = "Engineers",
		Name = "Mühendis",
		Icon = "👷",
		Color = Color3.fromRGB(255, 175, 45),
		CurrencyName = "Mühendis",
	},
}

-- 4 Temel Kategori
UpgradeConfig.CATEGORIES = {
	Income = {
		Id = "Income",
		Name = "Gelir / Üretim Artışı",
		Icon = "📈",
		EffectType = "ProductionMultiplier",
		DescTemplate = "Tüm şantiyelerin gelirini +%%%d artırır",
	},
	Discount = {
		Id = "Discount",
		Name = "Maliyet Azaltma",
		Icon = "🏷️",
		EffectType = "CostDiscountMultiplier",
		DescTemplate = "Bina ve şantiye maliyetlerini -%%%d düşürür",
	},
	Capacity = {
		Id = "Capacity",
		Name = "Kapasite & Çevrimdışı",
		Icon = "📦",
		EffectType = "OfflineCapHours",
		DescTemplate = "Çevrimdışı gelir tavanını +%.1f saat uzatır",
	},
	Speed = {
		Id = "Speed",
		Name = "Hız & Çekiç Gücü",
		Icon = "⚡",
		EffectType = "SpeedMultiplier",
		DescTemplate = "İnşaat hızını ve çekiç gücünü +%%%d artırır",
	},
}

-- Her Sekme ve Kategori İçin İsim/İkon Havuzları ve Fiyatlandırma
UpgradeConfig.DEFINITIONS = {
	-- 1. PARA (CASH) SEKMEDEKİ YÜKSELTMELER (Sık, ucuz, çok sayıda)
	Cash = {
		Income = {
			BaseCost = 50,
			CostMultiplier = 1.32,
			BonusPerLevel = 6, -- +%6 gelir
			Pool = {
				{ Name = "Yağlanmış Dişliler", Icon = "⚙️" },
				{ Name = "Hidrolik Güç Sistemi", Icon = "🔧" },
				{ Name = "Akıllı Şantiye Yönetimi", Icon = "📋" },
				{ Name = "Otomatik Kontrol Ünitesi", Icon = "🎛️" },
				{ Name = "Gelişmiş Malzeme İşleme", Icon = "🧱" },
				{ Name = "Çelik Kiriş Optimizasyonu", Icon = "🏗️" },
				{ Name = "Yüksek Hızlı Asansörler", Icon = "🛗" },
				{ Name = "Dijital İskele Takibi", Icon = "💻" },
				{ Name = "Prefabrik Montaj Hattı", Icon = "🏭" },
				{ Name = "Yapay Zeka Şantiye Analitiği", Icon = "🧠" },
			},
		},
		Discount = {
			BaseCost = 120,
			CostMultiplier = 1.38,
			BonusPerLevel = 1.5, -- -%1.5 maliyet
			Pool = {
				{ Name = "Toplu Alım Anlaşması", Icon = "🤝" },
				{ Name = "Yerel Tedarikçi Ağı", Icon = "🗺️" },
				{ Name = "Verimli Lojistik Hattı", Icon = "🚛" },
				{ Name = "Optimize Tedarik Zinciri", Icon = "🔗" },
				{ Name = "Hurda Geri Dönüşüm Hattı", Icon = "♻️" },
				{ Name = "Toptan Çimento İndirimi", Icon = "📉" },
				{ Name = "Standartlaştırılmış Kalıplar", Icon = "📐" },
				{ Name = "Yakıt Tasarruflu Makineler", Icon = "⛽" },
			},
		},
		Capacity = {
			BaseCost = 80,
			CostMultiplier = 1.35,
			BonusPerLevel = 0.5, -- +0.5 saat çevrimdışı tavan
			Pool = {
				{ Name = "Ek Depo Alanı", Icon = "🛖" },
				{ Name = "Gelişmiş Stok Yönetimi", Icon = "📦" },
				{ Name = "Merkezi Depo Sistemi", Icon = "🏬" },
				{ Name = "Akıllı Envanter", Icon = "📊" },
				{ Name = "Gece Güvenlik Sistemi", Icon = "🔦" },
				{ Name = "Palet Raf Sistemleri", Icon = "🗄️" },
				{ Name = "Hava Şartlarına Dayanıklı Baraka", Icon = "⛺" },
				{ Name = "Barkodlu Stok Takibi", Icon = "🏷️" },
			},
		},
		Speed = {
			BaseCost = 100,
			CostMultiplier = 1.34,
			BonusPerLevel = 8, -- +%8 hız
			Pool = {
				{ Name = "Ek Vardiya", Icon = "⏱️" },
				{ Name = "Gece Vardiyası", Icon = "🌙" },
				{ Name = "7/24 Kesintisiz Operasyon", Icon = "🔄" },
				{ Name = "Otomasyon Montaj Hattı", Icon = "🤖" },
				{ Name = "Pnömatik El Aletleri", Icon = "🛠️" },
				{ Name = "Güçlendirilmiş Pompalar", Icon = "⛽" },
				{ Name = "Şantiye İçi Konveyör", Icon = "🛤️" },
				{ Name = "Çift Çekiç Tekniği", Icon = "🔨" },
			},
		},
	},

	-- 2. KRİSTAL (CRYSTALS) SEKMEDEKİ YÜKSELTMELER (Orta kaynak, güçlü etki)
	Crystals = {
		Income = {
			BaseCost = 5,
			CostMultiplier = 1.45,
			BonusPerLevel = 25, -- +%25 dev gelir artışı
			Pool = {
				{ Name = "Titanyum Vinç Motorları", Icon = "⚡" },
				{ Name = "Manyetik Raylı Vinç Sistemi", Icon = "🧲" },
				{ Name = "Süperiletken Kablolama", Icon = "💡" },
				{ Name = "Kuantum Lojistik Optimizasyonu", Icon = "🔮" },
				{ Name = "Nanoteknolojik Beton", Icon = "🧪" },
				{ Name = "Otonom Ağır İş Makineleri", Icon = "🚜" },
				{ Name = "Lazerli Hizalama Kuleleri", Icon = "🎯" },
				{ Name = "Plazma Kesim İstasyonları", Icon = "🔥" },
			},
		},
		Discount = {
			BaseCost = 8,
			CostMultiplier = 1.5,
			BonusPerLevel = 3.0, -- -%3.0 maliyet indirimi
			Pool = {
				{ Name = "Küresel Çelik Anlaşması", Icon = "🌐" },
				{ Name = "Gümrüksüz Malzeme Koridoru", Icon = "🚢" },
				{ Name = "Doğrudan Taşocağı Ortaklığı", Icon = "⛏️" },
				{ Name = "Stratejik Maden Rezervi", Icon = "🪙" },
				{ Name = "Akıllı İhale Algoritması", Icon = "📈" },
				{ Name = "VIP Sigorta Anlaşması", Icon = "🛡️" },
			},
		},
		Capacity = {
			BaseCost = 6,
			CostMultiplier = 1.48,
			BonusPerLevel = 1.5, -- +1.5 saat çevrimdışı tavan
			Pool = {
				{ Name = "Çelik Güçlendirmeli Mega Depo", Icon = "🏛️" },
				{ Name = "Otomatik İstifleme Vinçleri", Icon = "🏗️" },
				{ Name = "Yeraltı Siloları", Icon = "🕳️" },
				{ Name = "İklim Kontrollü Hangarlar", Icon = "❄️" },
				{ Name = "Yüksek Güvenlikli Terminal", Icon = "🚨" },
			},
		},
		Speed = {
			BaseCost = 7,
			CostMultiplier = 1.46,
			BonusPerLevel = 30, -- +%30 hız artışı
			Pool = {
				{ Name = "Ağır Siklet Kule Vinçler", Icon = "🏗️" },
				{ Name = "Çift Kollu Vinç Sistemi", Icon = "🦾" },
				{ Name = "Dizel Türbin Jeneratörleri", Icon = "🔋" },
				{ Name = "Jet Çimento Pompaları", Icon = "🚀" },
				{ Name = "Yüksek Torklu Ekskavatörler", Icon = "🚜" },
			},
		},
	},

	-- 3. MÜHENDİS (ENGINEERS) SEKMEDEKİ YÜKSELTMELER (Nadir, pasif birikir, en üst düzey teknoloji)
	Engineers = {
		Income = {
			BaseCost = 1.0,
			CostMultiplier = 1.6,
			BonusPerLevel = 60, -- +%60 gelir katlaması
			Pool = {
				{ Name = "Baş Mimar Danışmanlığı", Icon = "📐" },
				{ Name = "Yapısal Dinamik Simülatörü", Icon = "💻" },
				{ Name = "Sismik Güçlendirme Protokolü", Icon = "🏢" },
				{ Name = "Karbon Nötr Şantiye", Icon = "🌱" },
				{ Name = "Geometrik Yük Dengeleyicisi", Icon = "⚖️" },
				{ Name = "Akıllı Şehir Entegrasyonu", Icon = "🏙️" },
				{ Name = "Modüler Gökdelen İskelesi", Icon = "🧱" },
				{ Name = "Fütüristik Metropol Tasarımı", Icon = "✨" },
			},
		},
		Discount = {
			BaseCost = 2.0,
			CostMultiplier = 1.65,
			BonusPerLevel = 5.0, -- -%5 dev indirim
			Pool = {
				{ Name = "Değer Mühendisliği Analizi", Icon = "📊" },
				{ Name = "Sıfır Atık İnşaat Metodu", Icon = "🍃" },
				{ Name = "Yüksek Mukavemetli Alaşımlar", Icon = "🛡️" },
				{ Name = "Yalın Şantiye İlkeleri", Icon = "📌" },
				{ Name = "Dijital İkiz Modellemesi", Icon = "🖥️" },
				{ Name = "Otomatik Metraj Hesabı", Icon = "🧮" },
			},
		},
		Capacity = {
			BaseCost = 1.5,
			CostMultiplier = 1.62,
			BonusPerLevel = 3.0, -- +3.0 saat çevrimdışı tavan
			Pool = {
				{ Name = "Bulut Envanter Veri Merkezi", Icon = "☁️" },
				{ Name = "Tahmine Dayalı Tedarik Ağı", Icon = "📡" },
				{ Name = "Çevrimdışı Otonom Şantiye", Icon = "🌐" },
				{ Name = "Lojistik Kuantum Depolama", Icon = "🌀" },
				{ Name = "Kesintisiz Şantiye Protokolü", Icon = "♾️" },
			},
		},
		Speed = {
			BaseCost = 1.5,
			CostMultiplier = 1.6,
			BonusPerLevel = 75, -- +%75 inşaat hızı
			Pool = {
				{ Name = "Senkronize Şantiye Otomasyonu", Icon = "⚙️" },
				{ Name = "Kinetik Enerji Geri Kazanımı", Icon = "⚡" },
				{ Name = "Süpersonik Malzeme Besleyici", Icon = "🚀" },
				{ Name = "Robotik İnşaat Kolonisi", Icon = "🤖" },
				{ Name = "Zaman/Hareket Optimizasyonu", Icon = "⏱️" },
			},
		},
	},
}

-- Bir kategori için seviyeye göre maliyet hesaplar
function UpgradeConfig.GetCost(tabName: string, categoryId: string, currentLevel: number): number
	local tab = UpgradeConfig.DEFINITIONS[tabName]
	if not tab then return 999999 end
	local cat = tab[categoryId]
	if not cat then return 999999 end

	local cost = cat.BaseCost * (cat.CostMultiplier ^ currentLevel)
	if tabName == "Engineers" then
		-- Mühendis maliyetleri kesirli olabilir (örn: 1.5, 2.4, 3.8...)
		return math.round(cost * 100) / 100
	else
		return math.floor(cost)
	end
end

-- Bir kategori için şu an aktif olan teknoloji adını, ikonunu, kademe içi seviyeyi ve toplam bonusu döndürür
function UpgradeConfig.GetTechInfo(tabName: string, categoryId: string, totalLevel: number)
	local tab = UpgradeConfig.DEFINITIONS[tabName]
	local cat = tab and tab[categoryId]
	if not cat then
		return {
			Name = "Bilinmeyen",
			Icon = "❓",
			LevelInTier = 0,
			Tier = 1,
			TotalBonus = 0,
			BonusText = "+0%",
			NextCost = 0,
		}
	end

	local pool = cat.Pool
	local levelsPerTier = UpgradeConfig.LEVELS_PER_TIER
	local poolIndex = math.floor(totalLevel / levelsPerTier) % #pool + 1
	local cycle = math.floor(math.floor(totalLevel / levelsPerTier) / #pool)
	local levelInTier = totalLevel % levelsPerTier

	local rawTech = pool[poolIndex]
	local name = rawTech.Name
	if cycle > 0 then
		local roman = cycle == 1 and "Mk.II" or (cycle == 2 and "Mk.III" or ("Mk." .. tostring(cycle + 1)))
		name = string.format("%s (%s)", rawTech.Name, roman)
	end

	local totalBonus = totalLevel * cat.BonusPerLevel
	local nextCost = UpgradeConfig.GetCost(tabName, categoryId, totalLevel)

	return {
		Name = name,
		Icon = rawTech.Icon,
		LevelInTier = levelInTier,
		Tier = math.floor(totalLevel / levelsPerTier) + 1,
		TotalLevel = totalLevel,
		TotalBonus = totalBonus,
		BonusText = categoryId == "Capacity" and string.format("+%.1f Sa", totalBonus)
			or (categoryId == "Discount" and string.format("-%%%d", math.min(70, totalBonus))
			or string.format("+%%%d", totalBonus)),
		NextCost = nextCost,
	}
end

return UpgradeConfig
