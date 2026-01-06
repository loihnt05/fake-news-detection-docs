== Phân loại hình thức Register 
 <registration_patterns>

Service Registry chỉ hữu ích khi dữ liệu trong nó là chính xác và tươi mới (fresh). Các service instances sinh ra và chết đi liên tục, vậy làm sao Registry cập nhật kịp thời? Có hai mẫu thiết kế chính:

=== Self-registration

Đây là cách tiếp cận phổ biến nhất trong thế hệ Microservices đầu tiên (như Spring Cloud Netflix).

==== Mô tả chi tiết
Trong mô hình này, chính bản thân Service Instance chịu trách nhiệm "nói chuyện" với Service Registry.

*Quy trình vòng đời:*
1.  *Startup:* Khi service khởi động, nó gọi API của Registry (ví dụ: `POST /register`) để đăng ký thông tin: IP, Port, Service Name, Health Check URL.
2.  *Heartbeat (Nhịp tim):* Sau khi đăng ký, Service phải liên tục gửi tín hiệu (ví dụ mỗi 30 giây) để báo "Tôi vẫn còn sống". Đây gọi là cơ chế *Renew Lease*.
3.  *Shutdown:* Khi service tắt một cách chủ động (Graceful Shutdown), nó gọi API `DELETE /register` để tự gỡ mình khỏi danh sách.
4.  *Eviction:* Nếu service bị crash (tắt đột ngột) và không gửi Heartbeat trong một khoảng thời gian (ví dụ 90 giây), Registry sẽ tự động coi nó là đã chết và xóa khỏi danh sách.

==== Ví dụ
- *Netflix Eureka Client:* Một thư viện Java nhúng trong ứng dụng Spring Boot. Nó tự động làm mọi việc trên ở background thread.

==== Ưu điểm
- *Đơn giản:* Không cần thêm thành phần hạ tầng nào khác. Logic nằm gọn trong ứng dụng.
- *Trạng thái chi tiết:* Service biết rõ trạng thái của chính mình (ví dụ: STARTING, UP, DOWN, OUT_OF_SERVICE) để báo cáo chính xác cho Registry.

=== Nhược điểm
- *Coupling:* Code ứng dụng bị dính chặt với SDK của Registry.
- *Lặp code:* Phải implement logic đăng ký/heartbeat cho từng ngôn ngữ lập trình khác nhau (Java, Node, Go...).
- *Zombie instances:* Nếu service vẫn chạy (gửi heartbeat) nhưng logic nghiệp vụ bị treo (deadlock) hoặc DB connection pool bị đầy, Registry vẫn nghĩ nó "khỏe" và gửi traffic vào -> Lỗi. (Cần Health Check sâu hơn).

=== Third-party registration

Mô hình này tách biệt hoàn toàn trách nhiệm đăng ký ra khỏi ứng dụng. Đây là xu hướng của các hệ thống Container Orchestration (Kubernetes) và Service Mesh.

=== Mô tả chi tiết
Service Instance không hề biết sự tồn tại của Service Registry. Thay vào đó, một thành phần quản lý hạ tầng gọi là *Registrar* (hoặc Service Manager) sẽ làm thay việc này.

*Cơ chế hoạt động:*
1.  *Event Listening:* Registrar lắng nghe các sự kiện từ môi trường chạy (Docker Events, Kubernetes Events).
2.  *Detection:* Khi một container mới được khởi tạo (Container Start), Registrar phát hiện ra sự kiện, lấy IP/Port của container đó.
3.  *Registration:* Registrar gọi API của Service Registry để đăng ký thay cho container.
4.  *Health Check:* Registrar (hoặc Registry) chủ động ping container định kỳ để kiểm tra sức khỏe.
5.  *Deregistration:* Khi container bị hủy (Container Die), Registrar phát hiện sự kiện và gỡ bỏ thông tin khỏi Registry.

=== Ví dụ
- *Registrator (Open source):* Một container chạy song song trên mỗi host Docker. Nó lắng nghe `docker.sock` để tự động đăng ký các container khác vào Consul hoặc Etcd.
- *Kubernetes:* Khi Pod khởi động, Kubelet và Control Plane tự động cập nhật Endpoints object (Registry của K8s). Pod không cần làm gì cả.
- *AWS Autoscaling Group:* Tự động đăng ký EC2 instance mới vào ELB Target Group.

=== Ưu điểm
- *Decoupling tuyệt đối:* Service code hoàn toàn sạch sẽ, không chứa logic hạ tầng.
- *Đa ngôn ngữ:* Không cần viết SDK cho từng ngôn ngữ. Bất kỳ ứng dụng nào chạy trong container đều được tự động quản lý.
- *Chính xác:* Registrar thường gắn liền với nền tảng (Platform), nên nó biết chính xác khi nào một process thực sự sống hay chết tốt hơn là bản thân process đó.

=== Nhược điểm
- *Phụ thuộc hạ tầng:* Cần triển khai và duy trì thêm thành phần Registrar. Nó phải có độ sẵn sàng cao (High Availability), vì nếu Registrar chết, không ai được đăng ký mới nữa.

=== Bảng so sánh

#table(
  columns: (1fr, 1fr, 1fr),
  inset: 10pt,
  align: horizon,
  table.header(
    [*Đặc điểm*], [*Self-registration*], [*Third-party registration*]
  ),
  [Người thực hiện], [Code ứng dụng (SDK)], [Infrastructure Component],
  [Độ phức tạp App], [Cao (phải nhúng SDK)], [Thấp (Zero config)],
  [Đa ngôn ngữ], [Khó khăn], [Dễ dàng],
  [Môi trường], [Thường dùng cho VM/Bare-metal], [Chuẩn cho Container/K8s]
)
