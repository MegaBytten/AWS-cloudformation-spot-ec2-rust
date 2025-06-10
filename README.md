# TODO
* Currently does not pull server data from S3 in Bootstrap script
* Move bootstrap.sh into first-time setup section
* Insert bootstrap script into infrastructure.yaml



## Uploading server files to S3

``` sh
BUCKET="bucket-name"
BACKUP_NAME="rust_backup_$(date +%F).tar.gz"

cd ~/rust/server

sudo tar czf "$BACKUP_NAME" server cfg HarmonyMods
sudo aws s3 cp "$BACKUP_NAME" "s3://$BUCKET/backups/$BACKUP_NAME"
sudo aws s3 cp "$BACKUP_NAME" "s3://$BUCKET/backups/latest.tar.gz"

rm "$BACKUP_NAME"
```


# Rust configuration settings
* 4000 mapsize = 9gb initial load