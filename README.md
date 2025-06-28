This project i designed contains the source code and infrastructure as code for deploying a scalable and resilient multi-tier architecture on AWS using Terraform for automating.

![Alt text](images/My-AWS-Architeture-Diagram1.drawio.png)

Project Overview
This project enables the deployment of a highly available, scalable, and secure multi-tier architecture on Amazon Web Services (AWS) using Terraform. The architecture is organized into three main layers:

Web Tier: Responsible for handling incoming user requests, this tier typically includes web servers paired with a load balancer to distribute traffic efficiently. It can be horizontally scaled to accommodate increased demand. 🌐⚖️

Application Tier: This layer runs the core business logic through application servers, which communicate with the database tier. Like the web tier, it supports horizontal scaling to handle varying workloads. 🧠🔄

Database Tier: Serving as the backbone for data storage and management, this tier utilizes Amazon RDS to provide a fully managed and reliable database service. 🗄️🔐