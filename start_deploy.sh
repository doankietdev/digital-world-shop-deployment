#!/bin/bash

cleanup() {
  echo "Cleaning up..."
  docker rm -f tmp-proxy > /dev/null 2>&1
}

trap cleanup EXIT

if [ "$(id -u)" -ne 0 ]; then
    echo "This script needs to be run with root privileges."
    exit 1
fi

echo "Starting tmp-proxy..."
docker run -d \
  --name tmp-proxy \
  -p 80:80 \
  -v $(pwd)/nginx.tmp.conf:/etc/nginx/nginx.conf \
  -v $(pwd)/certbot/www:/var/www/certbot \
  nginx:latest

if [ $? -ne 0 ]; then
    echo "Failed to start tmp-proxy."
    exit 1
fi

echo "Running certbot to generate SSL certificate..."
docker run -it --rm \
  --name certbot \
  -v $(pwd)/certbot/conf:/etc/letsencrypt \
  -v $(pwd)/certbot/www:/var/www/certbot \
  certbot/certbot certonly --webroot -w /var/www/certbot --force-renewal --email doankietdev@gmail.com -d 178.128.209.229 --agree-tos

if [ $? -ne 0 ]; then
    echo "Error running certbot."
    exit 1
fi

echo "Starting Docker Compose services..."
docker-compose up -d

if [ $? -ne 0 ]; then
    echo "Error starting Docker Compose services."
    exit 1
fi

echo "Process completed. SSL certificate generated, tmp-proxy removed, and Docker Compose services started."
