
# AWS-cloudformation-spot-ec2-rust
A preconfigured Cloudformation template and user-data (bootstrap) script to launch an Ubuntu-based Rust server (with mod compatability) within minutes. Runs on 75-90% price-reduced EC2 spot instances, Ubuntu 22.04 LTS.
# Infrastructure Intro

## Bootstrap script
This is the most important aspect of the deployment to understand. EC2 by default only runs the bootstrap script (user-data script) once at server procurement. For a persistent spot request, this is NOT re-run when restarting the server, or when starting a `stopped` instance. The bootstrap script therefore writes a `systemd service, rustserver` which is enabled and runs on every server boot.

### Monitoring systemd rustserver.service
Normally, systemd services' logs can be viewed through `journalctl` command: `journalctl -u rustserver -f`

However, Rust provides a -logfile option when calling the RustDedicated server, which I use in my bootstrap script. This means Rust server logs actually output to the file `/home/ubuntu/rust/server/rustserverlog.txt`. **Monitor the server through the following command**:
```sh
tail -n 50 -f /home/ubuntu/rust/server/rustserverlog.txt
```

## EC2 Spot Instance
ri7.large was chosen. 8GB sometimes failed to successfully load maps >3000, so 16GB is the safest and most secure, cheapest instance type which supports spot instances and x86_64 Ubuntu. 

## Persistent Spot request
The CFN will make a persistent spot request, which means off-demand pricing (75-90% reduction), although your server/workload may be interrupted when demand for EC2 returns. I found that there was limited demand between 12am-2am daily, possibly due to large organisations procuring ri7.large instances for business workloads. 

## Security group
Server requires TCP+UDP 28015, RCON requires TCP+UDP 28016. Security group should therefore allow 28015-28016 for both TCP + UDP.

# Rust Server Config
Rust servers support 2 primary ways of loading parameters when executing the RustDedicated executable server. The way I have chosen is to hardcode the settings `+param.option "value"` acting as arguments to the command executing the RustDedicated. Secondly there is support for loading config from `server.cfg`, placed in your server-specific folder (alongside `serverauto.cfg`). I had inconsistent success with this, particularly re: RCON config - so I opted for the former option.

# Mods
The bootstrapping script will install uMod (formerly OXIDE) and two uMod mods (MagicLoot and GatherManager). These provide configuration .json files which allow us to make the server 2x, 3x, etc. Any mod can be installed into the `$HOME/rust/server/oxide/plugins` directory via uMod.

## Configuring Mods:
Make sure to run the rust server once with a successful connect after installing the mods, so that they can initialise their default `<mod name>.json` config files located in `$HOME/rust/server/oxide/config`. 

### GatherManager config
vim the config .json file for GatherManager, (or editor of choice): `vim $HOME/rust/server/oxide/config/GatherManager.json`, then modify the following objects: `GatherResourceModifiers, MiningQuarryResourceTickRate, PickupResourceModifiers, QuarryResourceModifiers, SurveyResourceModifiers`. See [GatherManager on uMod](https://umod.org/plugins/gather-manager) for more.

```JSON
{
  ...,
  "Options": {
    ...,
    "GatherResourceModifiers": {
      "*": 2.0
    },
    "MiningQuarryResourceTickRate": 5.0,
    "PickupResourceModifiers": {
      "*": 2.0
    },
    "QuarryResourceModifiers": {
      "*": 2.0
    },
    "SurveyResourceModifiers": {
      "*": 2.0
    }
  },
  ...
}
```

### MagicLoot config
Same process as for GatherManager, edit the config .json file. `cat $HOME/rust/server/oxide/config/MagicLoot.json`. See [MagicLoot on uMod](https://umod.org/plugins/magic-loot) for more.
```JSON
{
  "General Settings": {
    "General Item List Multiplier (All items in the 'Manual Item Multipliers' List)": 2.0,
    ...
  },
  ...
}
```

# Server Backups
Running a server on an EC2 instance means the data is stored on a single disk. In case of disk failure or termination, backups of the server are recommended. S3 provides arguably cheapest object storage. As the AWS CLI is installed in the bootstrap script:
1. SSH into the EC2 server
2. Ensure the EC2 instance has the S3_fullaccess role created in the rust_server.infrastructure.yaml file
3. Configure and run the following bash commands

``` sh
BUCKET="bucket-name"
BACKUP_NAME="rust_backup_$(date +%F).tar.gz"

cd ~/rust/server

sudo tar czf "$BACKUP_NAME" server cfg HarmonyMods
sudo aws s3 cp "$BACKUP_NAME" "s3://$BUCKET/backups/$BACKUP_NAME"
sudo aws s3 cp "$BACKUP_NAME" "s3://$BUCKET/backups/latest.tar.gz"

rm "$BACKUP_NAME"
```