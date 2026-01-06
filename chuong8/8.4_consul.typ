== Consul <consul>

Trong một hệ thống phân tán với hàng trăm Microservices và hàng ngàn instances thay đổi liên tục, việc biết "Service A đang nằm ở IP nào?" là bài toán sống còn. Consul, sản phẩm của HashiCorp, là giải pháp hàng đầu cho vấn đề này.

=== Mô tả và Kiến trúc

Consul là một công cụ phân tán, có độ sẵn sàng cao (High Availability), cung cấp giải pháp đầy đủ cho Service Discovery, Configuration và Segmentation.

==== Kiến trúc Client-Server
Consul hoạt động theo mô hình cụm (Cluster):
- *Consul Servers:* (Thường 3-5 node) Chịu trách nhiệm lưu trữ dữ liệu, duy trì trạng thái Cluster và thực hiện bầu chọn Leader (dùng thuật toán Raft Consensus).
- *Consul Clients (Agents):* Chạy trên *mọi node* trong hệ thống. Agent rất nhẹ, chịu trách nhiệm đăng ký service chạy trên node đó, chạy health check và chuyển tiếp câu hỏi (query) lên Server.

==== Giao thức Gossip
Các Consul Agent nói chuyện với nhau bằng giao thức *SWIM (Gossip Protocol)*.
- Thay vì Server phải ping từng Agent (tốn tải trung tâm), các Agent tự "tám chuyện" với nhau để lan truyền thông tin: "Này, Node A vừa chết đấy", "Node B vừa tham gia".
- Giúp hệ thống scale lên hàng ngàn node mà không làm quá tải Consul Server.

=== Chức năng chính

==== Service Discovery
Đây là chức năng cốt lõi.
- *Đăng ký (Registration):* Khi Service "Order" khởi động trên IP `10.0.0.1`, Consul Agent tại đó sẽ đăng ký với Consul Server: "Có một instance của Order tại 10.0.0.1".
- *Khám phá (Discovery):* Service "Web" muốn gọi "Order". Nó có 2 cách hỏi Consul:
    1.  *DNS Interface:* `dig order.service.consul`. Consul trả về danh sách IP `[10.0.0.1, 10.0.0.2]`. -> Cực kỳ tiện lợi, không cần sửa code ứng dụng, chỉ cần cấu hình DNS server trỏ về Consul.
    2.  *HTTP API:* `GET /v1/catalog/service/order`. Trả về JSON chi tiết.

==== Health Checking
Consul không chỉ trả về IP, nó trả về *IP của các service đang khỏe mạnh*.
- *Cơ chế:* Khi đăng ký, Service cung cấp một Health Check (ví dụ: `curl http://localhost:8080/health` mỗi 10s).
- *Hoạt động:* Consul Agent thực hiện check này liên tục. Nếu API trả về 500 hoặc Timeout, Agent báo cáo lên Server.
- *Tự động cách ly:* Khi Service "Web" hỏi địa chỉ "Order", Consul sẽ tự động *loại bỏ* các IP đang bị lỗi khỏi danh sách trả về. -> Giúp hệ thống tự phục hồi, tránh gửi traffic vào hố đen.

==== KV Store
Consul cung cấp một kho lưu trữ Key-Value phân tán.
- Dùng để lưu cấu hình động (Dynamic Configuration).
- Ứng dụng có thể lắng nghe (Watch) sự thay đổi của Key. Khi Admin sửa config trên Consul, ứng dụng tự động nhận được giá trị mới mà không cần restart (Hot Reload).

==== Service Mesh
Consul có thể hoạt động như một Control Plane cho Service Mesh, tự động cấu hình các Sidecar Proxy (Envoy) để mã hóa traffic (mTLS) giữa các service.

=== Ưu điểm so với các giải pháp khác

#table(
  columns: (1fr, 1fr, 1fr),
  inset: 10pt,
  align: horizon,
  table.header(
    [*Tiêu chí*], [*Consul*], [*Netflix Eureka*]
  ),
  [Kiến trúc], [CP (Consistency - Raft)], [AP (Availability - Peer to Peer)],
  [Health Check], [Đa dạng (HTTP, TCP, Script, Docker)], [Chỉ Heartbeat đơn giản],
  [Giao diện], [DNS & HTTP API], [Chỉ HTTP API (Java Client)],
  [Đa DataCenter], [Hỗ trợ Native (Federation)], [Không hỗ trợ tốt],
  [Non-Java], [Hỗ trợ tốt mọi ngôn ngữ (qua DNS/Sidecar)], [Khó khăn (Cần viết Client wrapper)]
)

*Kết luận:* Consul mạnh mẽ và đa năng hơn Eureka rất nhiều, đặc biệt trong môi trường không phải Java (Non-JVM) hoặc môi trường lai (Hybrid Cloud/VM + K8s).