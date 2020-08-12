provider "aws" {
    region = "us-east-2"
    shared_credentials_file = pathexpand("~/.aws/mycreds")
    profile                 = "spamcap-acct"
}

resource "aws_s3_bucket" "spamcap" {
    bucket = "unique-bucket-name-spamcap"
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
            "Resource": [
                "arn:aws:s3:::unique-bucket-name-spamcap",
                "arn:aws:s3:::*/*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole",
                "iam:ListInstanceProfiles"
            ],
            "Resource": "arn:aws:s3:::unique-bucket-name-spamcap"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "spamcap" {
    name = "spamcap"
    roles = [aws_iam_role.spamcap.name]
    policy_arn = aws_iam_policy.spamcap.arn
}

resource "aws_iam_instance_profile" "spamcap" {
    name = "spamcap"
    role = aws_iam_role.spamcap.name
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

resource "aws_security_group" "allow_ssh" {
    name = "allow_ssh"
    description = "Allow SSH on port 22"
    vpc_id = "vpc-idherethisisnotareallid"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_security_group" "allow_smtp" {
    name = "allow_smtp"
    description = "Allow SMTP on port 25"
    vpc_id = "vpc-idherethisisnotareallid"

    ingress {
        from_port = 25
        to_port = 25
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_security_group" "allow_egress_all" {
    name = "allow_egress_all"
    description = "Allow all outbound traffic"
    vpc_id = "vpc-idherethisisnotareallid"

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "spamcap" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.nano"
    vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_smtp.id, aws_security_group.allow_egress_all.id]
    iam_instance_profile = aws_iam_instance_profile.spamcap.name
    key_name = "spamcap"
    subnet_id = "subnet-idherethisisnotarealid"

    tags = {
        Name = "spamcap"
    }


}

resource "aws_eip" "spamcap-eip" {
    instance = aws_instance.spamcap.id
    vpc      = true
    provisioner "local-exec" {
        command = "sleep 60; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ~/.ssh/spamcap-key.pem -i '${aws_eip.spamcap-eip.public_ip},' -e 'ansible_python_interpreter=/usr/bin/python3' spamcap.yml"
    }
}