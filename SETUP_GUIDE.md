# Proje Kurulum Rehberi

Bu proje Flutter (Frontend) ve Node.js (Backend) kullanılarak geliştirilmiştir. Veritabanı olarak PostgreSQL kullanılır.

## Gereksinimler

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Backend ve Veritabanı için)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Mobil uygulama için)

## 🚀 Backend Kurulumu (Docker ile)

Arkadaşlarınızın bilgisayarında Node.js veya PostgreSQL kurulu olmasına gerek yoktur. Sadece Docker yeterlidir.

1. **Backend klasörüne gidin:**
   ```bash
   cd backend
   ```

2. **Docker konteynerlerini başlatın:**
   ```bash
   docker-compose up --build
   ```
   Bu komut hem veritabanını hem de backend sunucusunu ayağa kaldırır.

3. **Veritabanı Tablolarını Oluşturun (İlk seferde):**
   Yeni bir terminal açın ve şu komutu çalıştırın:
   ```bash
   # Backend konteynerinin içine girip init scriptini çalıştırır
   docker-compose exec api npx ts-node src/scripts/initDb.ts
   
   # Email güncellemesi için (gerekirse)
   docker-compose exec api npx ts-node src/scripts/updateDbForEmail.ts
   ```

Backend artık `http://localhost:3000` adresinde çalışıyor!

---

## 📱 Frontend (Flutter) Kurulumu

1. **Ana dizine dönün:**
   ```bash
   cd ..
   ```

2. **Bağımlılıkları yükleyin:**
   ```bash
   flutter pub get
   ```

3. **Uygulamayı çalıştırın:**
   ```bash
   flutter run
   ```

## ⚠️ Önemli Notlar

- **Android Emülatör:** Emülatör `localhost` yerine `10.0.2.2` adresini kullanır. Kodda bu ayar yapılmıştır.
- **E-posta Ayarları:** `backend/src/services/emailService.ts` dosyasındaki Gmail bilgileri kişiseldir. Arkadaşlarınızın kendi Gmail App Password'lerini alıp oraya yazmaları gerekebilir.
