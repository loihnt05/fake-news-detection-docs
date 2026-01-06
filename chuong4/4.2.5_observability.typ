== Observability liên quan giao tiếp <observability>

Trong Monolith, khi có lỗi, bạn chỉ cần đọc log của 1 file duy nhất. Trong Microservices, một request đi qua 10 service khác nhau. Nếu lỗi xảy ra, nó nằm ở đâu? Tại sao nó chậm? Observability giúp trả lời câu hỏi "Hệ thống đang làm gì?" dựa trên dữ liệu đầu ra.

Ba trụ cột của Observability (The Three Pillars): *Logs, Metrics, Traces*.

=== Distributed Tracing

Đây là công cụ quan trọng nhất để debug Microservices.

==== Vấn đề:
User báo lỗi "Không đặt được hàng". Log của `Order Service` báo "Timeout gọi Payment". Log của `Payment Service` báo "Database Locked". Làm sao xâu chuỗi chúng lại?

==== Giải pháp:
Gắn cho mỗi request từ khi bắt đầu (vào API Gateway) một *Trace ID* duy nhất. ID này được truyền (propagate) qua HTTP Headers (ví dụ: `X-B3-TraceId` của Zipkin) sang tất cả các service phía sau.

==== Các khái niệm:
- *Trace:* Toàn bộ hành trình của một request.
- *Span:* Một công đoạn xử lý đơn lẻ (ví dụ: Service A gọi Service B, Service B query DB).
- *Context Propagation:* Việc truyền Trace ID qua các boundaries (HTTP, gRPC, Kafka headers).

==== Công cụ:
- *OpenTelemetry (OTel):* Chuẩn công nghiệp hiện nay để thu thập Trace/Metric/Log.
- *Jaeger / Zipkin:* Backend để lưu trữ và hiển thị biểu đồ Gantt của Trace. Nhìn vào biểu đồ, ta biết ngay Span nào dài nhất (nguyên nhân gây chậm).

=== Centralized Logging

Không thể SSH vào 100 server để `tail -f` log. Log phải được gom về một chỗ.

==== Quy trình (ELK/EFK Stack):
1.  *Collection:* Agent (Filebeat, Fluentd, Fluent-bit) chạy trên mỗi server/container, đọc log file hoặc docker logs.
2.  *Aggregation & Processing:* Gửi về Logstash hoặc Fluentd để lọc, parse (biến text log thành JSON), làm sạch dữ liệu.
3.  *Storage:* Lưu vào Elasticsearch (hoặc Loki, Splunk).
4.  *Visualization:* Hiển thị trên Kibana (hoặc Grafana).

==== Best Practices:
- *Structured Logging:* Luôn ghi log dạng JSON thay vì text thuần.
  - *Tệ:* `User 123 login failed.`
  - *Tốt:* `{"event": "login_failed", "user_id": 123, "ip": "10.0.1.1", "error": "wrong_password"}` -> Dễ dàng query trên Kibana.
- *Correlation:* Trong Log phải in kèm *Trace ID* để link được với Tracing.

=== Metrics & Alerting

Log cho biết "Tại sao lỗi". Metric cho biết "Hệ thống có khỏe không".

==== Các loại Metric (USE & RED Method):
- RED Method (cho Services):
    - *Rate:* Số request/giây (RPS).
    - *Errors:* Số lỗi/giây (HTTP 500).
    - *Duration:* Thời gian phản hồi (Latency P95, P99).
- *USE Method (cho Resources - CPU/RAM):*
    - *Utilization:* % sử dụng (CPU 80%).
    - *Saturation:* Độ bão hòa (Queue đang chờ).
    - *Errors:* Số lỗi phần cứng.

==== Công cụ:
- *Prometheus:* Tiêu chuẩn để scrape (kéo) metrics từ các service.
- *Grafana:* Vẽ biểu đồ dashboard cực đẹp từ Prometheus.
- *AlertManager:* Gửi cảnh báo (Slack, Email, PagerDuty) khi `Error Rate > 5%` trong 5 phút.

=== Contract Testing

Làm sao đảm bảo Service A (Consumer) vẫn chạy đúng khi Service B (Provider) thay đổi API?
- Integration Test truyền thống rất chậm và tốn kém môi trường.
- *Consumer-Driven Contract Testing (CDC):*
    - Service A định nghĩa một "Hợp đồng" (Contract): "Tôi cần API `/users/{id}` trả về JSON có field `name` là string".
    - Service B (Provider) chạy test case tự động để kiểm tra xem mình có đáp ứng đúng Contract đó không.
    - Nếu B sửa API xóa mất field `name` -> Test fail -> Không cho deploy.
- *Công cụ:* *Pact*.

=== Service Map

Từ dữ liệu Tracing, ta có thể vẽ ra bản đồ Dependency Graph theo thời gian thực.
- Giúp phát hiện: Service nào là điểm nghẽn (được quá nhiều thằng gọi)? Service nào bị cô lập? Vòng lặp gọi nhau (Circular dependency).
- Các công cụ APM (Application Performance Monitoring) như Datadog, Dynatrace, New Relic làm việc này rất tốt (nhưng đắt). Kiali (cho Istio) là lựa chọn miễn phí.