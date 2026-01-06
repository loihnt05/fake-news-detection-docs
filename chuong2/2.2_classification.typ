== Phân loại Load Balancer <classification>

Có nhiều cách để phân loại Load Balancer, nhưng phổ biến nhất là dựa trên hình thức triển khai (Phần cứng vs Phần mềm) và tầng hoạt động trong mô hình OSI (Layer 4 vs Layer 7).

=== Phân loại theo hình thức triển khai

==== Hardware Load Balancer

Đây là các thiết bị vật lý chuyên dụng (appliances) được thiết kế và tối ưu hóa riêng cho nhiệm vụ xử lý mạng. Bên trong lớp vỏ kim loại là các vi mạch ASIC (Application-Specific Integrated Circuit) hoặc FPGA chuyên dụng để xử lý gói tin tốc độ cao.

*Các ông lớn:* F5 BIG-IP, Citrix ADC (NetScaler), A10 Networks, Barracuda.

*Đặc điểm:*
- *Hiệu năng cực khủng:* Có thể xử lý hàng chục Gigabits, thậm chí Terabits traffic mỗi giây. Phần cứng chuyên dụng giúp giải mã SSL nhanh gấp hàng trăm lần CPU thường.
- *Tính năng độc quyền:* Thường đi kèm với hệ điều hành riêng, giao diện quản lý chuyên nghiệp và các tính năng bảo mật cao cấp.
- *Độ ổn định cao:* Được thiết kế để chạy liên tục nhiều năm không cần khởi động lại (Carrier-grade reliability).

*Nhược điểm:*
- *Chi phí đắt đỏ:* Giá từ vài chục nghìn đến hàng trăm nghìn USD cho một thiết bị. Chưa kể phí license hàng năm.
- *Kém linh hoạt:* Muốn mở rộng phải mua thêm thiết bị mới, lắp đặt vật lý (racking, cabling), cấu hình phức tạp. Không phù hợp với môi trường Cloud co giãn nhanh.
- *Vendor Lock-in:* Phụ thuộc hoàn toàn vào nhà cung cấp.

==== Software Load Balancer

Đây là các phần mềm được cài đặt trên các máy chủ tiêu chuẩn (x86 commodity hardware) hoặc chạy trong môi trường ảo hóa/container.

*Phổ biến nhất:* Nginx, HAProxy, Envoy, Traefik, Apache HTTP Server (mod_proxy).
*Cloud Managed:* AWS ALB/NLB, Google Cloud Load Balancing, Azure Load Balancer.

*Đặc điểm:*
- *Chi phí thấp:* Nhiều phần mềm là Open Source (miễn phí). Cloud LB tính tiền theo giờ sử dụng (Pay-as-you-go).
- *Linh hoạt tuyệt đối:* Có thể cài đặt, cấu hình, thay đổi, xóa bỏ chỉ bằng vài dòng lệnh hoặc click chuột. Dễ dàng tích hợp vào quy trình CI/CD và Automation (Terraform, Ansible).
- *Scalability:* Có thể chạy hàng trăm instance LB song song. Nếu traffic tăng, Cloud Provider tự động cấp thêm tài nguyên cho LB.

*Nhược điểm:*
- *Hiệu năng phụ thuộc CPU:* Do chạy trên phần cứng đa dụng, hiệu năng xử lý gói tin và SSL không thể so sánh với ASIC chuyên dụng (tuy nhiên khoảng cách này đang thu hẹp nhờ CPU hiện đại và kỹ thuật như DPDK).
- *Cần kỹ năng quản trị:* Cần đội ngũ kỹ sư hiểu sâu về Linux, mạng để cấu hình và tối ưu (tuning) chính xác.

=== Phân loại theo tầng xử lý

Đây là cách phân loại quan trọng nhất đối với kỹ sư hệ thống.

==== Layer 4 Load Balancer

L4 LB hoạt động ở tầng Giao vận (Transport Layer) của mô hình OSI. Nó chỉ quan tâm đến các thông tin ở header của gói tin TCP/UDP:
- Địa chỉ IP nguồn (Source IP)
- Địa chỉ IP đích (Destination IP)
- Cổng nguồn (Source Port)
- Cổng đích (Destination Port)
- Giao thức (TCP/UDP)

*Cơ chế hoạt động:*
L4 LB hoạt động chủ yếu dựa trên cơ chế *NAT (Network Address Translation)* hoặc *Packet Forwarding*. Nó *không* mở gói tin để xem nội dung bên trong (data payload). Nó chỉ đơn giản là chuyển tiếp các gói tin.

1.  Client gửi gói tin TCP SYN đến LB.
2.  LB chọn server đích, sửa đổi Destination IP trong header thành IP của server đích (DNAT).
3.  LB chuyển gói tin đi.
4.  Kết nối TCP thực sự được thiết lập trực tiếp giữa Client và Backend Server (hoặc qua LB nhưng LB không can thiệp vào handshake ở mức application).

*Ưu điểm:*
- *Tốc độ cực nhanh:* Vì không cần giải mã nội dung, không cần buffer dữ liệu, độ trễ cực thấp.
- *Tiêu tốn ít tài nguyên:* CPU/RAM sử dụng rất ít. Một L4 LB nhỏ có thể gánh hàng triệu kết nối.
- *Hỗ trợ mọi giao thức:* Bất kể là HTTP, SMTP, FTP, MySQL, MongoDB... miễn là chạy trên TCP/UDP đều load balance được.

*Nhược điểm:*
- *Kém thông minh:* Không thể định tuyến dựa trên nội dung. Ví dụ: Không thể nói "Request `/images` thì về Server A, request `/api` thì về Server B" vì nó không đọc được URL.
- *Không hỗ trợ SSL Termination tốt:* Thường chỉ pass-through SSL (chuyển nguyên gói tin mã hóa cho backend xử lý), bắt buộc backend phải cài chứng chỉ SSL.

*Ví dụ:* LVS (Linux Virtual Server), HAProxy (mode tcp), AWS Network Load Balancer.

==== Layer 7 Load Balancer

L7 LB hoạt động ở tầng Ứng dụng (Application Layer). Nó hiểu và phân tích được nội dung của các giao thức cấp cao như HTTP, HTTPS, HTTP/2, gRPC, WebSocket.

*Cơ chế hoạt động:*
L7 LB hoạt động như một *Reverse Proxy*.
1.  Client thiết lập kết nối TCP và gửi HTTP Request đến LB.
2.  LB nhận request, *giải mã (terminate SSL)*, đọc header, đọc body, cookie.
3.  Dựa trên nội dung (URL path, Host header, Cookie, User-Agent), LB quyết định chọn server nào.
4.  LB thiết lập một kết nối TCP *mới* tới Backend Server và gửi lại request đó.
5.  Backend trả lời cho LB. LB trả lời cho Client.
-> Có 2 kết nối TCP riêng biệt: Client-LB và LB-Backend.

#figure(image("../images/pic5.webp"), caption: [Layer 4 vs Layer 7 load balancer diagram])

*Ưu điểm:*
- *Định tuyến thông minh:*
  - *Path-based routing:* `/video` -> Video Service, `/chat` -> Chat Service.
  - *Host-based routing:* `api.domain.com` -> API Service, `web.domain.com` -> Web Service.
- *Advanced Features:* Caching, Compression (Gzip), Rate Limiting, Authentication, WAF injection, Header modification.
- *Sticky Session:* Dựa vào Cookie để đảm bảo một user luôn kết nối vào đúng 1 server (quan trọng cho stateful app).

*Nhược điểm:*
- *Tiêu tốn tài nguyên:* Giải mã SSL và phân tích HTTP header tốn nhiều CPU và RAM hơn L4.
- *Độ trễ cao hơn:* Do phải xử lý buffer và tạo 2 kết nối TCP.
- *Phức tạp:* Cấu hình nhiều options hơn.

*Ví dụ:* Nginx, HAProxy (mode http), AWS Application Load Balancer, Traefik.

==== Bảng so sánh tổng hợp L4 vs L7

#table(
  columns: (1fr, 1fr, 1fr),
  inset: 10pt,
  align: horizon,
  table.header(
    [*Tiêu chí*], [*Layer 4 LB*], [*Layer 7 LB*]
  ),
  [Dữ liệu xử lý], [IP, Port (TCP/UDP)], [HTTP Header, URL, Cookie, Body],
  [Cơ chế], [Packet Forwarding / NAT], [Reverse Proxy (2 connections)],
  [Hiệu năng], [Rất cao, Low Latency], [Thấp hơn, High Latency (tương đối)],
  [Độ linh hoạt], [Thấp (Chỉ chia tải)], [Cao (Routing, Authen, Cache)],
  [SSL Offloading], [Hạn chế (thường Pass-through)], [Mạnh mẽ (Termination)],
  [Trường hợp dùng], [DNS, Database, Cache, TCP services], [Web App, Microservices API, WebSockets]
)

=== Xu hướng kết hợp

Trong các hệ thống quy mô lớn, người ta thường kết hợp cả hai:
- Bên ngoài cùng (Edge) đặt một lớp *L4 Load Balancer* cực mạnh (như LVS hoặc Hardware LB) để hứng toàn bộ traffic thô và phân phối về các cụm L7.
- Bên trong (Internal) sử dụng *L7 Load Balancer* (như Nginx/Envoy) để định tuyến chi tiết đến các Microservices cụ thể.

Mô hình này tận dụng được sức mạnh xử lý của L4 và trí tuệ định tuyến của L7.