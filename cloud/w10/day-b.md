# W10 - DAY 2: SECRETS ROTATION + SUPPLY CHAIN SECURITY

## MỤC TIÊU

Sau khi hoàn thành Day 2 cần hiểu:

* Secret là gì
* Tại sao không được hardcode secret
* AWS Secrets Manager hoạt động như thế nào
* Secret Rotation là gì
* External Secrets Operator (ESO)
* Supply Chain Security
* Supply Chain Attack
* Trivy Image Scanning
* CVE và Severity
* Cosign Image Signing
* Admission Verify Signature
* Exception Policy

---

# 1. VẤN ĐỀ CỦA SECRET

Hầu như mọi ứng dụng đều cần secret.

Ví dụ:

* Database Password
* API Key
* Access Token
* AWS Credential
* Certificate

---

Ví dụ Spring Boot:

```yaml
spring:
  datasource:
    username: admin
    password: admin123
```

---

Nếu commit lên Git:

```text
Git Repository
       ↓
Password bị lộ
```

---

Hacker chỉ cần:

```bash
git clone
```

là có thể xem toàn bộ credential.

---

Đây gọi là:

```text
Secret Leakage
```

---

# 2. TẠI SAO HARDCODE SECRET LÀ NGUY HIỂM?

Giả sử:

```yaml
password: admin123
```

---

Developer nghỉ việc.

Repository bị leak.

Screenshot bị gửi nhầm.

---

Khi đó:

```text
Password vẫn tồn tại
```

---

Nguyên tắc bảo mật:

```text
Code và Secret phải tách biệt
```

---

Không lưu:

```text
Secret trong source code
```

---

# 3. KUBERNETES SECRET

Kubernetes hỗ trợ:

```yaml
kind: Secret
```

---

Ví dụ:

```yaml
password: YWRtaW4xMjM=
```

---

Nhiều người nghĩ:

```text
Đã mã hóa
```

---

Thực tế:

```text
Base64 Encode
```

---

Có thể giải mã dễ dàng:

```bash
echo YWRtaW4xMjM= | base64 -d
```

---

Kết quả:

```text
admin123
```

---

Vì vậy:

```text
Kubernetes Secret
≠
Secret Manager
```

---

# 4. AWS SECRETS MANAGER

AWS Secrets Manager là dịch vụ quản lý secret tập trung.

Ví dụ:

```text
prod/mysql/password
```

---

AWS sẽ:

* Mã hóa bằng KMS
* Lưu version
* Audit bằng CloudTrail
* Hỗ trợ rotation

---

Ví dụ:

```text
Version 1
Password123
```

---

Sau 30 ngày:

```text
Version 2
NewPassword456
```

---

Ứng dụng không cần thay đổi code.

---

# 5. SECRET ROTATION

Mentor hỏi rất nhiều.

---

Giả sử password:

```text
admin123
```

được dùng suốt:

```text
2 năm
```

---

Nếu bị lộ:

```text
Hacker dùng mãi mãi
```

---

Secret Rotation:

```text
admin123
      ↓
abc456xyz
      ↓
new789xyz
      ↓
...
```

---

Password thay đổi định kỳ.

---

Mục tiêu:

```text
Giảm thời gian tồn tại của credential bị lộ
```

---

# 6. EXTERNAL SECRETS OPERATOR (ESO)

Vấn đề:

```text
Secret nằm ở AWS
```

Nhưng:

```text
Application chạy trong Kubernetes
```

---

Làm sao lấy secret vào cluster?

---

ESO giải quyết việc đó.

---

Luồng:

```text
AWS Secrets Manager
          ↓
External Secrets Operator
          ↓
Kubernetes Secret
          ↓
Pod
```

---

ESO liên tục đồng bộ dữ liệu.

---

Ví dụ:

```text
AWS Secret đổi password
```

↓

```text
ESO phát hiện
```

↓

```text
Update Kubernetes Secret
```

↓

```text
Pod sử dụng secret mới
```

---

# 7. REFRESH INTERVAL

Ví dụ:

```yaml
refreshInterval: 1m
```

---

Nghĩa là:

```text
1 phút kiểm tra Secret 1 lần
```

---

Mentor hay hỏi:

### Secret đổi ở AWS thì Kubernetes có tự cập nhật không?

Có.

Nhờ ESO.

---

# 8. SUPPLY CHAIN SECURITY

Ngày xưa:

```text
Developer
     ↓
Deploy
```

---

Ngày nay:

```text
Developer
     ↓
Git
     ↓
CI/CD
     ↓
Docker Build
     ↓
Registry
     ↓
Kubernetes
```

---

Mỗi bước đều có nguy cơ bị tấn công.

---

Đó gọi là:

```text
Software Supply Chain
```

---

# 9. SUPPLY CHAIN ATTACK

Ví dụ:

```docker
FROM nginx
```

---

Image gốc bị cài malware.

---

Pipeline:

```text
Build thành công
Deploy thành công
```

---

Nhưng:

```text
Malware đã vào cluster
```

---

Đây là:

```text
Supply Chain Attack
```

---

Ví dụ nổi tiếng:

* SolarWinds
* Codecov
* 3CX

---

# 10. TRIVY

Trivy là công cụ quét lỗ hổng.

---

Có thể quét:

* Docker Image
* Filesystem
* Repository
* Kubernetes

---

Ví dụ:

```text
my-api:v1
```

---

Trivy kiểm tra:

```text
openssl
curl
log4j
```

---

Có CVE hay không.

---

# 11. CVE

CVE:

```text
Common Vulnerabilities and Exposures
```

---

Mỗi lỗ hổng có mã riêng.

Ví dụ:

```text
CVE-2021-44228
```

(Log4Shell)

---

Severity:

```text
LOW
MEDIUM
HIGH
CRITICAL
```

---

# 12. TRIVY TRONG CI/CD

Luồng:

```text
Git Push
    ↓
CI Pipeline
    ↓
Docker Build
    ↓
Trivy Scan
    ↓
Deploy
```

---

Nếu phát hiện:

```text
CRITICAL
```

---

Pipeline:

```text
FAIL
```

---

Deploy bị chặn.

---

Mục tiêu:

```text
Chặn image nguy hiểm trước khi vào cluster
```

---

# 13. COSIGN

Câu hỏi:

```text
Làm sao biết image này do công ty tạo?
```

---

Cosign giải quyết.

---

Cosign dùng để:

```text
Ký điện tử Docker Image
```

---

Ví dụ:

```text
my-api:v1
```

↓

```text
Cosign Sign
```

↓

```text
Image + Signature
```

---

# 14. KEYLESS SIGNING

Cosign hỗ trợ:

```text
OIDC
```

---

Ví dụ:

```text
GitHub Actions
```

---

Không cần:

```text
Private Key
```

---

Workflow được xác thực.

---

Cosign tạo chữ ký.

---

Đây gọi là:

```text
Keyless Signing
```

---

# 15. ADMISSION VERIFY SIGNATURE

Hôm qua học:

```text
Admission Controller
```

---

Hôm nay:

```text
Admission Controller
          ↓
Verify Signature
```

---

Luồng:

```text
Deploy Image
      ↓
Admission
      ↓
Cosign Verify
      ↓
Allow / Deny
```

---

Nếu image chưa được ký:

```text
Admission Denied
```

---

Không được deploy.

---

# 16. EXCEPTION POLICY

Thực tế:

```text
Trivy phát hiện HIGH
```

---

Nhưng:

```text
Chưa có bản vá
```

---

Không thể dừng production.

---

Khi đó tạo:

```text
Exception Policy
```

---

Ví dụ:

```text
Cho phép CVE-2026-12345

Hết hạn:
14 ngày
```

---

Sau thời gian đó:

```text
Exception tự hết hiệu lực
```

---

# TÓM TẮT DAY 2

```text
AWS Secrets Manager
          ↓
External Secrets Operator
          ↓
Kubernetes Secret
          ↓
Pod

Git Push
    ↓
CI/CD
    ↓
Trivy Scan
    ↓
Cosign Sign
    ↓
Registry
    ↓
Admission Verify
    ↓
Kubernetes
```

## KẾT LUẬN

Day 2 tập trung vào hai mục tiêu chính:

1. Bảo vệ Secret
2. Bảo vệ Software Supply Chain

Mục tiêu cuối cùng là:

```text
Không deploy image nguy hiểm
Không để lộ credential
```
