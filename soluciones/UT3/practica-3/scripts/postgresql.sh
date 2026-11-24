#!/bin/bash
# =====================================================================
#  user_data del ServidorPostgreSQL  (SOLUCIÓN - Práctica 3.3)
#  Instala Docker y levanta PostgreSQL 18 con Pagila mediante Compose
# =====================================================================
set -eux

# --- Preparación para un script no interactivo -----------------------
export DEBIAN_FRONTEND=noninteractive
echo 'DPkg::Lock::Timeout "300";' > /etc/apt/apt.conf.d/99-lock-timeout

PG_PASS='Contraseña_Robusta_123'
DIR=/home/ubuntu/postgres-compose

# --- 1. Docker, Docker Compose y git ---------------------------------
apt-get update
apt-get install -y docker.io docker-compose-v2 git

# --- 2. Clonar Pagila ------------------------------------------------
git clone https://github.com/devrimgunduz/pagila.git /home/ubuntu/pagila

# --- 3. Scripts de inicialización ------------------------------------
mkdir -p "$DIR/init_scripts"
cp /home/ubuntu/pagila/pagila-schema.sql "$DIR/init_scripts/01-pagila-schema.sql"
cp /home/ubuntu/pagila/pagila-data.sql   "$DIR/init_scripts/02-pagila-data.sql"

# --- 4. compose.yaml -------------------------------------------------
cat > "$DIR/compose.yaml" <<EOF
services:
  postgres:
    image: postgres:18
    container_name: postgres18-remoto
    environment:
      POSTGRES_PASSWORD: ${PG_PASS}
      POSTGRES_DB: pagila
    ports:
      - "5432:5432"
    restart: always
    volumes:
      # Carpeta para los datos de las BD
      - ./datos_postgres:/var/lib/postgresql
      # Carpeta para la auto-inicialización
      - ./init_scripts:/docker-entrypoint-initdb.d
EOF

# --- 5. Levantar el servicio -----------------------------------------
cd "$DIR"
docker compose up -d

echo "=== ServidorPostgreSQL listo ==="
