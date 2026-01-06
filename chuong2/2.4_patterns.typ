== Load Balancer Patterns <patterns>

Cách đặt Load Balancer ở đâu và cấu hình như thế nào tạo nên các kiến trúc (topology) khác nhau, ảnh hưởng trực tiếp đến độ tin cậy và hiệu năng hệ thống.

=== Active-Passive

Đây là mô hình kinh điển để xử lý vấn đề SPOF (Single Point of Failure) của chính bản thân Load Balancer. Vì nếu LB chết, cả hệ thống chết, nên LB cũng cần dự phòng.

*Cấu trúc:*
- 2 thiết bị Load Balancer: LB-Primary (Active) và LB-Secondary (Passive/Standby).
- Cả hai dùng chung một địa chỉ IP ảo (VIP - Virtual IP).
- Cơ chế *Heartbeat:* Hai thiết bị nối với nhau qua một dây cáp riêng hoặc qua mạng, liên tục gửi tín hiệu "Tôi còn sống".
- Giao thức phổ biến: *VRRP* hoặc Keepalived.

*Hoạt động:*
- Bình thường: Chỉ LB-Primary giữ VIP và xử lý 100% traffic. LB-Secondary ngồi chơi, chỉ lắng nghe heartbeat.
- Sự cố: LB-Primary chết (mất điện, lỗi OS). LB-Secondary không thấy heartbeat nữa -> Nó lập tức chiếm lấy VIP (IP Takeover) và bắt đầu xử lý traffic.
- Thời gian chuyển đổi: Thường rất nhanh (vài giây).

=== Active-Active Cluster

Để tránh lãng phí LB-Secondary (mua về để không), người ta cấu hình cả 2 LB cùng chạy.

*Cấu trúc:*
- Cả LB1 và LB2 đều xử lý traffic.
- Cần một cơ chế phân tải trước đó nữa (ví dụ: DNS Round Robin). DNS sẽ trả về lúc thì IP của LB1, lúc thì IP của LB2.

*Ưu điểm:* Tăng gấp đôi công suất xử lý.
*Nhược điểm:* Phức tạp hơn trong cấu hình và debug. Nếu 1 LB chết, LB còn lại phải gánh 100% tải, có thể bị quá tải theo (Cascading failure).

=== Global Server Load Balancing (GSLB)

Đây là Load Balancing ở cấp độ địa lý (Geo-level), thường dùng DNS làm công cụ chính.

*Bài toán:*
Bạn có server ở Mỹ (US) và Việt Nam (VN). Khách ở VN truy cập vào server US sẽ rất chậm. Làm sao để khách VN vào server VN, khách US vào server US?

*Giải pháp:*
GSLB đóng vai trò là một DNS Server thông minh.
1.  Khách VN gõ `facebook.com`.
2.  GSLB nhận DNS Query, nhìn thấy IP nguồn của khách là ở VN.
3.  GSLB trả về IP của Load Balancer tại Data Center Việt Nam.
4.  Khách kết nối thẳng tới DC Việt Nam -> Nhanh.

*Tính năng khác:*
- *Disaster Recovery:* Nếu DC Việt Nam bị động đất sập hoàn toàn, GSLB phát hiện ra (Health Check thất bại) -> Nó sẽ tự động trả về IP của DC Singapore hoặc Mỹ cho khách VN. Chậm hơn nhưng vẫn vào được.

=== Reverse Proxy Load Balancer

Đây là mô hình phổ biến nhất trong các web server hiện đại (Nginx, Apache).
- LB đứng chắn trước các Web Server.
- Client không bao giờ kết nối trực tiếp với Web Server.
- LB chấm dứt kết nối từ Client, rồi tạo kết nối mới tới Server.
- Lợi ích: Ẩn topology mạng nội bộ (Security through obscurity), tập trung quản lý SSL, Caching tập trung.

=== Client-side Load Balancing

Trong kiến trúc Microservices, việc dùng một Hardware LB ở giữa các service (Server-side LB) có thể gây ra độ trễ và điểm nghẽn.

*Ý tưởng:*
Chính Client (Service A gọi Service B) sẽ tự quyết định gọi instance nào của Service B.

*Cơ chế:*
1.  *Service Registry:* Là cuốn danh bạ lưu danh sách IP của tất cả các service đang sống.
2.  Service A hỏi Registry: "Cho tôi danh sách IP của Service B".
3.  Registry trả về: `[10.0.0.1, 10.0.0.2, 10.0.0.3]`.
4.  Service A tự chạy thuật toán Round Robin (trong code của mình) để chọn 1 IP và gọi thẳng.

*Ưu điểm:*
- Loại bỏ nút thắt cổ chai trung gian (No middleman).
- Hiệu năng cao nhất.

*Nhược điểm:*
- Client trở nên phức tạp (Client phải có logic load balancing).
- Phải viết thư viện LB cho từng ngôn ngữ (Java, Go, Nodejs...).

=== Service Mesh Load Balancing

Đây là sự tiến hóa của Client-side LB để giải quyết nhược điểm "Client phức tạp".

*Cấu trúc:*
- Mỗi Service (Container) sẽ được đính kèm một *Sidecar Proxy* nhỏ (như Envoy, Linkerd) chạy ngay bên cạnh (localhost).
- Service A muốn gọi Service B, nó chỉ việc gọi ra `localhost`.
- Sidecar của A sẽ chặn request đó, tự thực hiện Service Discovery, tự Load Balance, rồi gửi sang Sidecar của B.

*Ưu điểm:*
- Code ứng dụng không cần biết gì về LB hay mạng (Transparent).
- Hỗ trợ đa ngôn ngữ tự động (vì giao tiếp qua localhost/TCP).
- Cung cấp khả năng quan sát (Observability), Tracing, mTLS cực mạnh.

*Ví dụ:* Istio, Linkerd, Consul Connect. Đây là tiêu chuẩn vàng cho các hệ thống Kubernetes hiện đại.