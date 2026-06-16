# W10 - DAY 1: RBAC + ADMISSION POLICY (OPA/GATEKEEPER)

## MỤC TIÊU

Sau khi hoàn thành Day 1, cần hiểu:

* Authentication và Authorization khác nhau thế nào
* RBAC hoạt động ra sao trong Kubernetes
* Role, ClusterRole, RoleBinding, ClusterRoleBinding
* ServiceAccount dùng để làm gì
* kubectl auth can-i hoạt động như thế nào
* Admission Controller là gì
* OPA là gì
* Gatekeeper là gì
* ConstraintTemplate và Constraint
* Audit mode và Enforce mode

---

# 1. KUBERNETES SECURITY FLOW

Khi người dùng chạy:

```bash
kubectl apply -f pod.yaml
```

Kubernetes không tạo Pod ngay lập tức.

Luồng xử lý thực tế:

```text
kubectl
    ↓
API Server
    ↓
Authentication
    ↓
Authorization (RBAC)
    ↓
Admission Controller
    ↓
etcd
```

Ý nghĩa:

* Authentication: xác định người gửi request là ai
* Authorization: kiểm tra người đó có quyền hay không
* Admission Controller: kiểm tra tài nguyên có vi phạm policy hay không
* etcd: lưu trạng thái cuối cùng của cluster

---

# 2. AUTHENTICATION VS AUTHORIZATION

## Authentication

Authentication trả lời câu hỏi:

```text
Bạn là ai?
```

Ví dụ:

```text
User: hieu
```

Kubernetes xác thực:

* Certificate
* Token
* OIDC
* ServiceAccount Token

Nếu hợp lệ:

```text
Authentication Success
```

---

## Authorization

Sau khi xác định được danh tính.

Kubernetes kiểm tra:

```text
Bạn được phép làm gì?
```

Ví dụ:

```bash
kubectl delete namespace production
```

RBAC sẽ quyết định:

```text
ALLOW
hoặc
DENY
```

---

# 3. RBAC LÀ GÌ?

RBAC = Role Based Access Control

Hiểu đơn giản:

```text
User
 ↓
Role
 ↓
Permission
```

RBAC giúp:

* Hạn chế quyền
* Tránh thao tác nhầm
* Tuân thủ nguyên tắc Least Privilege

Least Privilege:

```text
Chỉ cấp đúng quyền cần thiết
Không cấp thừa
```

---

# 4. ROLE

Role là tập hợp quyền trong một namespace.

Ví dụ:

Namespace:

```text
demo
```

Role:

```text
get pod
list pod
create pod
```

Role này chỉ hoạt động trong namespace demo.

Nếu namespace khác:

```text
production
```

Role không còn hiệu lực.

---

## Ví dụ thực tế

Developer cần:

* xem pod
* deploy ứng dụng

Không cần:

* xóa namespace
* quản lý node

Khi đó tạo Role cho Developer.

---

# 5. CLUSTERROLE

Một số tài nguyên không thuộc namespace.

Ví dụ:

```text
Node
Namespace
StorageClass
PersistentVolume
```

Những tài nguyên này thuộc toàn cluster.

Do đó Kubernetes cung cấp:

```text
ClusterRole
```

---

## So sánh

| Role                        | ClusterRole              |
| --------------------------- | ------------------------ |
| Namespace scope             | Cluster scope            |
| Chỉ áp dụng trong namespace | Áp dụng toàn cluster     |
| Dùng cho Pod, Deployment    | Dùng cho Node, Namespace |

---

# 6. ROLEBINDING

Role chỉ là tập quyền.

Chưa được gán cho ai.

Ví dụ:

```text
Role:
Create Pod
Delete Pod
```

Nhưng chưa có user nào sở hữu.

---

RoleBinding dùng để:

```text
Gắn Role vào User
```

Ví dụ:

```text
developer-role
      ↓
RoleBinding
      ↓
User: hieu
```

Khi đó user hieu mới có quyền.

---

# 7. CLUSTERROLEBINDING

Tương tự RoleBinding.

Khác biệt:

```text
ClusterRole
       ↓
ClusterRoleBinding
       ↓
User/Group/ServiceAccount
```

Áp dụng cho toàn cluster.

---

# 8. SERVICEACCOUNT

Đây là phần rất quan trọng.

## User

Là con người.

Ví dụ:

```text
admin
hieu
mentor
```

---

## ServiceAccount

Là danh tính của Pod.

Ví dụ:

```yaml
serviceAccountName: api-sa
```

Pod chạy dưới quyền:

```text
api-sa
```

---

## Tại sao cần ServiceAccount?

Ví dụ:

API Pod cần:

* đọc Secret
* đọc ConfigMap

Pod phải gọi Kubernetes API.

Kubernetes cần biết:

```text
Pod nào đang gọi?
```

ServiceAccount giải quyết vấn đề đó.

---

# 9. KUBECTL AUTH CAN-I

Lệnh kiểm tra quyền hiện tại.

Ví dụ:

```bash
kubectl auth can-i create pods
```

Ý nghĩa:

```text
User hiện tại có được tạo Pod không?
```

---

Ví dụ:

```bash
kubectl auth can-i delete namespace
```

Kết quả:

```text
yes
```

hoặc

```text
no
```

---

Ứng dụng thực tế:

Debug lỗi CI/CD.

Ví dụ:

```text
Deployment failed
Forbidden
```

Kiểm tra:

```bash
kubectl auth can-i create deployment
```

---

# 10. ADMISSION CONTROLLER

RBAC chỉ kiểm tra:

```text
Người dùng có quyền hay không
```

Nhưng không kiểm tra:

```text
Pod có an toàn không
```

---

Ví dụ:

Developer có quyền tạo Pod.

Tạo:

```yaml
runAsUser: 0
```

Hoặc:

```yaml
privileged: true
```

RBAC vẫn cho phép.

---

Kubernetes thêm lớp bảo vệ:

```text
Admission Controller
```

Luồng:

```text
kubectl
 ↓
API Server
 ↓
Admission Controller
 ↓
etcd
```

Admission Controller quyết định:

```text
ALLOW
hoặc
DENY
```

---

# 11. OPA (OPEN POLICY AGENT)

OPA là Policy Engine.

Cho phép định nghĩa luật dưới dạng Policy.

Ví dụ:

```text
Không cho phép chạy root
```

Hoặc:

```text
Không cho phép image latest
```

OPA đánh giá request:

```text
Allow
hoặc
Deny
```

---

## REGO

Ngôn ngữ policy của OPA.

Ví dụ:

```rego
deny {
  input.spec.containers[_].securityContext.runAsUser == 0
}
```

Ý nghĩa:

```text
Container chạy root
→ Reject
```

---

# 12. GATEKEEPER

OPA chỉ là engine.

Gatekeeper là giải pháp tích hợp OPA với Kubernetes.

Gatekeeper cung cấp:

* Admission Webhook
* Audit
* Constraint
* ConstraintTemplate
* Violation Report

---

## Dễ hiểu

```text
OPA
 ↓
Bộ não

Gatekeeper
 ↓
Hệ thống bảo vệ hoàn chỉnh
```

---

# 13. CONSTRAINTTEMPLATE

ConstraintTemplate dùng để định nghĩa luật.

Ví dụ:

```text
Không cho phép image latest
```

Hoặc:

```text
Không cho phép privileged container
```

Nó giống như:

```text
Mẫu luật
```

---

# 14. CONSTRAINT

Constraint dùng để áp dụng luật.

Ví dụ:

ConstraintTemplate:

```text
Không cho phép image latest
```

Constraint:

```text
Áp dụng cho namespace demo
```

---

## So sánh

| ConstraintTemplate | Constraint             |
| ------------------ | ---------------------- |
| Định nghĩa luật    | Áp dụng luật           |
| Viết Rego          | Thực thi Rego          |
| Tạo policy         | Gắn policy vào cluster |

---

# 15. AUDIT MODE VS ENFORCE MODE

## Audit Mode

Chỉ ghi nhận vi phạm.

Ví dụ:

```text
Image latest detected
```

Nhưng vẫn deploy thành công.

Mục đích:

```text
Đánh giá hệ thống hiện tại
```

---

## Enforce Mode

Chặn ngay lập tức.

Ví dụ:

```text
Image latest detected
```

Kết quả:

```text
Admission Denied
```

Pod không được tạo.

---

## So sánh

| Audit                   | Enforce                 |
| ----------------------- | ----------------------- |
| Chỉ cảnh báo            | Chặn luôn               |
| Không ảnh hưởng deploy  | Deploy thất bại         |
| Dùng khi rollout policy | Dùng khi policy ổn định |

---

# 16. NHỮNG CÂU HỎI MENTOR THƯỜNG HỎI

### RBAC là gì?

Cơ chế phân quyền trong Kubernetes dựa trên vai trò.

---

### Role và ClusterRole khác nhau thế nào?

Role áp dụng trong namespace.

ClusterRole áp dụng toàn cluster.

---

### Tại sao phải có RoleBinding?

Role chỉ là tập quyền.

RoleBinding gắn quyền đó cho User hoặc ServiceAccount.

---

### ServiceAccount dùng để làm gì?

Cung cấp danh tính cho Pod để Pod có thể gọi Kubernetes API.

---

### kubectl auth can-i dùng để làm gì?

Kiểm tra quyền hiện tại của User hoặc ServiceAccount.

---

### Admission Controller nằm ở đâu?

Sau Authorization và trước khi dữ liệu được lưu vào etcd.

---

### OPA là gì?

Policy Engine dùng để đánh giá luật bảo mật.

---

### Gatekeeper là gì?

Giải pháp tích hợp OPA vào Kubernetes để thực thi policy ở cluster level.

---

### ConstraintTemplate và Constraint khác nhau thế nào?

ConstraintTemplate định nghĩa luật.

Constraint áp dụng luật đó.

---

### Audit và Enforce khác nhau thế nào?

Audit chỉ cảnh báo.

Enforce chặn tài nguyên vi phạm.

---

# TÓM TẮT DAY 1

```text
Authentication
        ↓
Authorization (RBAC)
        ↓
Admission Controller
        ↓
OPA / Gatekeeper
        ↓
etcd
```

* Authentication → Bạn là ai?
* Authorization → Bạn được làm gì?
* RBAC → Quản lý quyền
* ServiceAccount → Danh tính của Pod
* Admission → Kiểm tra tài nguyên
* OPA → Engine đánh giá policy
* Gatekeeper → Triển khai policy trong Kubernetes
* Audit → Cảnh báo
* Enforce → Chặn
* etcd → Lưu trạng thái cluster

```
```
