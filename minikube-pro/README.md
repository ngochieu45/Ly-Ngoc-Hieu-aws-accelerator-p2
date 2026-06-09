# Minikube on AWS - Infrastructure as Code

Dự án này triển khai một ứng dụng Minikube trên AWS EC2 với Application Load Balancer (ALB) sử dụng Terraform.

## 📋 Mục lục
- [Kiến trúc hệ thống](#kiến-trúc-hệ-thống)
- [Yêu cầu](#yêu-cầu)
- [Cách wire Provider](#cách-wire-provider)
- [Hướng dẫn triển khai](#hướng-dẫn-triển-khai)
- [Kiểm tra ứng dụng](#kiểm-tra-ứng-dụng)
- [Dọn dẹp tài nguyên](#dọn-dẹp-tài-nguyên)

## 🏗️ Kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│                    Region: ap-southeast-1                        │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   VPC (10.0.0.0/16)                         │ │
│  │                                                              │ │
│  │  ┌─────────────────────┐   ┌─────────────────────┐        │ │
│  │  │  Public Subnet 1    │   │  Public Subnet 2    │        │ │
│  │  │  10.0.1.0/24        │   │  10.0.2.0/24        │        │ │
│  │  │  AZ: 1a             │   │  AZ: 1b             │        │ │
│  │  │                     │   │                     │        │ │
│  │  │  ┌──────────────┐   │   │                     │        │ │
│  │  │  │              │   │   │                     │        │ │
│  │  │  │  EC2 t3.medium  │   │                     │        │ │
│  │  │  │  (Minikube)  │   │   │                     │        │ │
│  │  │  │  Port: 30080 │   │   │                     │        │ │
│  │  │  │              │   │   │                     │        │ │
│  │  │  └───────┬──────┘   │   │                     │        │ │
│  │  │          │          │   │                     │        │ │
│  │  └──────────┼──────────┘   └─────────────────────┘        │ │
│  │             │                                               │ │
│  │             │              ┌─────────────────────┐         │ │
│  │             └──────────────┤                     │         │ │
│  │                            │  Application LB     │         │ │
│  │                            │  Port: 80           │         │ │
│  │                            │  (Target: 30080)    │         │ │
│  │                            └──────────┬──────────┘         │ │
│  │                                       │                     │ │
│  └───────────────────────────────────────┼─────────────────────┘ │
│                                          │                       │
│                    ┌─────────────────────┼───────┐              │
│                    │  Internet Gateway   │       │              │
│                    └─────────────────────┼───────┘              │
└──────────────────────────────────────────┼───────────────────────┘
                                           │
                                           │
                                    ┌──────▼──────┐
                                    │   Internet  │
                                    │   Users     │
                                    └─────────────┘
```

### Thành phần chính:

1. **Network Layer (Module: network)**
   - VPC với CIDR: 10.0.0.0/16
   - 2 Public Subnets ở 2 AZ khác nhau (High Availability)
   - Internet Gateway để kết nối ra ngoài
   - Route Table cho public subnets

2. **Security Layer (Module: security_group)**
   - Security Group cho EC2: cho phép SSH (22), HTTP (30080) từ IP cụ thể
   - Security Group cho ALB: cho phép HTTP (80) từ Internet

3. **Compute Layer (Module: ec2)**
   - EC2 instance t3.medium chạy Amazon Linux 2023
   - Cài đặt Minikube và kubectl qua user_data script
   - SSH key được tạo tự động bằng TLS provider

4. **Load Balancer Layer (Module: alb)**
   - Application Load Balancer phân phối traffic
   - Target Group nhắm đến port 30080 của EC2
   - Health check endpoint: HTTP GET /

## 📦 Yêu cầu

- Terraform >= 1.5.0
- AWS CLI configured với credentials
- Quyền IAM đầy đủ để tạo VPC, EC2, ALB, Security Groups

## 🔌 Cách wire Provider

### 1. Khai báo Providers trong `provider.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    
    local = {
      source = "hashicorp/local"
    }
  }
}
```

**Giải thích:**
- **aws provider**: Quản lý tất cả tài nguyên AWS (VPC, EC2, ALB, Security Groups)
- **tls provider**: Tạo SSH key pair (private/public key) để truy cập EC2
- **local provider**: Lưu private key xuống file local (xbrain-key.pem)

### 2. Cách các Module sử dụng Provider

Terraform tự động kế thừa provider configuration từ root module xuống các child modules. Không cần khai báo lại provider trong từng module.

**Flow:**
```
root (provider.tf)
  ↓ AWS Provider được kế thừa
  ├─→ module "network" → tạo VPC, Subnets, IGW
  ├─→ module "security_group" → tạo Security Groups
  ├─→ module "ec2" → tạo EC2 instance
  └─→ module "alb" → tạo ALB, Target Group
```

### 3. Provider Configuration Variables

```hcl
variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}
```

Để chỉ định region cho AWS provider, bạn có thể:
- Cấu hình trong AWS CLI: `aws configure`
- Hoặc thêm provider block (tùy chọn):
  ```hcl
  provider "aws" {
    region = var.aws_region
  }
  ```

## 🚀 Hướng dẫn triển khai

### Bước 1: Khởi tạo Terraform

```bash
cd minikube-pro/project-1/terraform
terraform init
```

Lệnh này sẽ:
- Download các provider plugins (aws, tls, local)
- Khởi tạo backend
- Khởi tạo modules

### Bước 2: Xem kế hoạch triển khai

```bash
terraform plan
```

Xem trước các tài nguyên sẽ được tạo (VPC, EC2, ALB, Security Groups, v.v.)

### Bước 3: Triển khai infrastructure

```bash
terraform apply
```

- Nhập `yes` để xác nhận
- Quá trình triển khai mất khoảng 5-10 phút
- Sau khi hoàn tất, output sẽ hiển thị ALB DNS name

### Bước 4: Lấy thông tin ALB DNS

```bash
terraform output alb_dns_name
```

Hoặc xem trong output sau khi apply:
```
Outputs:
alb_dns_name = "main-alb-xxxxxxxxx.ap-southeast-1.elb.amazonaws.com"
```

## 🔍 Kiểm tra ứng dụng

### 1. Truy cập qua Browser

Mở browser và truy cập:
```
http://<ALB_DNS_NAME>
```

Ví dụ:
```
http://main-alb-1234567890.ap-southeast-1.elb.amazonaws.com
```

### 2. Chờ Health Check

- ALB cần 1-2 phút để health check EC2 instance
- EC2 instance cần 3-5 phút để cài đặt Minikube và deploy app

### 3. Xác minh thành công

Khi thành công, bạn sẽ thấy:
- Trang web của ứng dụng chạy Hello Xbrain x Aws

## 🧹 Dọn dẹp tài nguyên

### Xóa tất cả tài nguyên AWS

```bash
terraform destroy
```

- Nhập `yes` để xác nhận
- Terraform sẽ xóa tất cả tài nguyên theo thứ tự ngược lại:
  1. ALB Listener, Target Group Attachment
  2. Application Load Balancer
  3. EC2 Instance
  4. Security Groups
  5. Subnets, Route Tables
  6. Internet Gateway
  7. VPC

### Xác nhận đã xóa sạch

```bash
# Kiểm tra state file
terraform show

# Nếu còn resources, chạy lại
terraform destroy -auto-approve
```
