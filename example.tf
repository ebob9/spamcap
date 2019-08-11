provider "aws" {
    region = "us-east-1"
}

resource "aws_s3_bucket" "spamcap" {
    bucket = "spamcap"
    acl = "public-read"
}

resource "aws_iam_role" "spamcap" {
    name = "spamcap"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "spamcap" {
    name = "spamcap"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": "${aws_s3_bucket.spamcap.arn}"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "spamcap" {
    name = "spamcap"
    roles = ["${aws_iam_role.spamcap.name}"]
    policy_arn = "${aws_iam_policy.spamcap.arn}"
}

resource "aws_iam_instance_profile" "spamcap" {
    name = "spamcap"
    role = "${aws_iam_role.spamcap.name}"
}

data "aws_ami" "ubuntu" {
    most_recent = true
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "allow_smtp" {
    name = "allow_smtp"
    description = "Allow SMTP on port 25"

    ingress {
        from_port = 22
        to_port = 25
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "spamcap" {
    ami = "${data.aws_ami.ubuntu.id}"
    instance_type = "t3.nano"
    security_groups = ["${aws_security_group.allow_smtp.name}"]
    iam_instance_profile = "${aws_iam_instance_profile.spamcap.name}"
    key_name = "AWSDefault"

    tags = {
        Name = "Spamcap"
    }
}