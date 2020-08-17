# Create a new instance of the latest Ubuntu 14.04 on an
# t2.micro node with an AWS Tag naming it "HelloWorld"
provider "aws" {
  access_key = "AKIAU3KROSIMGJMHICXM" //saurabh@accurics.com
  secret_key = "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"
  region = "ca-central-1" //Canada
}

# Create a VPC to launch our instances into
resource "aws_vpc" "acqa-test-vpc1" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "acqa-test-vpc1"
    ACQAResource = "true"
    Owner = "ACQA"
    Drift = "One"
  }
}

# Create a security group with most of the vulnerabilities
resource "aws_security_group" "acqa-test-securitygroup1" {
  name        = "acqa-test-securitygroup1"
  description = "This security group is for API test automation"
  vpc_id      = aws_vpc.acqa-test-vpc1.id

  tags = {
    Name = "acqa-test-securitygroup1"
    ACQAResource = "true"
    Owner = "ACQA"
  }

  # SSH access from anywhere..
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/24"]
  }


  # HTTP access from the VPC - changed
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/24"]
  }

  ingress {
    to_port     = 3306
    from_port   = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/24"]
  }
  
  # Drift 2
  ingress {
    to_port     = 3333
    from_port   = 3333
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/24"]
  }
  
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/24"]
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "acqa-test-gateway1" {
  vpc_id = aws_vpc.acqa-test-vpc1.id
  tags = {
    Name = "acqa-test-gateway1"
    ACQAResource = "true"
  }
}

# # Grant the VPC internet access on its main route table
# resource "aws_route" "acqa-test-route1" {
#   route_table_id         = aws_vpc.acqa-test-vpc1.main_route_table_id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.acqa-test-gateway1.id
# }

# Create a subnet to launch our instances into
resource "aws_subnet" "acqa-test-subnet1" {
  vpc_id                  = aws_vpc.acqa-test-vpc1.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "acqa-test-subnet1"
    ACQAResource = "true"
  }
}

# # Setup ebs encryption
# resource "aws_ebs_encryption_by_default" "acqa-test-ebs1" {
#   enabled = false
# }

# # Filter AMI for the ec2 instance
# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["099720109477"] # Canonical
# }

# # Create EC2 instance
# resource "aws_instance" "acqa-test-instance1" {
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = "t2.micro"
#   subnet_id    = aws_subnet.acqa-test-subnet1.id
#   instance_initiated_shutdown_behavior  = "stop"
#   vpc_security_group_ids = ["${aws_security_group.acqa-test-securitygroup1.id}"]
#   subnet_id = aws_subnet.acqa-test-subnet1.id
#   tags = {
#     Name = "acqa-test-instance1"
#     ACQAResource = "true"
#   }
# }

# Create network interface
resource "aws_network_interface" "acqa-test-networkinterface1" {
  subnet_id       = aws_subnet.acqa-test-subnet1.id
  private_ips     = ["10.0.0.50"]
  security_groups = [aws_security_group.acqa-test-securitygroup1.id]

  # attachment {
  #   instance     = aws_instance.acqa-test-instance1.id
  #   device_index = 1
  # }
  tags = {
    Name = "acqa-test-networkinterface1"
    ACQAResource = "true"
  }
}

# Get the userID for s3 bucket
data "aws_canonical_user_id" "current_user" {}

# Create S3 bucket
resource "aws_s3_bucket" "acqa-test-s3bucket1" {
  bucket = "acqa-test-s3bucket1"

  grant {
    id          = data.aws_canonical_user_id.current_user.id
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
  }

  grant {
    type        = "Group"
    permissions = ["READ", "WRITE"]
    uri         = "http://acs.amazonaws.com/groups/s3/LogDelivery"
  }
  tags = {
    Name = "acqa-test-s3bucket1"
    ACQAResource = "true"
  }
}

# Create IAM role for lamda
resource "aws_iam_role" "acqa-test-iamrole1" {
  name = "acqa-test-iamrole1"

  tags = {
    Name = "acqa-test-iamrole1"
    ACQAResource = "true"
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Create lambda function
resource "aws_lambda_function" "acqa-test-lambda1" {
  tags = {
    Name = "acqa-test-lambda1"
    ACQAResource = "true"
  }

  filename      = "acqa-test-lambda1.zip"
  function_name = "acqa-test-lambda1"
  role          = aws_iam_role.acqa-test-iamrole1.arn
  handler       = "exports.test"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("acqa-test-lambda1.zip")

  runtime = "nodejs12.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}