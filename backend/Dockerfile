# Node.js resmi imajını kullan (LTS sürümü)
FROM node:18-alpine

# Çalışma dizinini ayarla
WORKDIR /app

# Package dosyalarını kopyala
COPY package*.json ./

# Bağımlılıkları yükle
RUN npm install

# Kaynak kodları kopyala
COPY . .

# TypeScript'i derle (Eğer build scriptin varsa)
# RUN npm run build 

# Uygulamanın çalışacağı portu belirt
EXPOSE 3000

# Uygulamayı başlat
CMD ["npm", "run", "dev"]
