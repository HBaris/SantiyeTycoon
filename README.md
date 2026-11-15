# 🏗️ Şantiye Tycoon (Roblox Studio)

> **English summary.** Şantiye Tycoon is a construction and logistics tycoon game for Roblox, built with Roblox Studio, Luau and Rojo.
> - Three-currency upgrade system (cash, crystals, engineers) with infinite progression.
> - Big-number formatting.
> - Drivable vehicle tiers that carry materials to sites.
> - Worker NPCs and four project types (from a quick single building to a skyscraper island).
>
> The details below are in Turkish.

Roblox Studio ve Rojo ile geliştirilmiş, modern inşaat ve lojistik tycoon oyunu.

---

## 🌟 Öne Çıkan Özellikler

### 1. 🛠️ 3 Sekmeli Gelişmiş Yükseltme Sistemi
- 💰 **Para (Cash):** İnşaat gelirleriyle yapılan sık ve kademeli geliştirmeler.
- 💎 **Kristal (Crystals):** Başarımlar ve ödüllerle kazanılan orta-üst kademe geliştirmeler.
- 👷 **Mühendis (Engineers):** Saniyede `0.01 👷` (ve çevrimdışı) pasif biriken en güçlü fütüristik teknolojiler.
- **Sonsuz İlerleme:** Her 10 seviyede bir yeni teknoloji yerine geçer; havuz tükenince `Mk.II`, `Mk.III` ekleriyle sonsuz döngü devam eder.
- **Kırmızı Rozetler (Badge):** Satın alınabilir yükseltme sayısını dinamik gösterir.

### 2. 🔢 Büyük Sayı Formatlayıcı (`NumberFormat`)
- `K`, `M`, `B`, `T` ve sonrasında `aa..zz` çift harfli ve `aaa..` üçlü harfli formatlama.

### 3. 🛵 Taşıt & Garaj Mekaniği
- **Işınlanma Yok:** Oyuncu yeni şantiyelerine otoyoldan fiziki olarak taşıtıyla sürerek gider.
- **Kademeli Araçlar:** 🛴 Şantiye Scooter'ı → 🏍️ Müteahhit Motoru → 🚗 Ağır Saha Kamyoneti.
- **Malzeme Taşıma:** Ana depodan yüklenen malzemeler şantiyeye teslim edildiğinde **45 saniyelik 2.5x Kargo Turbo İnşaat Modu** tetiklenir.

### 4. 👷 Çalışan İşçi NPC'leri
- Her şantiyede baretli ve reflektör yelekli 3 çalışan işçi (Usta Ahmet, Mühendis Burak, Sevkiyatçı Can).

### 5. 📋 4 Farklı Proje Türü Seçimi
- 🏠 **Tekli Hızlı Bina:** %50 hızlı tamamlama, düşük maliyet, hızlı nakit döngüsü.
- 🏝️ **Ada Projesi (Klasik):** 5 kademeli mimari serüven, helipadli gökdelen.
- 🏘️ **Konut Sitesi Projesi:** 3 bloklu eş zamanlı inşaat, çift kule vinç.
- 🌆 **Mega Ticaret & Plaza:** İkiz gökdelenler ve fütüristik AVM plazası.

---

## 🚀 Başlangıç ve Çalıştırma

### Rojo ile Derleme
```bash
rojo build -o "SantiyeTycoon.rbxl"
rojo serve
```

### Roblox Studio MCP Senkronizasyonu
```bash
python sync_to_studio.py
```