#!/bin/bash

set -e

sudo mkdir -p /var/www/myapp
sudo chmod 777 /var/www/myapp


cat <<'EOF' > /var/www/myapp/index.js
const express = require('express');
const { MongoClient } = require('mongodb');

const username = 'marco';
const password = 'password';
const host = '10.0.1.10';
const port = '27017';
const database = 'admindb';

// Cadena de conexión a MongoDB (URI)
const uri = `mongodb://${username}:${password}@${host}:${port}/${database}`;
let stringMongoConection;

// Verificación de la conexión a MongoDB
async function checkMongoDBConnection() {
  try {
    const client = new MongoClient(uri);
    await client.connect();
    console.log('Conexión exitosa a MongoDB');
    stringMongoConection = `Mongo Conectado correctamente a: ${uri}`;
    await client.close();
  } catch (error) {
    console.error('Error al conectar a MongoDB:', error);
    stringMongoConection = `Error al conectar a MongoDB: ${error}`;
  }
}
checkMongoDBConnection();

// Crea una instancia de la aplicación Express
const app = express();

// Configura una ruta básica
app.get('/', (req, res) => {
  res.send(
    '|| Soy Marco Speranza ||\n' +
    `||${stringMongoConection}||`
  );
});

// Escucha en el puerto 3000
const puerto = 3000;
app.listen(puerto, () => {
  console.log(`El servidor está escuchando en el puerto ${puerto}`);
});
}
EOF

cat <<'EOF' > /var/www/myapp/package.json
{
  "name": "mi-aplicacion",
  "version": "1.0.0",
  "description": "Mi aplicación Node.js",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.17.1",
    "mongodb": "^4.1.0"
  },
  "author": "",
  "license": "ISC"
}
EOF

# Actualización de repositorios y paquetes
sudo apt update
sudo apt upgrade -y

# Instalación de Nginx y Node.js
sudo apt install -y nginx npm

# Instalar la versión deseada de Node.js (reemplaza con el comando correcto si es necesario)
curl -sL https://deb.nodesource.com/setup_18.x | sudo bash -
sudo apt install -y nodejs

# Instalación de los build essentials para la compilación de dependencias de Node.js
sudo apt install -y build-essential

# Instalar dependencias de Node.js, si es que tu aplicación las tiene
sudo chown ubuntu:ubuntu /var/www/myapp
cd /var/www/myapp
sudo npm install


# Configura el servicio de Node.js
echo "[Unit]
Description=Node.js Application
After=network.target

[Service]
ExecStart=/usr/bin/node /var/www/myapp/index.js
Restart=on-failure
User=ubuntu
Group=ubuntu
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
WorkingDirectory=/var/www/myapp

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/nodeapp.service


# Habilitar e iniciar el servicio Node.js
sudo systemctl enable nodeapp.service
sudo systemctl start nodeapp.service

# Configura Nginx como proxy inverso para Node.js
echo "server {
    listen 80;
    server_name [::]:80;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}" | sudo tee /etc/nginx/sites-available/default

#Enlaza la configuración de sitio disponible a los sitios habilitados y elimina el archivo default
# Elimina el enlace simbólico predeterminado si existe
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Reiniciar Nginx para aplicar la configuración
sudo systemctl restart nginx
