#!/bin/bash

# Ask if the user wants to start the script
read -p "Do you want to start the VPS setup script? (y/n): " start_script < /dev/tty

if [[ "$start_script" != "y" && "$start_script" != "Y" ]]; then
    echo "Setup aborted. Exiting..."
    exit 0
fi

# Update and upgrade system packages
apt update && apt upgrade -y
apt install -y curl wget git unzip net-tools ufw mc btop

# Setup a basic Firewall with ufw
ufw allow 22
ufw --force enable

# Set TimeZone
timedatectl set-timezone "Europe/Berlin"

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "Docker not found, installing..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm -f get-docker.sh
else
    echo
    echo "✅ Docker is already installed."
    echo
fi

mkdir -p /docker

# Ask if user wants to set up Dockge
read -p "Do you want to set up Dockge? (y/n): " setup_dockge < /dev/tty

if [[ "$setup_dockge" == "y" || "$setup_dockge" == "Y" ]]; then
    # Create required directories and files
    mkdir -p /dockge
    touch /dockge/compose.yaml

    # Create Docker Compose file
    cat << EOF > /dockge/compose.yaml
services:
  dockge:
    image: louislam/dockge:1
    restart: unless-stopped
    ports:
      - "5001:5001"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "./data:/app/data"
      - "/docker:/docker"
    environment:
      - DOCKGE_STACKS_DIR=/docker
EOF


    # Start Docker Compose service
    docker compose -f /dockge/compose.yaml up -d
    
    echo
    echo "✅ Dockge is spun up."
    echo 
    # Get the server's IP address
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
else
    echo
    echo "Skipped Dockge setup."
fi

# Ask if user wants to set up watchtower
read -p "Do you want to set up watchtower for automatic Docker updates? (y/n): " setup_watchtower < /dev/tty

if [[ "$setup_watchtower" == "y" || "$setup_watchtower" == "Y" ]]; then
    # Create required directories and files
    mkdir -p /docker/watchtower
    touch /docker/watchtower/compose.yaml

    # Create Docker Compose file
    cat << EOF > /docker/watchtower/compose.yaml 
services:
  watchtower:
    container_name: watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /etc/localtime:/etc/localtime
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_SCHEDULE=0 0 5 * * *
      - TZ=Europe/Berlin
    image: containrrr/watchtower
    restart: unless-stopped
EOF

    # Start Docker Compose service
    docker compose -f /docker/watchtower/compose.yaml up -d

    echo
    echo "✅ watchtower is spun up."
    echo 
    
else
    echo
    echo "Skipped watchtower setup."
fi

# Ask if user wants to set up tailscale
read -p "Do you want to set up tailscale? (y/n): " setup_tailscale < /dev/tty

if [[ "$setup_tailscale" == "y" || "$setup_tailscale" == "Y" ]]; then
    # Install Tailscale
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list
    apt update
    apt install tailscale
    tailscale up --accept-routes
    
else
    echo
    echo "Skipped tailscale setup."
fi

# Print final completion message
echo
echo "🎉 Setup Complete! 🎉"
echo
echo "🔥 Firewall is setup to only allow SSH Port (and Docker Ports)"
echo "⏱️ TimeZone is set to Europe/Berlin"
echo
if [[ "$setup_dockge" == "y" || "$setup_dockge" == "Y" ]]; then
    echo "🐳 Docker is installed and a Dockge instance spun up."
    echo "-> Reach Dockge at: http://${SERVER_IP}:5001"
    echo
else
    echo "🐳 Docker is installed."
    echo
fi
if [[ "$setup_watchtower" == "y" || "$setup_watchtower" == "Y" ]]; then
    echo "Watchtower is spun up and performs updates at 05:00 o'clock."
else
    echo
fi
if [[ "$setup_tailscale" == "y" || "$setup_tailscale" == "Y" ]]; then
    echo "Tailscale is running and connected."
else
    echo
fi