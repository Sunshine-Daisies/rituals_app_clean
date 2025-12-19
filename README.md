# 🌱 Personalized Daily Rituals App

> **Flutter**, **Node.js/Express**, **PostgreSQL** ve **OpenAI API** kullanılarak geliştirilmiş kapsamlı bir alışkanlık takip ve ritüel yönetimi uygulaması.

---

## 📋 İçindekiler

- [Proje Genel Bakış](#-proje-genel-bakış)
- [Teknoloji Yığını](#-teknoloji-yığını)
- [Desteklenen Platformlar](#-desteklenen-platformlar)
- [Temel Özellikler](#-temel-özellikler)
- [Mimari Yapı](#-mimari-yapı)
- [Kurulum Rehberi](#-kurulum-rehberi)
- [API Dokümantasyonu](#-api-dokümantasyonu)
- [Geliştirici Rehberi](#-geliştirici-rehberi)
- [Katkıda Bulunma](#-katkıda-bulunma)

---

## 🚀 Proje Genel Bakış

Bu uygulama kullanıcıların:

- 📅 **Günlük ritüeller** oluşturmasına ve yönetmesine (sabah/akşam rutinleri, alışkanlıklar vb.)
- 🤖 **Yapay zeka chatbot** ile doğal dilde ritüel eklemesine/düzenlemesine (OpenAI GPT-4o)
- 📧 **E-posta doğrulama** ile güvenli kimlik doğrulama yapmasına
- 📊 **İstatistikler ve seriler** ile ilerlemeyi takip etmesine
- 🎮 **Oyunlaştırma sistemi** ile motivasyon sağlamasına (XP, seviye, rozet)
- 👥 **Sosyal özellikler** ile arkadaşlarıyla etkileşime girmesine

olanak tanır.

---

## 🛠 Teknoloji Yığını

### Frontend (Mobil & Web)

| Kategori | Teknoloji | Versiyon |
|----------|-----------|----------|
| **Dil** | Dart | SDK ^3.8.1 |
| **Framework** | Flutter | Latest Stable |
| **State Management** | Riverpod | ^2.5.1 |
| **Navigasyon** | GoRouter | ^14.2.3 |
| **Bildirimler** | flutter_local_notifications | ^17.2.2 |
| **Firebase** | firebase_core, firebase_messaging | ^2.27.0 |
| **Grafikler** | fl_chart | ^0.68.0 |
| **AI Entegrasyonu** | dart_openai | ^5.1.0 |
| **HTTP İstemci** | http | ^1.2.2 |
| **Yerel Depolama** | shared_preferences | ^2.2.3 |

### Backend (REST API)

| Kategori | Teknoloji | Versiyon |
|----------|-----------|----------|
| **Dil** | TypeScript | ^5.4.5 |
| **Runtime** | Node.js | ≥18.0.0 |
| **Framework** | Express.js | ^4.19.2 |
| **Veritabanı** | PostgreSQL | 15 (pg ^8.11.5) |
| **Kimlik Doğrulama** | JWT | jsonwebtoken ^9.0.2 |
| **Şifreleme** | bcryptjs | ^3.0.3 |
| **E-posta** | Nodemailer | ^7.0.10 |
| **AI/LLM** | OpenAI API | ^6.14.0 |
| **Push Bildirimleri** | Firebase Admin SDK | ^12.7.0 |
| **Zamanlayıcı** | node-cron | ^3.0.3 |
| **API Dokümantasyonu** | Swagger | swagger-jsdoc ^6.2.8 |

### DevOps

| Araç | Kullanım |
|------|----------|
| **Docker** | Konteynerizasyon |
| **Docker Compose** | Konteyner orkestrasyonu |

---

## 📱 Desteklenen Platformlar

| Platform | Durum | Notlar |
|----------|-------|--------|
| ✅ **Android** | Destekleniyor | APK ve AAB build |
| ✅ **Web** | Destekleniyor | PWA desteği |
| ⏳ **iOS** | Planlı | Gelecek sürümlerde |
| ⏳ **Desktop** | Planlı | Windows/macOS/Linux |

---

## 🔑 Temel Özellikler

### 🔐 Kimlik Doğrulama
- E-posta ile kayıt ve giriş
- E-posta doğrulama sistemi
- Şifremi unuttum akışı
- JWT tabanlı oturum yönetimi

### 📋 Ritüel Yönetimi
- CRUD işlemleri (oluştur, oku, güncelle, sil)
- Adım adım ritüel tanımlama
- Hatırlatıcı zamanlama (saat ve gün bazlı)
- Ritüel arşivleme

### ✅ Checklist Modu
- Adım adım ritüel tamamlama
- İlerleme takibi
- Geri alma özelliği

### 💬 AI Chatbot
- Doğal dilde ritüel oluşturma
- Intent çıkarımı (JSON formatında)
- GPT-4o ve GPT-4o-mini desteği
- Kullanım kotası takibi

### 📊 İstatistikler
- Seri (streak) takibi
- Günlük/haftalık/aylık raporlar
- Görsel grafikler (fl_chart)

### 🎮 Oyunlaştırma
- XP (deneyim puanı) sistemi
- Seviye atlama
- Rozet kazanma
- Liderlik tablosu

### 👥 Sosyal Özellikler
- Arkadaş ekleme/çıkarma
- Partner ritüelleri
- Ritüel paylaşımı
- Bildirim sistemi

### 🔔 Bildirimler
- Push bildirimleri (FCM)
- Yerel bildirimler
- Hatırlatıcı zamanlama
- Bildirim geçmişi

---

## 🏗 Mimari Yapı

### Genel Bakış

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Frontend                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Features  │  │   Services  │  │   Data Models       │  │
│  │   (Ekranlar)│  │   (API)     │  │   (Domain)          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└────────────────────────────┬────────────────────────────────┘
                             │ HTTP/REST
┌────────────────────────────▼────────────────────────────────┐
│                     Node.js Backend                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Routes    │  │ Controllers │  │   Services          │  │
│  │   (API)     │  │ (İş Mantığı)│  │   (DB & 3rd Party)  │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└────────────────────────────┬────────────────────────────────┘
                             │ SQL
┌────────────────────────────▼────────────────────────────────┐
│                     PostgreSQL 15                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────────┐  │
│  │  users   │ │ profiles │ │ rituals  │ │ partnerships   │  │
│  └──────────┘ └──────────┘ └──────────┘ └────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Frontend Klasör Yapısı

```
lib/
├── main.dart              # Uygulama giriş noktası
├── config/                # Uygulama yapılandırması
├── core/
│   ├── exceptions/        # Özel hata sınıfları
│   └── utils/             # Logger, yardımcı fonksiyonlar
├── data/
│   └── models/            # Domain modelleri
│       ├── ritual.dart
│       ├── user_profile.dart
│       ├── sharing_models.dart
│       └── ...
├── features/              # Feature modülleri
│   ├── auth/              # Giriş, kayıt, hoşgeldin
│   ├── home/              # Ana dashboard
│   ├── rituals/           # Ritüel listesi
│   ├── ritual_detail/     # Ritüel detayı
│   ├── ritual_create/     # Ritüel oluşturma
│   ├── checklist/         # Adım adım tamamlama
│   ├── chat/              # AI chatbot
│   ├── profile/           # Kullanıcı profili
│   ├── friends/           # Arkadaşlar
│   ├── stats/             # İstatistikler
│   ├── badges/            # Rozetler
│   ├── leaderboard/       # Lider tablosu
│   ├── sharing/           # Paylaşım
│   └── notifications/     # Bildirimler
├── routes/                # GoRouter navigasyon
├── services/              # API servisleri
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── rituals_service.dart
│   └── ...
├── theme/                 # Tema tanımları
└── widgets/               # Paylaşılan widget'lar
```

### Backend Klasör Yapısı

```
backend/src/
├── index.ts               # Express uygulama giriş noktası
├── config/
│   ├── db.ts              # PostgreSQL bağlantısı
│   └── swagger.ts         # API dokümantasyonu
├── controllers/           # Route handler'ları
│   ├── authController.ts
│   ├── ritualsController.ts
│   ├── gamificationController.ts
│   └── ...
├── routes/                # API route tanımları
│   ├── authRoutes.ts
│   ├── ritualsRoutes.ts
│   └── ...
├── services/              # İş mantığı katmanı
│   ├── badgeService.ts
│   ├── xpService.ts
│   ├── LlmService.ts
│   └── ...
├── middleware/
│   └── authMiddleware.ts  # JWT doğrulama
├── scripts/               # Veritabanı scriptleri
└── types/                 # TypeScript tipleri
```

---

## 🔧 Kurulum Rehberi

### Gereksinimler

| Araç | Versiyon | Zorunlu |
|------|----------|---------|
| Docker Desktop | Latest | ✅ Evet |
| Flutter SDK | 3.8+ | ✅ Evet |
| Git | Latest | ✅ Evet |
| OpenAI API Key | - | ⚠️ AI özellikleri için |
| Gmail App Password | - | ⚠️ E-posta için |

### 1. Projeyi Klonlama

```bash
git clone https://github.com/[username]/rituals_app.git
cd rituals_app
```

### 2. Backend Kurulumu (Docker ile)

```bash
# Backend klasörüne girin
cd backend

# Docker konteynerlerini başlatın
docker-compose up --build

# (Yeni terminal) İlk seferde veritabanını kurun
docker-compose exec api npx ts-node src/scripts/initDb.ts

# Gamification tablolarını kurun
docker-compose exec api npx ts-node src/scripts/initGamification.ts
```

> ✅ Backend artık `http://localhost:3000` adresinde çalışıyor!
> 📖 API dokümantasyonu: `http://localhost:3000/docs`

### 3. Frontend Kurulumu (Flutter)

```bash
# Ana dizine dönün
cd ..

# Bağımlılıkları yükleyin
flutter pub get

# Uygulamayı başlatın
flutter run -d chrome    # Web için
flutter run -d android   # Android için
```

### 4. Ortam Değişkenleri

#### Backend (`.env`)

```env
DB_HOST=db
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=rituals_db
DB_PORT=5432
JWT_SECRET=your_super_secret_jwt_key
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_gmail_app_password
OPENAI_API_KEY=sk-your-openai-key
```

#### Frontend (`.env`)

```env
API_BASE_URL=http://localhost:3000/api
OPENAI_API_KEY=sk-your-openai-key
```

---

## 📚 API Dokümantasyonu

### Swagger UI

Backend çalışırken API dokümantasyonuna şu adresten erişebilirsiniz:

> **http://localhost:3000/docs**

### Ana API Endpoint'leri

| Endpoint | Metod | Açıklama |
|----------|-------|----------|
| `/api/auth/register` | POST | Yeni kullanıcı kaydı |
| `/api/auth/login` | POST | Kullanıcı girişi |
| `/api/auth/verify` | GET | E-posta doğrulama |
| `/api/rituals` | GET/POST | Ritüel listele/oluştur |
| `/api/rituals/:id` | PUT/DELETE | Ritüel güncelle/sil |
| `/api/ritual-logs` | GET/POST | Ritüel logları |
| `/api/profile` | GET/PUT | Kullanıcı profili |
| `/api/friends` | GET/POST | Arkadaş yönetimi |
| `/api/partnerships` | GET/POST | Partner ritüelleri |
| `/api/llm/chat` | POST | AI sohbet |
| `/api/notifications` | GET | Bildirim geçmişi |

### Kimlik Doğrulama

Tüm korumalı endpoint'ler JWT token gerektirir:

```http
Authorization: Bearer <your_jwt_token>
```

---

## 👨‍💻 Geliştirici Rehberi

### Kod Standartları

#### Dart/Flutter

- **Riverpod** ile state management
- `ConsumerWidget` / `ConsumerStatefulWidget` kullanımı
- **Equatable** ile immutable modeller
- `fromJson()` / `toJson()` / `copyWith()` pattern'i
- Merkezi tema (`AppTheme`) kullanımı

#### TypeScript/Node.js

- **Controller-Service** ayrımı
- Route'larda **Swagger JSDoc** yorumları
- **Express middleware** ile hata yönetimi
- **PostgreSQL** için raw SQL sorguları

### Git Commit Standartları

```
<tip>(<kapsam>): <kısa açıklama>

Örnekler:
feat(auth): google login eklendi
fix(rituals): streak hesaplama hatası düzeltildi
docs(readme): kurulum rehberi güncellendi
refactor(api): service katmanı ayrıldı
```

### Sık Kullanılan Komutlar

```bash
# Flutter analiz
flutter analyze

# Flutter test
flutter test

# Backend lokal geliştirme
cd backend && npm run dev

# Backend build
cd backend && npm run build

# Docker logları
docker-compose logs -f api
```

---

## 🤝 Katkıda Bulunma

1. Projeyi fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'feat: amazing feature eklendi'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

---

## 📄 Lisans

Bu proje özel kullanım içindir. Tüm hakları saklıdır.

---

## 📞 İletişim

Sorularınız için:
- **E-posta**: support@rituals.app
- **GitHub Issues**: [Yeni Issue Aç](https://github.com/[username]/rituals_app/issues)