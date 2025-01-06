#!/bin/bash

# Periksa file .env
check_env_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    echo "❌ File .env tidak ditemukan di $path!"
    echo "Silakan buat file .env atau salin dari .env.example:"
    echo "  cp $path.example $path"
    return 1
  else
    echo "✅ File .env ditemukan di $path."
    return 0
  fi
}

# Periksa file .env di ./web dan ./rasa
missing_env=0

check_env_file "./web/.env" || missing_env=1
check_env_file "./rasa/.env" || missing_env=1

# Jika ada file .env yang tidak ditemukan, keluar dengan kode 1
if [ $missing_env -eq 1 ]; then
  echo "❌ File .env tidak lengkap. Perbaiki dan jalankan ulang script ini."
  exit 1
else
  echo "✔️ File .env ditemukan. Melakukan penggabungan..."
  cat ./web/.env ./rasa/.env > ./.env
fi

# Pastikan Node.js terpasang
echo "Memeriksa apakah Node.js terpasang..."
if ! command -v node &> /dev/null; then
  echo "❌ Node.js tidak ditemukan!"
  echo "Pastikan Node.js sudah terinstal dengan benar."
  exit 1
else
  echo "✔️ Node.js ditemukan."
fi

# Pastikan Docker Compose terpasang
echo "Memeriksa apakah Docker Compose terpasang..."
if ! command -v docker compose &> /dev/null; then
  echo "❌ Docker Compose tidak ditemukan!"
  echo "Pastikan Docker Compose sudah terinstal dengan benar."
  exit 1
else
  echo "✔️ Docker Compose ditemukan."
fi

# Jalankan Migrasi Database
echo "Melakukan migrasi database..."
cd ./web
node ace migration:run
if [ $? -ne 0 ]; then
  echo "❌ Terjadi kesalahan saat melakukan migrasi database."
  exit 1
else
  echo "✔️ Langlah Migrasi Selesai."
fi

# Jalankan Docker Compose dengan file .env
echo "Menjalankan container dengan file .env..."
cd ../
docker compose --env-file ./.env up -d
if [ $? -ne 0 ]; then
  echo "❌ Terjadi kesalahan saat menjalankan Docker Compose."
  exit 1
else
  echo "✔️ Docker Compose berhasil dijalankan."
fi
