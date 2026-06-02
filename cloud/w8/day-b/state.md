# Terraform State

## State là gì?

State là cơ chế Terraform dùng để ghi nhớ hạ tầng đã tạo.

File mặc định:

```text
terraform.tfstate
```

---

## State lưu những gì?

Ví dụ:

```text
aws_s3_bucket.demo
→ tf-demo-bucket
```

State lưu:

- Resource ID
- Attributes
- Outputs
- Metadata

---

## Vì sao cần State?

Terraform phải biết:

- Resource nào đã tồn tại
- Resource nào cần tạo mới
- Resource nào cần sửa

Nếu không có State, Terraform sẽ không biết mình đã tạo gì trước đó.

---

## Refresh

Trước mỗi lần Plan hoặc Apply:

Terraform sẽ đọc:

```text
main.tf
↕
terraform.tfstate
↕
AWS thực tế
```

Sau đó tính toán sự khác biệt.

---

## Drift là gì?

Drift xảy ra khi hạ tầng thực tế bị thay đổi ngoài Terraform.

Ví dụ:

Cấu hình:

```text
Env = dev
```

AWS thực tế:

```text
Env = production
```

Terraform sẽ phát hiện sự khác biệt này.

---

## Idempotent

Nếu chạy:

```bash
terraform apply
```

nhiều lần với cùng cấu hình:

Terraform sẽ không tạo thêm resource mới.

Kết quả:

```text
No changes.
```

---

## Các lệnh State

Liệt kê resource:

```bash
terraform state list
```

Xem chi tiết:

```bash
terraform state show aws_s3_bucket.demo
```

Xem toàn bộ state:

```bash
terraform show
```

---

## Lưu ý

State có thể chứa:

- Password
- Endpoint
- Resource ID
- Secret

Không nên commit State lên GitHub.