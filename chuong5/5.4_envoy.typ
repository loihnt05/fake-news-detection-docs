== Envoy Proxy <envoy_proxy>

=== Giới thiệu

*Envoy* là một L7 Proxy và Communication Bus hiệu năng cao, mã nguồn mở, được thiết kế ban đầu bởi Lyft. Nó được xây dựng dựa trên triết lý: *"Mạng phải trong suốt (transparent) đối với ứng dụng. Khi có sự cố mạng và ứng dụng, ta phải dễ dàng xác định được nguyên nhân nằm ở đâu."*

==== Điểm khác biệt so với Nginx/HAProxy
Mặc dù Nginx và HAProxy rất mạnh, nhưng Envoy được sinh ra trong kỷ nguyên Cloud-Native với những đặc điểm vượt trội:
1.  *Dynamic Configuration (xDS API):* Đây là "vũ khí bí mật" của Envoy. Nginx thường cần reload process (hot reload) để nhận config mới. Envoy có thể cập nhật config (thêm route, thêm cluster, đổi weight) *theo thời gian thực* thông qua API mà không cần reload, không rớt kết nối nào. Điều này cực kỳ quan trọng trong môi trường Kubernetes biến động.
2.  *L3/L4/L7 Proxy:* Envoy hoạt động tốt ở cả tầng TCP/UDP và tầng HTTP/gRPC.
3.  *First-class gRPC support:* Envoy hỗ trợ gRPC, HTTP/2 từ trong trứng nước.
4.  *Observability:* Envoy sinh ra hàng ngàn metrics chi tiết về traffic, giúp việc debug hệ thống phân tán trở nên khả thi.

=== Kiến trúc cốt lõi

Kiến trúc của Envoy dựa trên luồng xử lý sự kiện (Event-driven) và pipeline.

==== Listeners
Listener là thành phần mở port để lắng nghe kết nối từ bên ngoài (Downstream).
- Ví dụ: Mở port 80 để hứng HTTP traffic, mở port 443 cho HTTPS.
- Một Envoy instance có thể chạy nhiều Listener cùng lúc.

==== Filter Chains
Khi một kết nối được thiết lập đến Listener, nó sẽ đi qua một chuỗi các Filters (Pipeline). Đây là nơi xảy ra các logic xử lý.

Có 3 tầng Filters chính:
1.  *Listener Filters:* Xử lý metadata của kết nối ngay khi vừa accept (ví dụ: TLS Inspector để xem SNI là gì).
2.  *Network Filters (L3/L4):* Xử lý ở tầng TCP. Filter quan trọng nhất ở đây là *HTTP Connection Manager*.
    - *Redis Proxy Filter:* Biến Envoy thành Redis Proxy.
    - *Mongo Proxy Filter:* Hiểu protocol MongoDB.
    - *TCP Proxy:* Forward raw TCP data.
3.  *HTTP Filters (L7):* Nếu Network Filter là `HTTP Connection Manager`, nó sẽ đẩy dữ liệu lên tầng L7 để chạy tiếp các HTTP Filters.
    - *Router Filter:* Định tuyến URL.
    - *Rate Limit Filter:* Giới hạn băng thông.
    - *Cors Filter:* Xử lý CORS.
    - *Gzip Filter:* Nén dữ liệu.

==== HTTP Connection Manager (HCM)
Đây là Network Filter quan trọng nhất, biến Envoy từ một L4 Proxy thành L7 Proxy thông minh.
- Nó parse HTTP/1.1, HTTP/2 và gRPC.
- Nó quản lý Access Log, Tracing, và điều phối luồng request qua các HTTP Filters.

==== Routes
Nằm trong Router Filter (HTTP Layer). Quy định luật đi đường:
- "Nếu path bắt đầu bằng `/api/v1/user` -> chuyển đến Cluster `user_service`".
- "Nếu header `x-canary: true` -> chuyển đến Cluster `user_service_v2`".

==== Clusters
Cluster là một nhóm các máy chủ backend (Upstream hosts) cung cấp cùng một dịch vụ.
- Cluster `user_service` có thể bao gồm 3 IP: `10.0.1.1`, `10.0.1.2`, `10.0.1.3`.
- Envoy thực hiện *Load Balancing* (Round Robin, Least Request, Maglev...) ngay tại đây để chọn ra 1 IP cụ thể (Endpoint) để gửi request.

==== Endpoints
Là địa chỉ IP và Port thực tế của một instance.

==== xDS APIs (Discovery Services)
Đây là cơ chế Dynamic Configuration. Thay vì viết file `envoy.yaml` tĩnh, Envoy kết nối tới một *Management Server* (như Istio Pilot) để lấy config động:
- *LDS (Listener Discovery Service):* "Hãy mở thêm port 9090 đi".
- *RDS (Route Discovery Service):* "Vừa có thêm rule routing mới cho `/payment`".
- *CDS (Cluster Discovery Service):* "Có thêm service `payment` vừa online".
- *EDS (Endpoint Discovery Service):* "Service `payment` vừa scale-up, thêm IP `10.0.2.5` vào danh sách nhé".

Nhờ xDS, Envoy có thể thay đổi hành vi trong mili-giây mà không cần con người can thiệp.

==== Thread Model
Envoy sử dụng mô hình *Single Process, Multi-threaded*.
- Một Main Thread quản lý xDS và phối hợp.
- Nhiều Worker Threads (mỗi thread bind vào 1 CPU core).
- Mỗi Worker Thread hoạt động độc lập, có Event Loop riêng (Non-blocking I/O).
- *Zero-lock:* Các Worker Thread hầu như không chia sẻ bộ nhớ, không cần Lock, giúp hiệu năng scale tuyến tính theo số core CPU.

=== Tóm tắt luồng đi của một Request
1.  Request đến Port 80 -> *Listener* bắt lấy.
2.  Đi qua *Network Filters* -> Gặp *HTTP Connection Manager*.
3.  Được parse thành HTTP Request.
4.  Đi qua *HTTP Filters* (Auth, Rate Limit...).
5.  Đến *Router Filter* -> Match URL -> Chọn *Cluster* đích.
6.  Trong Cluster, dùng Load Balancer chọn một *Endpoint* (IP).
7.  Envoy forwarding request đến IP đó.
8.  Nhận Response và trả ngược lại theo đường cũ.
