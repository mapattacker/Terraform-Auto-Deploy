data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  resource_name = "${var.division}-${var.project_code}-${var.purpose}"
  AWS_REGION    = data.aws_region.current.name
  AWS_ACCOUNT   = data.aws_caller_identity.current.account_id
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

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# ========== Instance Profile ==========

resource "aws_iam_instance_profile" "this" {
  name = "iamr-${local.resource_name}"
  role = aws_iam_role.this.name
}

resource "aws_iam_role" "this" {
  name               = "iamr-${local.resource_name}"
  assume_role_policy = file("policies/assume_role.json")

  inline_policy {
    name = "inline_policy"
    policy = templatefile("policies/inline_deploy.json",
      {
        s3             = aws_s3_bucket.this.bucket
        loggroup       = aws_cloudwatch_log_group.this.name
        aws_region     = local.AWS_REGION
        aws_account_id = local.AWS_ACCOUNT
        ecr            = aws_ecr_repository.this.name
      }
    )
  }
}

resource "aws_iam_role_policy_attachment" "attach_policy_ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}



# ========== Create EC2 ==========

# resource "aws_instance" "ec2" {
#   ami                  = data.aws_ami.ubuntu22x86.id
#   instance_type        = var.instance_type
#   subnet_id            = var.subnet_id
#   security_groups      = [aws_security_group.this.id]
#   iam_instance_profile = aws_iam_role.this.name
#   user_data            = templatefile("userdata/ubuntu.sh",
#       {
#         ECR = aws_ecr_repository.this.name
#       }
#     )

#   root_block_device {
#     volume_size = var.ebs_volume
#   }

#   tags = {
#     Name  = "vm-${local.resource_name}"
#     Patch = true
#   }
# }

# data "aws_ami" "ubuntu22x86" {
#   most_recent = true
#   owners      = ["amazon"]
#   # https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
#   filter {
#     name   = "name"
#     values = ["*hvm-ssd/ubuntu-jammy-22.04-amd64-server*"]
#   }
# }

# resource "aws_security_group" "this" {
#   name   = "tf-sg-${local.resource_name}"
#   vpc_id = var.vpc_id

#   ingress {
#     # http access in
#     protocol         = "tcp"
#     from_port        = 80
#     to_port          = 80
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   ingress {
#     # https access in
#     protocol         = "tcp"
#     from_port        = 443
#     to_port          = 443
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   egress {
#     # full access out
#     protocol         = "-1"
#     from_port        = 0
#     to_port          = 0
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }
# }

# ========== Create Cloudwatch Log Group ==========

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/ssm/runcommand/logs"
  retention_in_days = 30
}