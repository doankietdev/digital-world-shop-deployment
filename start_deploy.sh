#!/bin/bash

# Check if the script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script needs to be run with root privileges."
    exit 1
fi

# Run tmp-proxy (nginx) to serve SSL certificates
echo "Starting tmp-proxy..."
docker run -d --name tmp-proxy -p 8080:80 -v $(pwd)/nginx.tmp.conf:/etc/nginx/nginx.conf nginx:latest

# Check if tmp-proxy started successfully
if [ $? -ne 0 ]; then
    echo "Failed to start tmp-proxy."
    exit 1
fi

# Run certbot to generate the SSL certificate
echo "Running certbot to generate SSL certificate..."
docker run -it --rm --name certbot \
  -v $(pwd)/certbot/conf:/etc/letsencrypt \
  -v $(pwd)/certbot/www:/var/www/certbot \
  certbot/certbot certonly --webroot -w /var/www/certbot --force-renewal --email doankietdev@gmail.com -d digitals.software --agree-tos

# Check if certbot completed successfully
if [ $? -ne 0 ]; then
    echo "Error running certbot."
    exit 1
fi

# Remove tmp-proxy after certbot completes
echo "Removing tmp-proxy..."
docker rm -f tmp-proxy

# Check if tmp-proxy was removed successfully
if [ $? -ne 0 ]; then
    echo "Failed to remove tmp-proxy."
    exit 1
fi

# Start docker-compose services
echo "Starting Docker Compose services..."
docker-compose up -d

# Check if Docker Compose services started successfully
if [ $? -ne 0 ]; then
    echo "Error starting Docker Compose services."
    exit 1
fi

echo "Process completed. SSL certificate generated, tmp-proxy removed, and Docker Compose services started."
