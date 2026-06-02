# Terraform Best Practices

## Local State

Mặc định:

```text
terraform.tfstate
```

được lưu trên máy cá nhân.

Điều này phù hợp khi học tập hoặc làm việc một mình.

---

## Remote State

Khi làm việc theo nhóm:

State nên được lưu trên S3.

Ví dụ:

```text
s3://terraform-state-prod
```

Lợi ích:

- Chia sẻ State
- Backup dễ dàng
- Tránh mất dữ liệu

---

## State Lock

Nếu hai người cùng chạy:

```text
Dev A → terraform apply
Dev B → terraform apply
```

State có thể bị lỗi.

Giải pháp:

- DynamoDB Lock
- S3 Lockfile (Terraform mới)

---

## Không commit State

Không push:

```text
terraform.tfstate
terraform.tfstate.backup
```

Lý do:

- Có dữ liệu nhạy cảm
- Có Password
- Có Resource ID

---

## terraform fmt

Format code Terraform.

```bash
terraform fmt
```

Nên chạy trước khi commit.

---

## terraform validate

Kiểm tra cú pháp.

```bash
terraform validate
```

Giúp phát hiện lỗi sớm.

---

## Pin Version

Nên chỉ định version Provider.

Ví dụ:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

Giúp tránh lỗi khi Provider nâng cấp.

---

## Quy trình nên dùng

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

Đây là workflow phổ biến trong các dự án thực tế.