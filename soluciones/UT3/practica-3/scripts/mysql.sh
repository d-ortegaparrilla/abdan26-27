#!/bin/bash
# =====================================================================
#  user_data del ServidorMySQL  (SOLUCIÓN - Práctica 3.3)
#  Instala MySQL 9.7 LTS, restaura Sakila y crea el usuario remoto
# =====================================================================
set -eux

# --- Preparación para un script no interactivo -----------------------
export DEBIAN_FRONTEND=noninteractive
echo 'DPkg::Lock::Timeout "300";' > /etc/apt/apt.conf.d/99-lock-timeout

ROOT_PASS='Root_Robusta_123'
REMOTO_PASS='Contraseña_Robusta_123'

cd /tmp

# --- 1. Actualizar la lista de paquetes ------------------------------
apt-get update

# --- 2. Repositorio oficial de MySQL sin asistente -------------------
debconf-set-selections <<EOF
mysql-apt-config mysql-apt-config/select-server select mysql-9.7-lts
mysql-apt-config mysql-apt-config/select-product select Ok
mysql-community-server mysql-community-server/root-pass password ${ROOT_PASS}
mysql-community-server mysql-community-server/re-root-pass password ${ROOT_PASS}
EOF

wget https://dev.mysql.com/get/mysql-apt-config_0.8.36-1_all.deb
dpkg -i mysql-apt-config_0.8.36-1_all.deb

# --- 3. Instalar el servidor MySQL -----------------------------------
apt-get update
apt-get install -y mysql-server

# --- 4. Descargar Sakila y restaurar esquema y datos -----------------
wget https://downloads.mysql.com/docs/sakila-db.tar.gz
tar -xzf sakila-db.tar.gz
mysql -u root -p"$ROOT_PASS" < sakila-db/sakila-schema.sql
mysql -u root -p"$ROOT_PASS" < sakila-db/sakila-data.sql

# --- 5. Crear el usuario remoto --------------------------------------
mysql -u root -p"$ROOT_PASS" -e "
  CREATE USER 'remoto'@'%' IDENTIFIED BY '${REMOTO_PASS}';
  GRANT ALL PRIVILEGES ON sakila.* TO 'remoto'@'%';
"

echo "=== ServidorMySQL listo ==="
