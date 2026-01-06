== Các giải pháp hạ tầng hỗ trợ giao tiếp <infrastructure>

Microservices tạo ra hàng nghìn điểm kết nối động. Chúng ta không thể hard-code IP của server vào file cấu hình (ví dụ: `ORDER_SERVICE_URL=http://192.168.1.50:8080`) vì các IP này thay đổi liên tục khi container khởi động lại hoặc scale up/down. Hạ tầng hỗ trợ là bắt buộc.

=== Service Discovery

Là cơ chế giúp Microservice A tìm thấy địa chỉ (IP + Port) của Microservice B một cách tự động.

==== Cơ chế hoạt động:
1.  *Service Registry (Cuốn danh bạ):* Là một database chứa danh sách các service đang hoạt động. (Ví dụ: Eureka, Consul, Zookeeper, Etcd).
2.  *Registration:* Khi Service B khởi động, nó tự đăng ký (hoặc được đăng ký) IP của mình vào Registry. Nó phải gửi heartbeat định kỳ để báo "Tôi còn sống".
3.  *Discovery:* Khi Service A muốn gọi B, nó hỏi Registry lấy IP của B.

==== Hai mô hình Discovery:
1.  *Client-side Discovery (Ví dụ: Netflix Eureka + Ribbon):*
    - Service A tự gọi Registry, lấy danh sách IP của B (`[10.1, 10.2]`), rồi tự chọn 1 IP (Load Balancing) để gọi.
    - *Ưu:* Không cần thêm hop mạng trung gian. Logic thông minh nằm ở client.
    - *Nhược:* Code của Service A bị dính chặt với thư viện Discovery. Phải viết lại cho từng ngôn ngữ (Java, Go, Node).

2.  *Server-side Discovery (Ví dụ: Kubernetes Service, AWS ELB):*
    - Service A gọi đến một địa chỉ ảo (DNS/VIP), ví dụ `http://order-service`.
    - Hạ tầng (Load Balancer/Kube-proxy) sẽ nhận request, tra cứu Registry và forward đến instance thật.
    - *Ưu:* Trong suốt với lập trình viên. Không phụ thuộc ngôn ngữ.
    - *Nhược:* Thêm 1 hop mạng. Phụ thuộc vào hạ tầng cloud/k8s.

=== Sidecar & Service Mesh

Khi số lượng services tăng lên, các logic về giao tiếp (Retries, Timeout, Circuit Breaker, Tracing, Security) bị lặp lại trong code của từng service. Service Mesh sinh ra để tách logic này ra khỏi code nghiệp vụ.

==== Pattern Sidecar:
Thay vì Service A gọi trực tiếp Service B, ta gắn kèm mỗi service một "Sidecar Proxy" (ví dụ: Envoy, Linkerd-proxy) chạy song song (cùng localhost).
- A gọi localhost:proxy -> Proxy A gọi qua mạng -> Proxy B -> B.

==== Service Mesh (Istio, Linkerd, Consul Connect):
Là một lớp hạ tầng chuyên dụng (Infrastructure Layer) để quản lý giao tiếp giữa các service. Nó bao gồm:
- *Data Plane:* Tập hợp các Sidecar Proxy. Thực hiện chuyển gói tin.
- *Control Plane:* Trung tâm điều khiển, cấu hình policy cho toàn bộ Data Plane.

==== Tính năng chính:
- *Traffic Management:* Canary deployment (chuyển 1% traffic sang version mới), A/B testing, Mirroring.
- *Resilience:* Tự động Retry, Timeout, Circuit Breaker mà không cần sửa 1 dòng code ứng dụng.
- *Security (mTLS):* Tự động mã hóa giao tiếp giữa các service (Mutual TLS). Service A biết chắc chắn nó đang nói chuyện với Service B chứ không phải kẻ giả mạo.

=== Schema Registry

Trong giao tiếp Event-Driven (Kafka) dùng Avro/Protobuf, Producer và Consumer cần thống nhất cấu trúc dữ liệu (Schema).
- Producer gửi 1 chuỗi byte nhị phân. Consumer cần Schema để giải mã.
- Nếu Producer đổi Schema (thêm field mới) mà Consumer chưa biết -> Lỗi (Parsing Exception).

*Schema Registry (Ví dụ: Confluent Schema Registry):*
- Là kho lưu trữ version của các Schema.
- Producer gửi tin nhắn kèm theo `Schema ID` (ví dụ: ID=1).
- Consumer đọc tin nhắn, thấy `ID=1`, hỏi Registry lấy Schema #1 về để giải mã.
- Đảm bảo *Backward/Forward Compatibility* (Tính tương thích ngược/xuôi) khi nâng cấp hệ thống.

=== Queue / Stream Broker

Hạ tầng Message Broker cần được cấu hình High Availability (HA) để không trở thành điểm chết (SPOF).
- *RabbitMQ Cluster:* Mirrored Queues (copy queue ra nhiều node).
- *Kafka Cluster:* Partition Replication. Mỗi partition có 1 Leader và nhiều Follower. Nếu Leader chết, Follower lên thay. Controller node (ZooKeeper/KRaft) quản lý metadata.

*Lưu ý:* Việc vận hành Broker rất phức tạp (đặc biệt là Kafka). Xu hướng hiện nay là dùng Managed Services (Confluent Cloud, Amazon MSK) để giảm tải cho team vận hành.