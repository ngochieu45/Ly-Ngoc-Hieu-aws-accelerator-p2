# Terraform Modules

## Vấn đề

Giả sử cần tạo:

- EC2 Dev
- EC2 Staging
- EC2 Production

Nếu không dùng Module:

```text
Copy → Paste → Copy → Paste
```

Code rất khó bảo trì.

---

## DRY Principle

DRY = Don't Repeat Yourself

Không nên lặp lại code.

---

## Module là gì?

Module là tập hợp các file Terraform có thể tái sử dụng.

Có thể xem Module giống Function trong lập trình.

---

## Cấu trúc Module

```text
modules/
└── ec2/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

---

## Sử dụng Module

```hcl
module "web" {
  source = "./modules/ec2"
}
```

Terraform sẽ sử dụng toàn bộ code trong thư mục module.

---

## Terraform Registry

Terraform có kho Module công khai:

https://registry.terraform.io

Ví dụ:

```text
terraform-aws-modules/vpc/aws
```

---

## Lợi ích của Module

- Reuse code
- Chuẩn hóa hạ tầng
- Dễ bảo trì
- Dễ mở rộng

---

## Khi nào nên dùng?

Khi thấy:

- Copy cùng một đoạn code nhiều lần
- Tạo nhiều môi trường giống nhau

→ Nên chuyển thành Module.