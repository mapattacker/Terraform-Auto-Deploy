locals {
  SOURCE_ECR = "sassy19a/dummy-flask"
  DEST_ECR   = aws_ecr_repository.this.name
  S3         = aws_s3_bucket.this.bucket
}


resource "null_resource" "push_image" {
  depends_on = [aws_ecr_repository.this]
  provisioner "local-exec" {
    command = <<-EOT
        aws ecr get-login-password --region ${local.AWS_REGION} | docker login --username AWS --password-stdin ${local.AWS_ACCOUNT}.dkr.ecr.${local.AWS_REGION}.amazonaws.com
        docker pull ${local.SOURCE_ECR}
        docker tag ${local.SOURCE_ECR} ${local.AWS_ACCOUNT}.dkr.ecr.${local.AWS_REGION}.amazonaws.com/${local.DEST_ECR}:latest
        docker push ${local.AWS_ACCOUNT}.dkr.ecr.${local.AWS_REGION}.amazonaws.com/${local.DEST_ECR}:latest
    EOT
  }
}

resource "null_resource" "upload_artefacts" {
  depends_on = [aws_s3_bucket.this]
  provisioner "local-exec" {
    command = <<-EOT
        aws s3 cp scripts/deployment.yml s3://${local.S3}
        aws s3 cp scripts/docker-compose.yml s3://${local.S3}
    EOT
  }
}
