# 🚀 Proje Kurulum Rehberi

Bu proje Flutter (Frontend) ve Node.js (Backend) kullanılarak geliştirilmiştir. Veritabanı olarak PostgreSQL kullanılır.

---

## 📋 İçindekiler

1. [Gereksinimler](#gereksinimler)
2. [Backend Kurulumu (Docker)](#backend-kurulumu-docker-ile)
3. [Frontend Kurulumu (Flutter)](#frontend-flutter-kurulumu)
4. [Ortam Değişkenleri](#ortam-değişkenleri)
5. [Veritabanı Kurulumu](#veritabanı-kurulumu)
6. [Sorun Giderme](#sorun-giderme)
7. [Üretim Ortamı](#üretim-ortamı)

---

## 📦 Gereksinimler

| Araç | Versiyon | İndirme Linki |
|------|----------|---------------|
| Docker Desktop | Latest | [İndir](https://www.docker.com/products/docker-desktop/) |
| Flutter SDK | 3.8+ | [İndir](https://docs.flutter.dev/get-started/install) |
| Git | Latest | [İndir](https://git-scm.com/downloads) |
| VS Code (Önerilen) | Latest | [İndir](https://code.visualstudio.com/) |

### Önerilen VS Code Eklentileri

- Flutter
- Dart
- Docker
- Thunder Client (API testi için)

---

## 🖥️ Backend Kurulumu (Docker ile)

Arkadaşlarınızın bilgisayarında Node.js veya PostgreSQL kurulu olmasına gerek yoktur. Sadece Docker yeterlidir.

### Adım 1: Backend Klasörüne Gidin

```bash
cd backend
```

### Adım 2: Docker Konteynerlerini Başlatın

```bash
docker-compose up --build
```

Bu komut çalıştığında:
- ✅ PostgreSQL veritabanı ayağa kalkar (port: 5432)
- ✅ Node.js API sunucusu ayağa kalkar (port: 3000)
- ✅ Hot reload aktif olur (kod değişiklikleri anında yansır)

### Adım 3: Veritabanı Tablolarını Oluşturun (İlk seferde)

Yeni bir terminal açın ve şu komutları sırayla çalıştırın:

```bash
# Temel tabloları oluştur
docker-compose exec api npx ts-node src/scripts/initDb.ts

# Gamification tablolarını oluştur
docker-compose exec api npx ts-node src/scripts/initGamification.ts

# (Gerekirse) E-posta güncellemesi
docker-compose exec api npx ts-node src/scripts/updateDbForEmail.ts
```

### Adım 4: Kurulumu Doğrulayın

Tarayıcınızda şu adresleri açın:

| Adres | Açıklama |
|-------|----------|
| http://localhost:3000 | API sunucusu |
| http://localhost:3000/docs | Swagger API dokümantasyonu |

✅ "Rituals API Çalışıyor v1.4" mesajını görüyorsanız kurulum başarılı!

---

## 📱 Frontend (Flutter) Kurulumu

### Adım 1: Ana Dizine Dönün

```bash
cd ..
```

### Adım 2: Bağımlılıkları Yükleyin

```bash
flutter pub get
```

### Adım 3: Uygulamayı Çalıştırın

```bash
# Web için
flutter run -d chrome

# Android için (emülatör veya cihaz bağlı olmalı)
flutter run -d android

# Cihaz listesini görün
flutter devices
```

### Platform Özel Notlar

| Platform | Komut | Not |
|----------|-------|-----|
| Web | `flutter run -d chrome` | Chrome gerekli |
| Android | `flutter run -d android` | SDK kurulu olmalı |
| iOS | `flutter run -d ios` | macOS + Xcode gerekli |

---

## ⚙️ Ortam Değişkenleri

### Backend (.env)

`backend/.env` dosyasını oluşturun veya düzenleyin:

```env
# Veritabanı
DB_HOST=db
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=rituals_db
DB_PORT=5432

# JWT
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production

# E-posta (Gmail)
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_gmail_app_password

# OpenAI API
OPENAI_API_KEY=sk-your-openai-api-key

# Server
PORT=3000

# Firebase (Push Notifications)
# firebase-service-account.json dosyasını backend/ dizinine koyun
```

### Frontend (.env)

Proje kök dizininde `.env` dosyası zaten mevcuttur:

```env
API_BASE_URL=http://localhost:3000/api
OPENAI_API_KEY=sk-your-openai-api-key
```

### Gmail App Password Alma

1. Google hesabınıza gidin: https://myaccount.google.com/
2. Güvenlik → 2 Adımlı Doğrulama'yı aktifleştirin
3. Güvenlik → Uygulama Şifreleri → Yeni şifre oluşturun
4. Oluşturulan 16 haneli şifreyi `EMAIL_PASS` olarak kullanın

---

## 🗄️ Veritabanı Kurulumu

### Manuel Tablo Oluşturma

Eğer scriptler çalışmazsa, veritabanına doğrudan bağlanabilirsiniz:

```bash
# PostgreSQL container'ına bağlan
docker-compose exec db psql -U postgres -d rituals_db
```

### Veritabanını Sıfırlama

```bash
# Tüm konteynerleri durdur ve sil
docker-compose down -v

# Yeniden başlat
docker-compose up --build

# Tabloları yeniden oluştur
docker-compose exec api npx ts-node src/scripts/initDb.ts
```

### Veritabanı Yedekleme

```bash
# Yedek al
docker-compose exec db pg_dump -U postgres rituals_db > backup.sql

# Yedekten geri yükle
cat backup.sql | docker-compose exec -T db psql -U postgres -d rituals_db
```

---

## 🔧 Sorun Giderme

### ❌ "Port 3000 already in use"

```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# macOS/Linux
lsof -i :3000
kill -9 <PID>
```

### ❌ "Cannot connect to database"

1. Docker Desktop'ın çalıştığından emin olun
2. Konteynerleri yeniden başlatın:
   ```bash
   docker-compose down
   docker-compose up --build
   ```

### ❌ Android Emülatör localhost'a bağlanamıyor

Android emülatör `localhost` yerine `10.0.2.2` adresini kullanır. `lib/config/app_config.dart` dosyasında bu ayar yapılmıştır.

```dart
// Emülatör için
static const String androidEmulatorUrl = 'http://10.0.2.2:3000/api';

// Fiziksel cihaz için (aynı ağda)
static const String physicalDeviceUrl = 'http://192.168.x.x:3000/api';
```

### ❌ Firebase Hatası

Push bildirimleri için Firebase yapılandırması gereklidir:
1. Firebase Console'da proje oluşturun
2. `google-services.json` dosyasını `android/app/` dizinine koyun
3. `firebase-service-account.json` dosyasını `backend/` dizinine koyun

### ❌ Flutter Build Hatası

```bash
# Cache temizle
flutter clean

# Bağımlılıkları yeniden yükle
flutter pub get

# Tekrar dene
flutter run
```

---

## 🚀 Üretim Ortamı

### Backend Deployment (Railway)

1. Railway hesabı oluşturun: https://railway.app/
2. GitHub repo'nuzu bağlayın
3. Ortam değişkenlerini ayarlayın
4. Deploy edin

### Frontend Build

```bash
# Web için
flutter build web

# Android APK
flutter build apk --release

# Android App Bundle (Play Store için)
flutter build appbundle --release
```

### Güvenlik Kontrol Listesi

- [ ] `JWT_SECRET` değiştirildi mi?
- [ ] E-posta şifresi güvenli mi?
- [ ] CORS origin'leri kısıtlandı mı?
- [ ] HTTPS aktif mi?
- [ ] Rate limiting var mı?

---

## 📞 Destek

Sorunlarınız için:
- GitHub Issues açın
- Dokümantasyonu kontrol edin: `docs/` klasörü
- Swagger API: http://localhost:3000/docs

