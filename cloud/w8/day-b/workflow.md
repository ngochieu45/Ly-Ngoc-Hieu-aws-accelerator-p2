# Terraform Workflow

## Terraform hoạt động như thế nào?

Terraform hoạt động theo vòng đời:

Write → Init → Plan → Apply → Destroy

---

## 1. Write

Viết file cấu hình Terraform.

Ví dụ:

```hcl
resource "aws_s3_bucket" "demo" {
  bucket = "my-demo-bucket"
}
```

---

## 2. terraform init

Khởi tạo project Terraform.

```bash
terraform init
```

Chức năng:

- Tải Provider
- Tạo thư mục .terraform
- Tạo file .terraform.lock.hcl

Init chỉ cần chạy khi:

- Tạo project mới
- Thêm provider mới
- Thay đổi version provider

---

## 3. terraform plan

```bash
terraform plan
```

Terraform sẽ:

1. Đọc file .tf
2. Đọc terraform.tfstate
3. Đọc trạng thái thực tế trên AWS
4. So sánh để tính toán thay đổi

Ký hiệu:

+ Create
~ Update
- Destroy

Plan không tạo resource.

---

## 4. terraform apply

```bash
terraform apply
```

Terraform sẽ:

- Chạy plan
- Xin xác nhận
- Gọi API AWS
- Tạo/Sửa/Xóa resource
- Cập nhật State

---

## 5. terraform destroy

```bash
terraform destroy
```

Xóa toàn bộ resource Terraform đang quản lý.

---

## known after apply

Ví dụ:

```text
bucket_arn = (known after apply)
```

Terraform chưa biết giá trị này vì AWS chỉ sinh ra sau khi resource được tạo.