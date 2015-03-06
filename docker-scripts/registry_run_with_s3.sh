# This script will start the Docker private registry image backed with an S3 bucket in the ICG-DEV AWS account
# Make sure to use a valid AWS key and secret that has rights to the S3 bucket.
# For now you MUST use verison 0.9.0 of the registry image due to a known bug: https://github.com/docker/docker-registry/issues/400
sudo docker run \
         -e SETTINGS_FLAVOR=s3 \
         -e AWS_BUCKET=icg-build-artifacts \
         -e STORAGE_PATH=/docker \
         -e AWS_KEY=<AWS_KEY_GOES_HERE> \
         -e AWS_SECRET=<AWS_SECRET_KEY_GOES_HERE> \
         -p 5000:5000 \
         -d \
         registry:0.9.0