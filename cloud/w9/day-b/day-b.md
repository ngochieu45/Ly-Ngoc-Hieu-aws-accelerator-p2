# W9 - Day B: Observability, SLO, SLI và OpenTelemetry

## Mục tiêu

Sau khi hoàn thành Day B cần hiểu:

- Observability là gì
- Monitoring khác Observability như thế nào
- Metrics, Logs, Traces là gì
- OpenTelemetry (OTel) là gì
- OTel SDK và OTel Collector hoạt động ra sao
- Prometheus dùng để làm gì
- Grafana dùng để làm gì
- Loki dùng để làm gì
- SLI là gì
- SLO là gì
- Error Budget là gì
- Burn Rate là gì
- Multi-window Burn Rate Alert hoạt động như thế nào

---

# 1. Monitoring là gì?

Monitoring là quá trình theo dõi trạng thái hệ thống thông qua các chỉ số đã biết trước.

Ví dụ:

- CPU
- Memory
- Disk
- Network

Theo dõi:

```text
CPU > 80%
```

thì gửi cảnh báo.

---

## Hạn chế của Monitoring

Monitoring trả lời:

```text
Điều gì đang xảy ra?
```

Ví dụ:

```text
CPU tăng cao
```

Nhưng không trả lời được:

```text
Tại sao CPU tăng?
```

---

# 2. Observability là gì?

Observability là khả năng hiểu được trạng thái bên trong của hệ thống thông qua dữ liệu được sinh ra.

Observability trả lời:

```text
Điều gì xảy ra?
Tại sao xảy ra?
Xảy ra ở đâu?
```

Ví dụ:

```text
API chậm
```

Observability giúp tìm:

- Service nào chậm
- Database nào chậm
- Request nào lỗi

---

# 3. Ba trụ cột của Observability

## Metrics

Dữ liệu dạng số theo thời gian.

Ví dụ:

```text
CPU Usage
Memory Usage
Request Count
Error Rate
Latency
```

Ví dụ:

```text
CPU = 75%
```

---

## Logs

Ghi lại các sự kiện xảy ra.

Ví dụ:

```text
User login success
```

```text
Database connection failed
```

```text
Payment completed
```

---

## Traces

Theo dõi đường đi của một request.

Ví dụ:

```text
Client
  |
Frontend
  |
Backend
  |
Database
```

Trace cho biết:

```text
Request mất bao lâu ở từng bước
```

---

# 4. Metrics, Logs và Traces khác nhau như thế nào?

| Thành phần | Mục đích |
|------------|-----------|
| Metrics | Theo dõi sức khỏe hệ thống |
| Logs | Ghi lại sự kiện |
| Traces | Theo dõi luồng request |

---

# 5. OpenTelemetry (OTel)

## Định nghĩa

OpenTelemetry là bộ tiêu chuẩn mã nguồn mở dùng để thu thập:

```text
Metrics
Logs
Traces
```

Từ ứng dụng.

---

## Tại sao cần OpenTelemetry?

Nếu mỗi công cụ có format riêng:

```text
Prometheus
Jaeger
Datadog
New Relic
```

sẽ rất khó tích hợp.

OTel tạo ra:

```text
Một chuẩn chung
```

cho tất cả.

---

# 6. OTel SDK

SDK được cài trong ứng dụng.

Ví dụ:

```text
NodeJS
Java
Python
Go
```

SDK sẽ tạo:

```text
Metrics
Logs
Traces
```

từ ứng dụng.

---

Ví dụ:

```text
API Request
```

SDK ghi nhận:

```text
Request Count
Latency
Error
```

---

# 7. OTel Collector

## Định nghĩa

Collector là thành phần trung gian.

Luồng:

```text
Application
    |
OTel SDK
    |
Collector
    |
Prometheus
Grafana
Jaeger
Datadog
```

---

## Nhiệm vụ

### Receive

Nhận dữ liệu.

### Process

Xử lý dữ liệu.

### Export

Gửi dữ liệu tới hệ thống đích.

---

# 8. Prometheus

## Định nghĩa

Prometheus là hệ thống thu thập và lưu trữ Metrics.

---

## Chức năng

Thu thập:

```text
CPU
Memory
Latency
Request Count
Error Rate
```

---

## Cơ chế Pull

Prometheus định kỳ:

```text
GET /metrics
```

từ ứng dụng.

---

Ví dụ:

```text
Prometheus
    |
    v
Application
```

---

# 9. Grafana

## Định nghĩa

Grafana là công cụ trực quan hóa dữ liệu.

---

## Chức năng

Hiển thị Dashboard:

```text
CPU
Memory
Latency
Error Rate
```

---

Ví dụ Dashboard:

```text
Requests per Second
Error Rate
P95 Latency
```

---

# 10. Loki

## Định nghĩa

Loki là hệ thống lưu trữ Logs của Grafana.

---

## Chức năng

Thu thập:

```text
Application Logs
Container Logs
Kubernetes Logs
```

---

Ví dụ:

```text
Error: Database timeout
```

được lưu trong Loki.

---

# 11. SLI

## Định nghĩa

SLI (Service Level Indicator)

Là chỉ số đo lường chất lượng dịch vụ.

---

Ví dụ:

### Availability

```text
99.95%
```

### Latency

```text
95% request < 200ms
```

### Error Rate

```text
0.1%
```

---

# 12. SLO

## Định nghĩa

SLO (Service Level Objective)

Là mục tiêu đặt ra cho SLI.

---

Ví dụ

SLI:

```text
Availability
```

SLO:

```text
99.9%
```

---

Ví dụ:

```text
95% request phải dưới 200ms
```

---

# 13. SLA, SLO, SLI

## SLI

Chỉ số đo.

Ví dụ:

```text
Availability = 99.92%
```

---

## SLO

Mục tiêu.

Ví dụ:

```text
Availability >= 99.9%
```

---

## SLA

Cam kết với khách hàng.

Ví dụ:

```text
Availability >= 99.5%
```

---

Quan hệ:

```text
SLI -> đo
SLO -> mục tiêu
SLA -> cam kết
```

---

# 14. Error Budget

## Định nghĩa

Lượng lỗi được phép xảy ra.

Ví dụ:

SLO:

```text
99.9%
```

Nghĩa là:

```text
0.1%
```

được phép lỗi.

---

Nếu vượt:

```text
0.1%
```

thì vi phạm SLO.

---

# 15. Burn Rate

## Định nghĩa

Tốc độ tiêu thụ Error Budget.

---

Ví dụ:

SLO:

```text
99.9%
```

Error Budget:

```text
0.1%
```

Nếu hệ thống lỗi quá nhanh:

```text
Burn Rate cao
```

---

Nếu hệ thống ổn định:

```text
Burn Rate thấp
```

---

# 16. Multi-window Burn Rate Alert

## Vấn đề

Nếu chỉ nhìn 1 thời điểm:

```text
Có thể báo động giả
```

---

Google đề xuất:

### Fast Window

```text
1 giờ
```

đánh giá:

```text
5 phút
```

---

### Slow Window

```text
6 giờ
```

đánh giá:

```text
30 phút
```

---

Chỉ cảnh báo khi:

```text
Fast Window báo lỗi
AND
Slow Window báo lỗi
```

---

Lợi ích:

- Giảm false positive
- Phát hiện sự cố thật nhanh
- Phát hiện lỗi kéo dài

---

# 17. Luồng Observability hoàn chỉnh

```text
Application
    |
OTel SDK
    |
OTel Collector
    |
+------------+
|            |
v            v
Prometheus   Loki
|            |
v            v
Grafana Dashboard
```

---

# Tổng kết

## Các khái niệm cần nhớ

### Monitoring

Theo dõi trạng thái hệ thống.

### Observability

Khả năng hiểu nguyên nhân sự cố.

### Metrics

Dữ liệu dạng số.

### Logs

Nhật ký sự kiện.

### Traces

Theo dõi luồng request.

### OpenTelemetry

Chuẩn thu thập Metrics, Logs, Traces.

### Collector

Thu thập và chuyển tiếp dữ liệu.

### Prometheus

Lưu Metrics.

### Grafana

Dashboard.

### Loki

Lưu Logs.

### SLI

Chỉ số đo lường.

### SLO

Mục tiêu chất lượng.

### Error Budget

Lượng lỗi cho phép.

### Burn Rate

Tốc độ tiêu thụ Error Budget.

---