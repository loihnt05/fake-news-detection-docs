== Phân loại Service Discovery
<service_discovery>

=== Giới thiệu chung: Tại sao cần Service Discovery?

Trong kiến trúc Monolithic truyền thống, các ứng dụng thường chạy trên phần cứng vật lý tĩnh. Địa chỉ IP và Port của các máy chủ này hiếm khi thay đổi. Lập trình viên có thể dễ dàng cấu hình cứng (hard-code) trong file `settings.properties` hoặc `config.yaml`.
Ví dụ: `ORDER_SERVICE_URL=http://192.168.1.10:8080`.

Tuy nhiên, trong kỷ nguyên *Cloud-Native* và *Microservices*, mọi thứ thay đổi hoàn toàn:
1.  *Dynamic IPs:* Các service chạy trong Container (Docker/Kubernetes). Mỗi khi deploy lại, scale-up hoặc scale-down, Container cũ bị hủy, Container mới được tạo ra với một IP hoàn toàn mới và ngẫu nhiên.
2.  *Elasticity:* Số lượng instance của một service thay đổi liên tục theo tải (Auto-scaling). Lúc 9h sáng có thể có 5 instance, nhưng đến 12h trưa có thể lên tới 50 instance.

Vấn đề đặt ra: *Làm thế nào Service A (Consumer) biết được IP hiện tại của Service B (Provider) để gửi request?*

Đây chính là bài toán mà *Service Discovery* giải quyết. Nó đóng vai trò như một cuốn "Danh bạ điện thoại" (Phonebook) của hệ thống phân tán, nơi lưu trữ ánh xạ giữa Tên dịch vụ (Logical Name) và Địa chỉ mạng thực tế (Network Location).

== 2. Phân loại các mô hình Discovery

Có hai cách tiếp cận chính để thực hiện Service Discovery: *Client-side Discovery* và *Server-side Discovery*.

==== Client-side Discovery

Trong mô hình này, trách nhiệm tìm kiếm địa chỉ của Service Provider nằm hoàn toàn ở *Service Consumer (Client)*.

*Cơ chế hoạt động:*
1.  *Registry:* Có một Service Registry trung tâm (như Netflix Eureka, Consul, ZooKeeper). Đây là database chứa danh sách IP của tất cả service đang hoạt động.
2.  *Fetch:* Khi Service A khởi động, nó tải toàn bộ (hoặc một phần) danh sách từ Registry về bộ nhớ cục bộ (Local Cache).
3.  *Lookup & Load Balance:* Khi Service A cần gọi Service B:
    - Nó tra cứu trong Local Cache để lấy danh sách các IP của Service B (ví dụ: `[10.0.1.1, 10.0.1.2]`).
    - Nó tự thực hiện thuật toán cân bằng tải (như Round-robin) để chọn 1 IP.
    - Nó gửi request trực tiếp đến IP đó.
4.  *Refresh:* Định kỳ, Service A sẽ hỏi lại Registry để cập nhật danh sách mới.

*Ví dụ điển hình:*
- *Netflix Stack:* Netflix Eureka (Registry) + Netflix Ribbon (Client-side Load Balancer). Client Java sử dụng thư viện Ribbon để tự chọn server.

*Ưu điểm:*
- *Ít hop mạng (No extra hop):* Client gọi thẳng cho Server, không đi qua Load Balancer trung gian, giảm độ trễ (Latency).
- *Thông minh:* Client có thể đưa ra quyết định load balancing thông minh dựa trên logic riêng (ví dụ: Hash theo UserID, chọn server có latency thấp nhất mà nó từng đo được).
- *Không phụ thuộc hạ tầng:* Code chạy được ở mọi nơi, không cần Load Balancer phần cứng hay Kubernetes Service.

*Nhược điểm:*
- *Coupling:* Logic tìm kiếm và load balancing dính liền vào code của Client.
- *Đa ngôn ngữ (Polyglot challenge):* Nếu hệ thống dùng Java, Go, Node.js, Python... bạn phải viết lại thư viện Client-side Discovery cho TỪNG ngôn ngữ. Việc duy trì các thư viện này đồng bộ tính năng rất tốn kém.

#figure(image("../images/pic9.jpg"), caption: [Client Side Service Discovery Diagram])

==== Server-side Discovery

Trong mô hình này, Client không hề biết về Registry. Client chỉ gọi đến một địa chỉ trung gian (Load Balancer).

*Cơ chế hoạt động:*
1.  *Abstraction:* Client A muốn gọi Service B. Nó chỉ cần gọi đến một địa chỉ ảo (Virtual IP - VIP) hoặc DNS chung, ví dụ: `http://order-service`.
2.  *Load Balancer (LB):* Request đi đến một Router/Load Balancer.
3.  *Lookup:* LB này (chứ không phải Client) sẽ truy vấn Service Registry để lấy danh sách IP thực của Service B.
4.  *Forward:* LB chọn một IP và chuyển tiếp (proxy) request đến đó.

*Ví dụ điển hình:*
- *Kubernetes Service:* Kube-proxy hoặc Ingress Controller đóng vai trò LB. Client chỉ gọi Service Name, K8s tự định tuyến.
- *AWS Elastic Load Balancer (ELB):* ELB tự động biết các EC2 instance nào đang sống.

*Ưu điểm:*
- *Client đơn giản:* Client không cần logic phức tạp, chỉ cần gửi HTTP Request chuẩn. Không phụ thuộc ngôn ngữ lập trình.
- *Tập trung hóa:* Logic Load Balancing, SSL Termination, Caching nằm tập trung ở LB, dễ quản lý và upgrade.

*Nhược điểm:*
- *Extra Hop:* Thêm một chặng mạng (Client -> LB -> Server) nên độ trễ sẽ cao hơn so với gọi trực tiếp.
- *SPOF (Single Point of Failure):* Nếu LB chết, toàn bộ giao tiếp ngưng trệ (tuy nhiên các LB hiện đại thường có HA).
- *Phụ thuộc hạ tầng:* Khó mang code đi chạy ở môi trường khác nếu môi trường đó không cung cấp sẵn LB tương ứng.

#figure(image("../images/pic10.png"), caption: [Server Side Service Discovery Diagram])

=== Bảng so sánh tóm tắt

#table(
  columns: (1fr, 1fr, 1fr),
  inset: 10pt,
  align: horizon,
  table.header(
    [*Tiêu chí*], [*Client-side Discovery*], [*Server-side Discovery*]
  ),
  [Vị trí Logic], [Nằm trong Code ứng dụng], [Nằm ở Hạ tầng (LB/Router)],
  [Số bước mạng], [1 Hop (Thẳng)], [2 Hops (Qua trung gian)],
  [Đa ngôn ngữ], [Khó (Cần nhiều thư viện)], [Dễ (HTTP chuẩn)],
  [Ví dụ], [Eureka + Ribbon, Consul], [K8s Service, AWS ELB, Nginx]
)
