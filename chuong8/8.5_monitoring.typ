== Prometheus + Grafana <monitoring>

Trong Microservices, việc debug bằng cách SSH vào server xem log là bất khả thi. Chúng ta cần một hệ thống giám sát tập trung để trả lời câu hỏi: *"Hệ thống có đang khỏe không? Service nào đang chậm? Tài nguyên có bị quá tải không?"*.
Cặp đôi *Prometheus* (Backend) và *Grafana* (Frontend) là tiêu chuẩn vàng (de-facto standard) cho việc này.

=== Prometheus

Prometheus là một hệ thống giám sát và cảnh báo mã nguồn mở, ban đầu được phát triển bởi SoundCloud. Nó khác biệt hoàn toàn với các hệ thống giám sát cổ điển (như Nagios, Zabbix).

==== Kiến trúc và Mô hình hoạt động

1.  *Time-series Database (TSDB):*
    Prometheus được thiết kế tối ưu để lưu trữ dữ liệu chuỗi thời gian.
    - Dữ liệu dạng: `(timestamp, value)`.
    - Ví dụ: `http_requests_total{status="200", method="POST"} = 1024` tại `12:00:00`.
    - Khả năng ghi (Write throughput) cực cao, nén dữ liệu rất tốt.

2.  *Mô hình Pull:*
    Đây là điểm đặc biệt nhất. Thay vì các App chủ động gửi (Push) dữ liệu về Server (như InfluxDB), Prometheus Server chủ động *Kéo (Scrape/Pull)* dữ liệu từ các App.
    - *Lợi ích:*
        - App không cần biết Prometheus nằm ở đâu. Code App đơn giản.
        - Prometheus kiểm soát được tốc độ lấy dữ liệu, không bị quá tải khi traffic tăng vọt (Backpressure).
        - Dễ dàng phát hiện App chết: Nếu không kéo được -> App chết.

3.  *Exporters:*
    Với các phần mềm không thể sửa code (Linux Kernel, MySQL, Redis), ta dùng các chương trình trung gian gọi là *Exporter*.
    - *Node Exporter:* Lấy thông tin CPU, RAM, Disk của máy chủ, expose ra port 9100.
    - *MySQL Exporter:* Query trạng thái DB, expose ra metrics.
    - Prometheus sẽ scrape các Exporter này.

4.  *PromQL:*
    Ngôn ngữ truy vấn cực mạnh để tính toán.
    - `rate(http_requests_total[5m])`: Tính tốc độ request trung bình trong 5 phút.
    - `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))`: Tính độ trễ P95 (95% request nhanh hơn bao nhiêu giây).

5.  *AlertManager:*
    Bộ phận xử lý cảnh báo.
    - Prometheus định nghĩa luật: "Nếu CPU > 90% trong 5 phút -> Báo động".
    - AlertManager nhận báo động, gộp lại (Deduplication), nhóm lại (Grouping) và gửi đi qua Slack, Email, PagerDuty...

=== Grafana

Nếu Prometheus là bộ não tính toán, thì Grafana là khuôn mặt xinh đẹp. Grafana là nền tảng phân tích và trực quan hóa dữ liệu đa nguồn.

==== Chức năng chính

1.  *Dashboarding:*
    Vẽ các biểu đồ (Graph, Gauge, Bar chart, Heatmap) cực kỳ đẹp mắt và chuyên nghiệp từ dữ liệu của Prometheus.
    - Cho phép tạo các Dashboard tương tác: Chọn Server A thì biểu đồ tự update theo Server A.

2.  *Đa nguồn dữ liệu:*
    Grafana không chỉ đọc Prometheus. Trên cùng 1 dashboard, nó có thể vẽ:
    - Biểu đồ CPU từ *Prometheus*.
    - Log lỗi từ *Elasticsearch/Loki*.
    - Số liệu kinh doanh từ *MySQL/PostgreSQL*.
    -> Giúp tương quan (correlate) dữ liệu: "Lúc CPU tăng cao (Prometheus) thì số lượng đơn hàng (MySQL) có tăng không?".

3.  *Plugin phong phú:*
    Hàng ngàn Dashboard mẫu được cộng đồng chia sẻ.
    - Cần giám sát Kubernetes? Import dashboard ID 315.
    - Cần giám sát Redis? Import dashboard ID 763.
    - Tiết kiệm hàng trăm giờ tự cấu hình.

==== Ưu điểm của bộ đôi này

1.  *Cloud-Native:* Tương thích hoàn hảo với Kubernetes. (Prometheus tự động phát hiện Pod mới sinh ra trong K8s để scrape - Service Discovery Integration).
2.  *Hiệu năng:* Xử lý hàng triệu metrics/giây.
3.  *Độc lập:* Không phụ thuộc vào hạ tầng cloud nào (khác với CloudWatch chỉ chạy trên AWS).
4.  *Cộng đồng:* Tài liệu khổng lồ, hỗ trợ mọi ngôn ngữ lập trình.

=== Tổng kết luồng dữ liệu

1.  *App/Exporter* mở cổng HTTP `/metrics` (chứa text dạng key-value).
2.  *Prometheus* định kỳ (15s/lần) gọi vào `/metrics`, lấy dữ liệu về, gắn timestamp, lưu vào ổ cứng.
3.  *AlertManager* check luật, nếu vi phạm thì bắn tin nhắn lên Slack cho Dev.
4.  *Grafana* query Prometheus (dùng PromQL) để vẽ biểu đồ lên màn hình TV ở văn phòng.