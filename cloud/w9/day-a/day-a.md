# W9 - Day A: GitOps & CI/CD

## Mục tiêu

Sau khi hoàn thành Day A cần hiểu:

- GitOps là gì
- Configuration Drift là gì
- Git là Source of Truth như thế nào
- ArgoCD hoạt động ra sao
- GitOps khác CI/CD ở đâu
- GitHub Actions trong GitOps được sử dụng như thế nào
- App of Apps là gì
- Sync Waves là gì
- Rollback trong GitOps thực hiện như thế nào

---

# 1. Vấn đề của cách Deploy truyền thống

Trong Kubernetes thông thường, developer hoặc admin thường deploy bằng:

```bash
kubectl apply -f deployment.yaml
```

Ví dụ:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
```

Sau đó một người khác sửa trực tiếp trên cluster:

```bash
kubectl scale deployment web --replicas=5
```

Lúc này:

Git:

```yaml
replicas: 3
```

Cluster:

```yaml
replicas: 5
```

Xuất hiện sự khác biệt giữa Git và Cluster.

---

# 2. Configuration Drift

## Định nghĩa

Configuration Drift là trạng thái:

```text
Cấu hình thực tế ≠ Cấu hình mong muốn
```

Ví dụ:

Git:

```yaml
replicas: 3
```

Cluster:

```yaml
replicas: 5
```

hoặc

Git:

```yaml
image: nginx:v1
```

Cluster:

```yaml
image: nginx:v2
```

## Nguyên nhân

- Sửa thủ công bằng kubectl
- Sửa trực tiếp trên cluster
- Script bên ngoài tác động
- Nhiều người cùng thao tác

## Tác hại

- Khó kiểm soát
- Khó audit
- Khó rollback
- Dễ xảy ra lỗi môi trường

---

# 3. GitOps là gì?

GitOps là phương pháp quản lý hạ tầng và ứng dụng bằng Git.

Ý tưởng:

```text
Git = Source of Truth
```

Mọi thay đổi đều phải thông qua Git.

Không sửa trực tiếp trên Cluster.

---

# 4. Source of Truth

## Định nghĩa

Source of Truth là nơi chứa trạng thái chuẩn của hệ thống.

Trong GitOps:

```text
Git Repository
```

chính là Source of Truth.

Ví dụ:

Git:

```yaml
replicas: 3
```

Cluster:

```yaml
replicas: 5
```

Git được xem là đúng.

Cluster sẽ bị sửa lại để giống Git.

---

# 5. GitOps hoạt động như thế nào?

Luồng hoạt động:

```text
Developer
    |
    v
Git Repository
    |
    v
ArgoCD
    |
    v
Kubernetes Cluster
```

Developer commit code:

```bash
git commit
git push
```

ArgoCD theo dõi Git.

Nếu Git thay đổi:

```text
Git → Cluster
```

ArgoCD sẽ đồng bộ xuống Kubernetes.

---

# 6. Reconciliation

## Định nghĩa

Reconciliation là quá trình liên tục so sánh:

```text
Git
vs
Cluster
```

Nếu khác nhau:

```text
Sync
```

để đưa Cluster về đúng trạng thái trong Git.

Ví dụ:

Git:

```yaml
replicas: 3
```

Cluster:

```yaml
replicas: 5
```

ArgoCD phát hiện:

```text
OutOfSync
```

Sau đó:

```text
Sync
```

Kết quả:

```yaml
replicas: 3
```

---

# 7. Declarative vs Imperative

## Imperative

Ra lệnh cho hệ thống phải làm gì.

Ví dụ:

```bash
kubectl scale deployment web --replicas=5
```

## Declarative

Mô tả trạng thái mong muốn.

Ví dụ:

```yaml
replicas: 5
```

Hệ thống tự thực hiện.

GitOps sử dụng mô hình Declarative.

---

# 8. CI/CD là gì?

## CI - Continuous Integration

Mỗi lần có code mới:

```text
Build
Test
Validate
```

Ví dụ:

```text
Git Push
    |
    v
GitHub Actions
    |
    +-- Unit Test
    +-- Lint
    +-- Build
```

---

## CD - Continuous Delivery / Deployment

Sau khi CI thành công:

```text
Deploy
```

Ví dụ:

```text
GitHub Actions
    |
    v
kubectl apply
```

---

# 9. GitOps khác CI/CD như thế nào?

## CI/CD truyền thống

```text
Developer
    |
    v
GitHub Actions
    |
    v
Deploy trực tiếp
    |
    v
Cluster
```

Pipeline chịu trách nhiệm deploy.

---

## GitOps

```text
Developer
    |
    v
Git Repository
    |
    v
ArgoCD
    |
    v
Cluster
```

Pipeline không deploy trực tiếp.

Pipeline chỉ cập nhật Git.

ArgoCD mới là thành phần deploy.

---

# 10. GitHub Actions

GitHub Actions là công cụ CI/CD của GitHub.

Cho phép:

- Build
- Test
- Validate
- Deploy

tự động khi có sự kiện Git.

---

# 11. Plan-on-PR

Khi tạo Pull Request:

```text
Feature Branch
    |
    v
Pull Request
    |
    v
GitHub Actions
```

Thực hiện:

```bash
terraform fmt
terraform validate
terraform plan
```

Mục đích:

- Kiểm tra lỗi
- Review thay đổi
- Hạn chế deploy sai

---

# 12. Apply-on-Merge

Sau khi Pull Request được merge:

```text
main branch
    |
    v
GitHub Actions
```

Thực hiện:

```bash
terraform apply
```

hoặc cập nhật manifest Kubernetes.

ArgoCD sẽ đồng bộ xuống cluster.

---

# 13. ArgoCD

## Định nghĩa

ArgoCD là GitOps Controller dành cho Kubernetes.

Nhiệm vụ:

```text
Git → Kubernetes
```

---

## Chức năng chính

### Sync

Đồng bộ Git xuống Cluster.

### Drift Detection

Phát hiện Config Drift.

### Self-Healing

Tự đưa Cluster về trạng thái đúng.

### Rollback

Khôi phục phiên bản trước.

---

# 14. App of Apps

## Định nghĩa

Một ứng dụng cha quản lý nhiều ứng dụng con.

Ví dụ:

```text
root-app
|
+-- frontend
|
+-- backend
|
+-- monitoring
|
+-- ingress
```

Chỉ cần deploy:

```text
root-app
```

ArgoCD tự tạo các ứng dụng còn lại.

---

# 15. Sync Waves

## Định nghĩa

Cho phép deploy tài nguyên theo thứ tự.

Ví dụ:

```text
Wave 0
|
+ Namespace

Wave 1
|
+ Database

Wave 2
|
+ Backend

Wave 3
|
+ Frontend
```

Mục đích:

- Đảm bảo dependency
- Tránh deploy sai thứ tự

---

# 16. Rollback

## Cách 1 - Git Revert

```bash
git revert <commit>
git push
```

ArgoCD phát hiện thay đổi:

```text
Sync
```

Cluster quay lại phiên bản cũ.

Đây là cách chuẩn của GitOps.

---

## Cách 2 - kubectl rollout undo

```bash
kubectl rollout undo deployment/web
```

Rollback trực tiếp trên cluster.

Nhược điểm:

```text
Git ≠ Cluster
```

Gây Configuration Drift.

Không đúng triết lý GitOps.

---

# Tổng kết

## Các khái niệm cần nhớ

### GitOps

Git là nguồn sự thật duy nhất.

### Source of Truth

Git chứa trạng thái mong muốn của hệ thống.

### Configuration Drift

Git khác với Cluster.

### Reconciliation

Quá trình đồng bộ Cluster về giống Git.

### Sync

Đồng bộ từ Git xuống Kubernetes.

### Self-Healing

Tự sửa Config Drift.

### App of Apps

Một ứng dụng quản lý nhiều ứng dụng.

### Sync Waves

Deploy theo thứ tự.

### Rollback

Khôi phục phiên bản trước thông qua Git.

---

