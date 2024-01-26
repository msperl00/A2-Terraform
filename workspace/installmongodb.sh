#!/bin/bash

set -e
# Con set -x se ven todos los camandos

sudo apt-get update
sudo apt-get install curl -y
sudo apt-get install gnupg -y

# Añadir la clave GPG
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg

# Añadir el repositorio de MongoDB
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org

# Establecer el dueño y el grupo de las carpetas db y log
sudo chown -R mongodb:mongodb /var/lib/mongodb

# Reiniciar el servicio de mongod para aplicar la nueva configuración
sudo service mongod start
sudo service mongod status
echo "Esperando a que mongod responda..."
sleep 15s

# Crear usuario con la contraseña proporcionada como parámetro
if ! id "mongodb" &>/dev/null; then
    sudo useradd -r -s /bin/false mongodb
fi


# Usar mongosh para crear el usuario
mongosh --host localhost <<CREACION_DE_USUARIO
use admin
db.createUser({
  user: "marco",
  pwd: "password",
  roles: [
    { role: "root", db: "admin" },
    { role: "restore", db: "admin" }
  ]
})
CREACION_DE_USUARIO
echo "El usuario ha sido creado con éxito!"
exit 0