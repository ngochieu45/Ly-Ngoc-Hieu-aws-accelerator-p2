# W8-D1: Terraform Fundamentals

## Vấn đề Terraform giải quyết

Khi quản lý hạ tầng bằng cách thao tác thủ công trên AWS Console sẽ gặp các vấn đề:

- Không thể tái tạo môi trường một cách chính xác.
- Dễ xảy ra configuration drift (cấu hình thực tế khác với thiết kế ban đầu).
- Khó review thay đổi trước khi triển khai.
- Khó theo dõi lịch sử thay đổi.

Terraform giải quyết các vấn đề này bằng cách áp dụng Infrastructure as Code (IaC).

---

# Infrastructure as Code (IaC)

Infrastructure as Code là phương pháp mô tả hạ tầng bằng code thay vì thao tác thủ công.

Lợi ích:

- Có thể lưu trữ trên Git.
- Dễ tái sử dụng.
- Dễ review qua Pull Request.
- Dễ khôi phục và tái tạo môi trường.
- Giảm sai sót khi triển khai.

---

# Terraform là gì?

Terraform là công cụ Infrastructure as Code do HashiCorp phát triển.

Terraform cho phép:

- Định nghĩa hạ tầng bằng file cấu hình.
- Quản lý nhiều nền tảng:
  - AWS
  - Azure
  - GCP
  - Kubernetes
  - GitHub
  - Cloudflare

Terraform hoạt động theo mô hình Declarative:

Thay vì mô tả từng bước thực hiện, chỉ cần mô tả trạng thái mong muốn của hệ thống.

---

# Ba khái niệm quan trọng

## Provider

Provider là plugin giúp Terraform giao tiếp với dịch vụ bên ngoài.

Ví dụ:

- AWS Provider
- Azure Provider
- Kubernetes Provider

Terraform Core không hiểu AWS, toàn bộ việc gọi API AWS được thực hiện thông qua Provider.

---

## Resource

Resource là đơn vị hạ tầng mà Terraform quản lý.

Ví dụ:

- aws_instance
- aws_s3_bucket
- aws_security_group
- aws_vpc

Mỗi resource tương ứng với một tài nguyên thực tế trên cloud.

---

## State

State là file Terraform dùng để ghi nhớ hạ tầng đã được tạo.

Terraform sử dụng state để:

- Biết resource nào đã tồn tại.
- So sánh cấu hình hiện tại với thực tế.
- Tính toán thay đổi cần thực hiện.

File mặc định:

```text
terraform.tfstate
```

---

# Terraform Workflow

## 1. Write

Viết file cấu hình Terraform.

```hcl
resource "aws_s3_bucket" "demo" {
  bucket = "demo-bucket"
}
```

---

## 2. Plan

Xem trước thay đổi.

```bash
terraform plan
```

Terraform sẽ hiển thị:

- Resource nào được tạo.
- Resource nào bị sửa.
- Resource nào bị xóa.

---

## 3. Apply

Triển khai hạ tầng.

```bash
terraform apply
```

Terraform sẽ thực hiện các thay đổi đã được duyệt.

---

## 4. Destroy

Xóa hạ tầng.

```bash
terraform destroy
```

---

# Terraform Architecture

Terraform gồm 3 thành phần chính:

```text
Terraform Core
        ↓
Provider
        ↓
Cloud API (AWS)
```

## Terraform Core

Chịu trách nhiệm:

- Đọc file .tf
- Đọc State
- Xây dựng dependency graph
- Tính toán execution plan

## Provider

Chịu trách nhiệm:

- Gọi API thực tế
- Tạo/Sửa/Xóa resource trên AWS

## State

Lưu thông tin resource đã được tạo để Terraform quản lý ở các lần chạy tiếp theo.

---

# Các lệnh Terraform cơ bản

## Khởi tạo project

```bash
terraform init
```

Tải provider và chuẩn bị môi trường.

---

## Kiểm tra cấu hình

```bash
terraform validate
```

Kiểm tra cú pháp và tính hợp lệ.

---

## Xem trước thay đổi

```bash
terraform plan
```

---

## Triển khai

```bash
terraform apply
```

---

## Xóa hạ tầng

```bash
terraform destroy
```

---

## Format code

```bash
terraform fmt
```

Chuẩn hóa định dạng file Terraform.

---

# HCL (HashiCorp Configuration Language)

HCL là ngôn ngữ cấu hình được Terraform sử dụng.

Đặc điểm:

- Dễ đọc.
- Dễ viết.
- Mang tính khai báo (Declarative).

Ví dụ:

```hcl
resource "aws_s3_bucket" "demo" {
  bucket = "terraform-demo-bucket"
}
```

---

# Các thành phần cơ bản của HCL

## Block

```hcl
resource "aws_instance" "web" {

}
```

Cấu trúc:

```hcl
resource "<type>" "<name>" {

}
```

---

## Argument

```hcl
instance_type = "t2.micro"
```

Cấu trúc:

```hcl
key = value
```

---

## String

```hcl
region = "ap-southeast-1"
```

---

## Number

```hcl
volume_size = 20
```

---

## Boolean

```hcl
publicly_accessible = false
```

---

## List

```hcl
availability_zones = [
  "ap-southeast-1a",
  "ap-southeast-1b"
]
```

---

## Map

```hcl
tags = {
  Name = "web-server"
  Env  = "dev"
}
```

---

# tóm tắt kiến thức về terraform cơ bản

- Terraform là công cụ Infrastructure as Code.
- Terraform sử dụng HCL để mô tả hạ tầng.
- Provider dùng để giao tiếp với cloud platform.
- Resource là tài nguyên được Terraform quản lý.
- State lưu trạng thái hạ tầng hiện tại.
- Workflow cơ bản:
  - terraform init
  - terraform plan
  - terraform apply
  - terraform destroy
- Terraform Core tính toán thay đổi.
- Provider thực hiện lời gọi API.
- HCL hỗ trợ String, Number, Boolean, List và Map.