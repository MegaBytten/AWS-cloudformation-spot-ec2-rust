

## Uploading server files to S3
BUCKET=$("bucketname")
# Backup this current save to its own unique folder
DATESTAMP=$(date +"%Y%m%d")
sudo aws s3 sync ~/mcserver/ s3://$BUCKET/$DATESTAMP_$ARG1

# Update the s3://bucket /latest folder, overwriting any data.
sudo aws s3 sync ~/mcserver/ s3://$BUCKET/latest --delete