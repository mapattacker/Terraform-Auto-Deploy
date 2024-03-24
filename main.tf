locals {
  resource_name = "${var.division}-${var.project_code}-${var.purpose}"
}


# ========== Create ECR ==========

resource "aws_ecr_repository" "this" {
  name = "ecr-${local.resource_name}"
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 7 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 7
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}


# ========== Create S3 ==========

resource "aws_s3_bucket" "this" {
  bucket = "s3-${local.resource_name}"
}


# ========== Create EC2 ==========

resource "aws_instance" "ec2" {
  ami                  = data.aws_ami.ubuntu22x86.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  security_groups      = [aws_security_group.this.id]
  iam_instance_profile = "AmazonSSMRoleForInstancesQuickSetup"
  user_data            = file("userdata/ubuntu.sh")

  root_block_device {
    volume_size = var.ebs_volume
  }
}

data "aws_ami" "ubuntu22x86" {
  most_recent = true
  owners      = ["amazon"]
  # https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
  filter {
    name   = "name"
    values = ["*hvm-ssd/ubuntu-jammy-22.04-amd64-server*"]
  }
}

resource "aws_security_group" "this" {
  name   = "tf-sg-${local.resource_name}"
  vpc_id = var.vpc_id

  ingress {
    # http access in
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    # https access in
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    # full access out
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# ========== Create Cloudwatch Log Group ==========

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/ssm/runcommand/logs"
  retention_in_days = 30
}