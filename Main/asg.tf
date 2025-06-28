locals {
  user_data = <<-EOT
#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
sudo usermod -a -G apache ec2-user
sudo chown -R ec2-user:apache /var/www
sudo chmod 2775 /var/www
sudo find /var/www -type d -exec chmod 2775 {} \\;
sudo find /var/www -type f -exec chmod 0664 {} \\;
echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/phpinfo.php
sudo yum install -y php-mbstring php-xml
sudo systemctl restart httpd
sudo systemctl restart php-fpm

cd /var/www/html
sudo wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
sudo mkdir phpMyAdmin
sudo tar -xvzf phpMyAdmin-latest-all-languages.tar.gz -C phpMyAdmin --strip-components 1
sudo rm phpMyAdmin-latest-all-languages.tar.gz
echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/phpinfo.php

cd phpMyAdmin
sudo mv config.sample.inc.php config.inc.php
sudo sed -i 's/localhost/${module.rds.db_instance_address}/g' config.inc.php

sudo dnf clean all
sudo dnf update -y

sudo dnf install -y java-17-amazon-corretto

java -version

sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

sudo dnf install -y jenkins

sudo systemctl enable jenkins
sudo systemctl start jenkins

sudo systemctl status jenkins
  EOT
}

################################################################################
# Supporting Resources
################################################################################

module "asg_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = var.asg_sg_name
  description = var.asg_sg_description
  vpc_id      = module.vpc.vpc_id


  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0" # 
    }
  ]

  egress_rules = ["all-all"]

  tags = var.asg_sg_tags
}

################################################################################
# Autoscaling scaling group (ASG)
################################################################################

# ASG for Public Subnets (with public IPs)
module "asg_public" {
  source = "terraform-aws-modules/autoscaling/aws"

  name                      = "${var.asg_name}-public"
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  wait_for_capacity_timeout = var.asg_wait_for_capacity_timeout
  health_check_type         = var.asg_health_check_type
  vpc_zone_identifier       = module.vpc.public_subnets
  user_data                 = base64encode(local.user_data)

  launch_template_name        = var.asg_launch_template_name
  launch_template_description = var.asg_launch_template_description
  update_default_version      = var.asg_update_default_version

  image_id          = var.asg_image_id
  instance_type     = var.asg_instance_type
  ebs_optimized     = var.asg_ebs_optimized
  enable_monitoring = var.asg_enable_monitoring

  create_iam_instance_profile = var.asg_create_iam_instance_profile
  iam_role_name               = var.asg_iam_role_name
  iam_role_path               = var.asg_iam_role_path
  iam_role_description        = var.asg_iam_role_description
  iam_role_tags               = var.asg_iam_role_tags
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = var.asg_block_device_mappings_volume_size_0
        volume_type           = "gp2"
      }
    },
    {
      device_name = "/dev/sda1"
      no_device   = 1
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = var.asg_block_device_mappings_volume_size_1
        volume_type           = "gp2"
      }
    }
  ]

  network_interfaces = [
    {
      delete_on_termination       = true
      description                 = "eth0"
      device_index                = 0
      security_groups             = [module.asg_sg.security_group_id]
      associate_public_ip_address = true
    },
  ]

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = var.asg_instance_tags
    },
    {
      resource_type = "volume"
      tags          = var.asg_volume_tags
    }
  ]

  tags = var.asg_tags
}

# ASG for Private Subnets (without public IPs)
module "asg_private" {
  source = "terraform-aws-modules/autoscaling/aws"

  name                      = "${var.asg_name}-private"
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  wait_for_capacity_timeout = var.asg_wait_for_capacity_timeout
  health_check_type         = var.asg_health_check_type
  vpc_zone_identifier       = module.vpc.private_subnets
  user_data                 = base64encode(local.user_data)

  launch_template_name        = var.asg_launch_template_name
  launch_template_description = var.asg_launch_template_description
  update_default_version      = var.asg_update_default_version

  image_id          = var.asg_image_id
  instance_type     = var.asg_instance_type
  ebs_optimized     = var.asg_ebs_optimized
  enable_monitoring = var.asg_enable_monitoring

  create_iam_instance_profile = var.asg_create_iam_instance_profile
  iam_role_name               = var.asg_iam_role_name
  iam_role_path               = var.asg_iam_role_path
  iam_role_description        = var.asg_iam_role_description
  iam_role_tags               = var.asg_iam_role_tags
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = var.asg_block_device_mappings_volume_size_0
        volume_type           = "gp2"
      }
    },
    {
      device_name = "/dev/sda1"
      no_device   = 1
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = var.asg_block_device_mappings_volume_size_1
        volume_type           = "gp2"
      }
    }
  ]

  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = [module.asg_sg.security_group_id]
      # No public IP here, so omit associate_public_ip_address or set false
    },
  ]

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = var.asg_instance_tags
    },
    {
      resource_type = "volume"
      tags          = var.asg_volume_tags
    }
  ]

  tags = var.asg_tags
}