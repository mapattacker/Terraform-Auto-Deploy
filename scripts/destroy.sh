# delete S3 contents and ECR images
# else terraform cannot destroy ECR and S3

S3=s3-mydivision-deploytest-model
DEST_ECR=ecr-mydivision-deploytest-model

aws ecr batch-delete-image --repository-name ${DEST_ECR} --image-ids imageTag=latest
aws s3 rm s3://${S3} --recursive