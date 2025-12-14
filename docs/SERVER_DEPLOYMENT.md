# Server Deployment Guide

## Kendi Bilgisayarı Server Olarak Kullanma

### 1. Port Forward (Router Ayarı) ⚠️ GEREKLİ
Router'da port 3000'i dışarıya açmak için:

```
Router Admin Panel (192.168.1.1 veya 192.168.0.1)
→ Port Forwarding / Virtual Server / NAT
→ External Port: 3000
→ Internal IP: 192.168.1.128 (local bilgisayar IP)
→ Internal Port: 3000
→ Protocol: TCP
→ Service Name: Rituals API
```

### 2. Public IP Bulma
```powershell
# Public IP öğren
$publicIp = Invoke-RestMethod -Uri "https://api.ipify.org"
Write-Host "Public IP: $publicIp"
```

### 3. Cloudflare DNS Ayarı
Domain'de DNS record oluştur:
```
Type: A
Name: api
Content: PUBLIC_IP_ADRESI (yukarıdaki komuttan)
Proxy: ❌ (ilk başta kapalı)
TTL: Auto
```

### 4. Test Komutları
```powershell
# Port forward test (telefon internetinden)
Invoke-RestMethod -Uri "http://PUBLIC_IP:3000/api/badges"

# Domain test
Invoke-RestMethod -Uri "https://api.senindomain.com/api/badges"
```

### 5. Flutter URL Güncelleme
```dart
// api_service.dart, gamification_service.dart, friends_service.dart
static const String _productionUrl = 'https://api.senindomain.com/api';

// Production modda kullanım
static String get baseUrl {
  if (kDebugMode) {
    // Development
    if (kIsWeb) return 'http://localhost:3000/api';
    return 'http://192.168.1.128:3000/api';
  } else {
    // Production
    return 'https://api.senindomain.com/api';
  }
}
```

### 6. Dynamic IP Problemi Çözümü
IP adresi değişirse otomatik güncelleme için:

```bash
# DDNS script (cron job)
#!/bin/bash
CURRENT_IP=$(curl -s https://api.ipify.org)
CLOUDFLARE_API_TOKEN="your_token"
ZONE_ID="your_zone_id"
RECORD_ID="your_record_id"

curl -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
     -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"api","content":"'$CURRENT_IP'"}'
```

---

## Alternatif Çözümler

### 1. Oracle Cloud (Ücretsiz VPS)
- Always Free Tier: 1 vCPU, 1GB RAM
- Kalıcı ücretsiz
- Ubuntu 22.04 + Docker

### 2. Railway Deploy
```powershell
npm install -g @railway/cli
cd backend
railway init
railway up
```

### 3. Ngrok (Geçici Test)
```powershell
winget install ngrok.ngrok
ngrok http 3000
# https://abc123.ngrok-free.app → localhost:3000
```

---

## Dikkat Edilecekler ⚠️

| Risk | Açıklama | Çözüm |
|------|----------|--------|
| **Güvenlik** | Bilgisayar internete açık | Firewall + güçlü şifreler |
| **Uptime** | PC kapalı = API down | VPS alternatifsz kullan |
| **Dynamic IP** | ISP IP değiştirebilir | DDNS script |
| **Bandwidth** | Upload hızı yeterli mi? | ISP planını kontrol et |

---

## Router Markaları Port Forward Yolları

### TP-Link
```
Advanced → NAT Forwarding → Port Forwarding
```

### D-Link
```
Advanced → Port Forwarding
```

### ASUS
```
Adaptive QoS → Port Forwarding
```

### ZyXEL/TTNet
```
Network → NAT → Port Forwarding
```

---

## Backend .env Production Ayarları

```env
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://postgres:postgres@db:5432/rituals_db
JWT_SECRET=strong_production_secret_here
EMAIL_USER=ritualsapp01@gmail.com
EMAIL_PASS=xyle_cmgd_mnnr_pxrf
BACKEND_URL=https://api.senindomain.com
```

---

## Implementation Checklist

- [ ] Router port forward ayarı
- [ ] Public IP bulma
- [ ] Cloudflare DNS record
- [ ] Flutter production URL güncelleme
- [ ] SSL sertifikası (Cloudflare Proxy)
- [ ] Backend .env production ayarları
- [ ] Dynamic IP monitoring script
- [ ] Security hardening (firewall, fail2ban)

---

*Hazırlayan: GitHub Copilot*  
*Tarih: 1 Aralık 2025*