# 🎮 Gamification Sistemi - Geliştirme Planı

> **Versiyon:** 1.0  
> **Tarih:** 1 Aralık 2025  
> **Durum:** 🚧 Geliştirme Aşamasında

---

## 📋 Özet

Bu döküman, Rituals App'e eklenecek gamification özelliklerinin detaylı planını içerir.

### Kesinleşen Kararlar

| Konu | Karar |
|------|-------|
| Arkadaşlık limiti | ❌ Yok (sınırsız) |
| Grup rituali | 🔮 Gelecek feature (şimdi sadece 1v1) |
| Leaderboard gösterim | 👤 Kullanıcı adı |
| XP → Coin dönüşümü | ❌ Yok |
| Coin satışı | 💰 Gerçek para ile (gelecekte) |
| Private ritual paylaşımı | ❌ Tamamen kişiye özel, paylaşılamaz |

---

## ✅ MVP Kapsamı (Şimdi Yapılacak)

| Özellik | Açıklama | Öncelik |
|---------|----------|---------|
| Arkadaş Sistemi | İstek gönder/kabul et, sınırsız arkadaş | P0 |
| Ritual Paylaşımı | Public/Private seçeneği, 1v1 partner streak | P0 |
| XP & Level Sistemi | Aksiyonlardan XP kazanma, 10 level | P0 |
| Coin Sistemi | Level + badge'lerden coin kazanma | P0 |
| Freeze Hakkı | Streak koruma (satın alınabilir) | P1 |
| Badge/Rozet Sistemi | Başarı rozetleri | P1 |
| Leaderboard | Arkadaşlar arası sıralama (kullanıcı adı ile) | P1 |
| Bildirimler | Streak uyarıları, davetler | P1 |

---

## 🔮 Gelecek Features

| Özellik | Açıklama |
|---------|----------|
| Grup Ritualleri | 3+ kişilik grup streak |
| Tema Mağazası | Coin ile tema satın alma |
| Avatar Sistemi | Coin ile avatar açma |
| Premium Freeze | Gerçek para ile freeze paketi |
| Coin Satışı | Gerçek para ile coin satın alma |

---

## 🗄️ Veritabanı Şeması

### Yeni Tablolar

```sql
-- Kullanıcı profili (gamification verileri)
CREATE TABLE user_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE NOT NULL,
    xp INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    coins INTEGER DEFAULT 0,
    freeze_count INTEGER DEFAULT 2,
    total_freezes_used INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Arkadaşlık ilişkileri
CREATE TABLE friendships (
    id SERIAL PRIMARY KEY,
    requester_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    addressee_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, rejected, blocked
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP,
    UNIQUE(requester_id, addressee_id)
);

-- Paylaşılan ritualler
CREATE TABLE shared_rituals (
    id SERIAL PRIMARY KEY,
    ritual_id INTEGER REFERENCES rituals(id) ON DELETE CASCADE,
    owner_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    invite_code VARCHAR(20) UNIQUE,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ritual partnerleri (1v1)
CREATE TABLE ritual_partners (
    id SERIAL PRIMARY KEY,
    shared_ritual_id INTEGER REFERENCES shared_rituals(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, left
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_completed_at TIMESTAMP,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(shared_ritual_id, user_id)
);

-- Freeze kullanım geçmişi
CREATE TABLE freeze_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    ritual_partner_id INTEGER REFERENCES ritual_partners(id),
    streak_saved INTEGER,
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Badge tanımları
CREATE TABLE badges (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    category VARCHAR(50), -- streak, social, milestone
    xp_reward INTEGER DEFAULT 0,
    coin_reward INTEGER DEFAULT 0,
    requirement_type VARCHAR(50), -- streak_days, friends_count, rituals_completed, etc.
    requirement_value INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Kullanıcıların kazandığı badge'ler
CREATE TABLE user_badges (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    badge_id INTEGER REFERENCES badges(id) ON DELETE CASCADE,
    earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, badge_id)
);

-- XP geçmişi
CREATE TABLE xp_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL,
    source VARCHAR(100), -- ritual_complete, streak_bonus, badge_earned, etc.
    source_id INTEGER, -- ilgili ritual_id veya badge_id
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Coin geçmişi
CREATE TABLE coin_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL,
    source VARCHAR(100), -- level_up, badge_earned, purchase
    source_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bildirimler
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- friend_request, ritual_invite, streak_warning, etc.
    title VARCHAR(200),
    body TEXT,
    data JSONB, -- ek veriler (ritual_id, friend_id, etc.)
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Rituals tablosuna ekleme
ALTER TABLE rituals ADD COLUMN is_public BOOLEAN DEFAULT FALSE;
```

---

## 🎯 XP Sistemi

### XP Kazanma Tablosu

| Aksiyon | XP | Kod |
|---------|-----|-----|
| Günlük ritual tamamlama | +10 | `ritual_complete` |
| 7 günlük streak | +50 | `streak_7` |
| 14 günlük streak | +100 | `streak_14` |
| 30 günlük streak | +250 | `streak_30` |
| 100 günlük streak | +1000 | `streak_100` |
| Yeni ritual oluşturma | +5 | `ritual_create` |
| Ritual paylaşma (public) | +15 | `ritual_share` |
| Arkadaşlık kurma | +10 | `friend_add` |
| Partner ritualine katılma | +20 | `partner_join` |
| Partner streak devam | +5 | `partner_streak` |
| İlk ritual tamamlama | +25 | `first_ritual` |

### Level Tablosu

| Level | XP Min | XP Max | Ünvan | Coin Ödülü |
|-------|--------|--------|-------|------------|
| 1 | 0 | 99 | 🌱 Tohum | - |
| 2 | 100 | 249 | 🌿 Filiz | 10 |
| 3 | 250 | 499 | 🌳 Fidan | 15 |
| 4 | 500 | 849 | 🌲 Ağaç | 20 |
| 5 | 850 | 1299 | 🌴 Orman | 30 |
| 6 | 1300 | 1899 | ⭐ Yıldız | 40 |
| 7 | 1900 | 2699 | 🌟 Parlak Yıldız | 50 |
| 8 | 2700 | 3799 | 💫 Takımyıldızı | 75 |
| 9 | 3800 | 5199 | 🌙 Ay | 100 |
| 10 | 5200 | ∞ | ☀️ Güneş | 150 |

---

## 🏆 Badge Sistemi

### Streak Badge'leri

| ID | Badge | Icon | Koşul | XP | Coin |
|----|-------|------|-------|-----|------|
| 1 | Kıvılcım | 🔥 | 3 günlük streak | 15 | 5 |
| 2 | Alev | 🔥🔥 | 7 günlük streak | 30 | 10 |
| 3 | Ateş Topu | 🔥🔥🔥 | 14 günlük streak | 50 | 20 |
| 4 | Meteor | ☄️ | 30 günlük streak | 100 | 50 |
| 5 | Efsane | 💎 | 100 günlük streak | 500 | 200 |

### Sosyal Badge'ler

| ID | Badge | Icon | Koşul | XP | Coin |
|----|-------|------|-------|-----|------|
| 6 | İlk Arkadaş | 🤝 | 1 arkadaş | 10 | 5 |
| 7 | Sosyal Kelebek | 👥 | 10 arkadaş | 50 | 25 |
| 8 | Popüler | 🌟 | 25 arkadaş | 100 | 50 |
| 9 | Takım Oyuncusu | 🎯 | 1 partner ritual | 20 | 10 |
| 10 | Mentor | 🏅 | 5 kişi ritualine katılsın | 100 | 50 |

### Milestone Badge'ler

| ID | Badge | Icon | Koşul | XP | Coin |
|----|-------|------|-------|-----|------|
| 11 | Başlangıç | 🎉 | İlk ritual tamamla | 15 | 5 |
| 12 | Düzenli | 📅 | 30 ritual tamamla | 50 | 25 |
| 13 | Koleksiyoncu | 📚 | 5 ritual oluştur | 30 | 15 |
| 14 | Sabahçı | 🌅 | 10 sabah rituali | 40 | 20 |
| 15 | Gececi | 🌙 | 10 akşam rituali | 40 | 20 |

---

## ❄️ Freeze Sistemi

| Özellik | Değer |
|---------|-------|
| Başlangıç hakkı | 2 |
| Maksimum biriktirme | 5 |
| Haftalık ücretsiz | 1 (Pazar) |
| Coin ile satın alma | 20 coin = 1 freeze |

### Kurallar
1. Kullanıcı manuel seçer (otomatik kullanılmaz)
2. Her ritual için ayrı freeze gerekir
3. Partner streak'te sadece kendi streak'ini korur
4. Freeze geçmişi loglanır

---

## 🔔 Bildirim Türleri

| Type | Tetikleyici | Title | Body |
|------|-------------|-------|------|
| `streak_warning` | 3 saat kala | Streak Tehlikede! 🔥 | {ritual_name} streak'in 3 saat içinde kırılacak! |
| `streak_broken` | Streak kırıldı | Streak Bitti 💔 | {days} günlük streak sona erdi |
| `streak_milestone` | 7/14/30 gün | Tebrikler! 🎉 | {days} günlük streak'e ulaştın! |
| `friend_request` | İstek geldi | Arkadaşlık İsteği 👋 | {username} seninle arkadaş olmak istiyor |
| `friend_accepted` | Kabul edildi | Arkadaşlık Kuruldu 🤝 | {username} arkadaşlık isteğini kabul etti |
| `ritual_invite` | Davet geldi | Ritual Daveti 🎯 | {username} seni '{ritual_name}' ritualine davet etti |
| `partner_completed` | Partner tamamladı | Partner Tamamladı ✅ | {username} rituali tamamladı, sıra sende! |
| `level_up` | Level atladı | Level Atladın! ⬆️ | Level {level} oldun! +{coins} coin kazandın |
| `badge_earned` | Badge kazanıldı | Yeni Rozet! 🏆 | '{badge_name}' rozetini kazandın! |
| `freeze_available` | Pazar günü | Freeze Hakkı ❄️ | Haftalık freeze hakkın eklendi! |

---

## 🔌 API Endpoints

### Profil & Gamification
```
GET    /api/profile              → Profil bilgileri (XP, level, coin, freeze)
PUT    /api/profile/username     → Kullanıcı adı güncelle
GET    /api/profile/:userId      → Başka kullanıcının public profili
```

### Arkadaşlık
```
GET    /api/friends              → Arkadaş listesi
GET    /api/friends/requests     → Bekleyen istekler
POST   /api/friends/request      → İstek gönder {addressee_id}
PUT    /api/friends/accept/:id   → Kabul et
PUT    /api/friends/reject/:id   → Reddet
DELETE /api/friends/:id          → Arkadaşı sil
GET    /api/users/search?q=      → Kullanıcı ara (username ile)
```

### Ritual Paylaşımı
```
PUT    /api/rituals/:id/visibility   → Public/Private değiştir
POST   /api/rituals/:id/share        → Davet kodu oluştur
POST   /api/rituals/join/:code       → Davet koduyla katıl
GET    /api/rituals/:id/partner      → Partner bilgisi
DELETE /api/rituals/:id/leave        → Partnerlıktan ayrıl
GET    /api/rituals/shared           → Katıldığım partner ritualler
```

### Badge & Freeze
```
GET    /api/badges                → Tüm badge listesi
GET    /api/badges/my             → Kazandığım badge'ler
POST   /api/freeze/use            → Freeze kullan {ritual_id}
POST   /api/freeze/buy            → Coin ile freeze satın al
```

### Leaderboard
```
GET    /api/leaderboard           → Global top 100
GET    /api/leaderboard/friends   → Arkadaşlar arası
GET    /api/leaderboard/weekly    → Haftalık sıralama
```

### Bildirimler
```
GET    /api/notifications         → Bildirim listesi
PUT    /api/notifications/:id/read    → Okundu işaretle
PUT    /api/notifications/read-all    → Tümünü okundu yap
DELETE /api/notifications/:id     → Bildirimi sil
```

---

## 📱 UI Ekranları

### Yeni Ekranlar
1. **Profil Sayfası** (güncelleme) - XP bar, level, coin, freeze, badge'ler
2. **Arkadaşlar Sayfası** - Liste, arama, istekler
3. **Kullanıcı Profili** - Başkasının public profili
4. **Leaderboard Sayfası** - Sıralama tabloları
5. **Badge Koleksiyonu** - Tüm badge'ler, kazanılanlar
6. **Bildirimler Sayfası** - Bildirim listesi
7. **Ritual Paylaşım Modal** - Davet kodu, partner durumu
8. **Davet Kabul Ekranı** - Deeplink ile açılan sayfa

### Güncellenecek Ekranlar
1. **Home** - XP bar, streak gösterimi
2. **Ritual List** - Public/Private badge, partner ikonu
3. **Ritual Detail** - Paylaşım butonu, partner streak
4. **Settings** - Username değiştirme

---

## 📅 Sprint Planı

### Sprint 1: Veritabanı & Temel API (3-4 gün)
- [ ] Migration script'leri oluştur
- [ ] user_profiles tablosu ve CRUD
- [ ] XP kazanma servisi
- [ ] Level hesaplama logic'i
- [ ] Mevcut ritual tamamlamaya XP ekleme

### Sprint 2: Arkadaşlık Sistemi (3-4 gün)
- [ ] friendships tablosu API'leri
- [ ] Kullanıcı arama endpoint'i
- [ ] Flutter arkadaş ekranları
- [ ] Arkadaş bildirimleri

### Sprint 3: Ritual Paylaşımı (4-5 gün)
- [ ] shared_rituals & ritual_partners API'leri
- [ ] Davet kodu oluşturma/doğrulama
- [ ] Partner streak takibi
- [ ] Ritual visibility (public/private)
- [ ] Flutter paylaşım UI

### Sprint 4: Badge & Freeze (3-4 gün)
- [ ] Badge tanımları seed data
- [ ] Badge kazanma logic'i
- [ ] Freeze sistemi API
- [ ] Flutter badge koleksiyon UI

### Sprint 5: Leaderboard & Bildirimler (3-4 gün)
- [ ] Leaderboard API'leri
- [ ] Bildirim sistemi (in-app)
- [ ] Flutter leaderboard UI
- [ ] Flutter bildirim UI
- [ ] Push notification entegrasyonu

### Sprint 6: Polish & Test (2-3 gün)
- [ ] UI/UX iyileştirmeleri
- [ ] Edge case'ler
- [ ] Performance optimizasyonu
- [ ] Test senaryoları

**Toplam Tahmini Süre: 3-4 hafta**

---

## 📝 Notlar

1. **Coin satışı** şimdilik devre dışı, sadece kazanma var
2. **Grup ritualleri** gelecek versiyonda eklenecek
3. **Private ritualler** kesinlikle paylaşılamaz
4. **Leaderboard'da** kullanıcı adı gösterilir
5. **XP → Coin dönüşümü** yok

---

## 🔗 İlgili Dosyalar

### Backend
- `backend/src/scripts/initGamification.ts` - Migration script
- `backend/src/routes/gamificationRoutes.ts` - API routes
- `backend/src/controllers/gamificationController.ts` - Controllers
- `backend/src/services/xpService.ts` - XP & Level logic

### Flutter
- `lib/features/gamification/` - Gamification screens
- `lib/services/gamification_service.dart` - API client
- `lib/data/models/user_profile.dart` - Profile model
