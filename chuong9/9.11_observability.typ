== Observability, Metrics & Logging <observability>

"Nếu bạn không đo lường được, bạn không thể cải thiện được". Observability giúp trả lời câu hỏi: Hệ thống có khỏe không? Tại sao nó chậm? Lỗi nằm ở đâu?

#figure(image("../images/pic21.jpg"), caption: [Grafana Monitoring Architecture])

#figure(image("../images/pic22.webp"), caption: [Prometheus Pull Model Diagram])

=== Metrics

Đo lường sức khỏe hệ thống theo thời gian thực.
- *Thư viện:* `prom-client`.
- *Các loại Metric:*
    - *Counter:* Đếm số lượng (Tổng số request, Tổng số lỗi 500). Chỉ tăng, không giảm.
    - *Gauge:* Giá trị tại một thời điểm (Số lượng RAM đang dùng, Số lượng Job trong Queue). Có thể tăng giảm.
    - *Histogram:* Phân bố giá trị (Độ trễ request: bao nhiêu % < 100ms, bao nhiêu % < 500ms). Dùng để tính P95, P99 Latency.

=== Tracing

Theo dõi hành trình của một request đi qua nhiều Microservices.
- *Chuẩn:* *OpenTelemetry (OTel)* Node.js SDK.
- *Cơ chế:*
    - Gắn `Trace-ID` vào Header của mỗi request.
    - Mỗi Service khi nhận request sẽ tạo ra một `Span` (khoảng thời gian xử lý) và gửi về Collector.
- *Backend:* Jaeger, Zipkin, hoặc Grafana Tempo.
- *Lợi ích:* Nhìn vào biểu đồ thác nước (Waterfall), biết ngay Service nào, DB query nào đang làm chậm hệ thống.

=== Logging

- *Structured Logging:* Không ghi log text (`User login failed`). Hãy ghi JSON (`{"event": "login_failed", "userId": 123, "ip": "10.0.0.1"}`).
    - Giúp máy (Elasticsearch, Loki) dễ dàng parse và search.
- *Thư viện:* `pino` (nhanh nhất), `winston`.
- *Log Shipping:* App chỉ ghi log ra `stdout` (console). Một agent (Filebeat, Fluentd) sẽ đọc log từ container và đẩy về hệ thống lưu trữ tập trung (ELK Stack).

=== Dashboards

Sử dụng *Grafana* để vẽ biểu đồ từ Prometheus (Metrics) và Loki (Logs).
- Cảnh báo (Alerts): Gửi tin nhắn Slack/Telegram khi tỉ lệ lỗi > 1% hoặc CPU > 80%.