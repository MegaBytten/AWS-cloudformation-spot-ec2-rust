

## Uploading server files to S3

``` sh
BUCKET="bucket-name"
BACKUP_NAME="rust_backup_$(date +%F).tar.gz"

cd ~/rust/server

sudo tar czf "$BACKUP_NAME" server cfg HarmonyMods
sudo aws s3 cp "$BACKUP_NAME" "s3://$BUCKET/backups/$BACKUP_NAME"
```

# Update the s3://bucket /latest folder, overwriting any data.
sudo aws s3 sync ~/mcserver/ s3://$BUCKET/latest --delete