#!/bin/bash

sudo apt update && sudo apt upgrade -y
sudo apt install unzip 

# install AWS to push to S3 bucket
echo "Installing AWS CLI..."
cd ~
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo unzip -q awscliv2.zip && sudo ./aws/install
rm -rf awscliv2.zip aws/

# Upgrade packages and install SteamCMD
sudo add-apt-repository multiverse -y && sudo dpkg --add-architecture i386 && sudo apt update && sudo apt install -y steamcmd

# Create install directory and install/update Rust server
mkdir -p ~/rust/server && /usr/games/steamcmd +@sSteamCmdForcePlatformType linux +force_install_dir $HOME/rust/server +login anonymous +app_update 258550 +quit

# Write the Rust systemd service
sudo tee /etc/systemd/system/rustserver.service > /dev/null <<EOF
[Unit]
Description=Rust Dedicated Server
Wants=network-online.target
After=network-online.target

[Service]
Environment=SteamAppId=258550
Environment=LD_LIBRARY_PATH=$HOME/rust/server:\$LD_LIBRARY_PATH
Type=simple
TimeoutSec=900
Restart=on-failure
RestartSec=10
KillSignal=SIGINT
User=ubuntu
Group=ubuntu
WorkingDirectory=$HOME/rust/server
ExecStartPre=/usr/games/steamcmd +@sSteamCmdForcePlatformType linux +force_install_dir $HOME/rust/server +login anonymous +app_update 258550 +quit
ExecStart=$HOME/rust/server/RustDedicated -batchmode \\
    +server.port 28015 \
    +server.level "Procedural Map" \
    +server.seed 11112222 \
    +server.worldsize 4000 \
    +server.maxplayers 5 \
    +server.hostname "Megabytten Rust" \
    +server.description "Megabytten server" \
    +server.identity "ubuntu" \
    +rcon.port 28016 \
    +rcon.password "" \\
    +rcon.web 1

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start the Rust server
sudo systemctl daemon-reload
sudo systemctl enable rustserver
sudo systemctl start rustserver

# Monitor service
# journalctl -u rustserver -f
