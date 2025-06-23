#!/bin/bash

###################################
###### --- CONFIGURATION --- ######
###################################
SERVER_IDENTITY="server2"
SEED="890123456789"
MAX_PLAYERS="5"
MAP_SIZE="3500"
RCON_PASSWORD="password"
SERVER_PW="password"
HOSTNAME="My Rust Server"

# install AWS to push to S3 bucket
echo "Installing AWS CLI..."
cd ~
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo unzip -q awscliv2.zip && sudo ./aws/install
rm -rf awscliv2.zip aws/

###################################
# --- ESSENTIAL INSTALLATIONS --- #
###################################
sudo apt update && sudo apt upgrade -y
sudo apt install unzip 

# Upgrade packages and install SteamCMD
sudo add-apt-repository multiverse -y && sudo dpkg --add-architecture i386 && sudo apt update && sudo apt install -y steamcmd

# Create install directory and install/update Rust server
mkdir -p ~/rust/server && /usr/games/steamcmd +@sSteamCmdForcePlatformType linux +force_install_dir $HOME/rust/server +login anonymous +app_update 258550 +quit

###################################
###### --- SERVER SETUP --- #######
###################################
# add owner and mod permissions via users.cfg permissions file
mkdir -p $HOME/rust/server/server/server2/cfg && sudo tee $HOME/rust/server/server/server2/cfg/users.cfg > /dev/null <<EOF
ownerid "76561198037342814" "Megabytten"
EOF

# Write the Rust systemd service
# touch /home/ubuntu/rust/server/rustserverlog.txt
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
ExecStart=$HOME/rust/server/RustDedicated -batchmode +server.identity "${SERVER_IDENTITY}" +server.port 28015 +server.level "Procedural Map" +server.seed "${SEED}" +server.worldsize "${MAP_SIZE}" +server.maxplayers "${MAX_PLAYERS}" +server.saveinterval 150 +rcon.port 28016 +rcon.password "${RCON_PASSWORD}" +rcon.web 1 +server.password "${SERVER_PW}" +server.hostname "${HOSTNAME}" +decay.upkeep false -logfile /home/ubuntu/rust/server/rustserverlog.txt

[Install]
WantedBy=multi-user.target
EOF

# install OXIDE
wget https://github.com/OxideMod/Oxide.Rust/releases/latest/download/Oxide.Rust-linux.zip -O oxide.zip && unzip oxide.zip -d oxide-temp
cp -r oxide-temp/* $HOME/rust/server/
rm -rf oxide.zip oxide-temp

# Installing mods
mkdir -p $HOME/rust/server/oxide/plugins/ 
wget --no-clobber \
    -P "$HOME/rust/server/oxide/plugins" \
    https://umod.org/plugins/MagicLoot.cs \
    https://umod.org/plugins/GatherManager.cs

# Reload systemd and start the Rust server for server file generation
sudo systemctl daemon-reload
sudo systemctl enable rustserver
sudo systemctl start rustserver