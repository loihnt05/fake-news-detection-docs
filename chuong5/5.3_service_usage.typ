== Sử dụng Service 
<service_usage>

Sau khi các services đã tìm thấy nhau (Discovery), câu hỏi tiếp theo là: *Client (Mobile App, Web App) nên giao tiếp với các services này như thế nào?*

=== Direct Client-to-Microservice

Đây là cách đơn giản nhất nhưng cũng tiềm ẩn nhiều rủi ro nhất.

==== Mô tả
Mobile App hoặc Web Browser gửi request trực tiếp đến từng Microservice.
- Để lấy thông tin đơn hàng: `GET http://order-service.api.com/orders/1`
- Để lấy thông tin người dùng: `GET http://user-service.api.com/users/1`
- Để lấy thông tin sản phẩm: `GET http://product-service.api.com/products/1`

==== Nhược điểm chí mạng
1.  *Chattiness :* Để hiển thị một màn hình "Chi tiết đơn hàng", App phải gửi 3-5 requests qua mạng Internet (vốn chậm và không ổn định). Điều này làm tăng độ trễ và tốn pin thiết bị di động.
2.  *Coupling:* Client biết quá rõ về kiến trúc nội bộ của Backend. Nếu Backend tách `Product Service` thành `Inventory Service` và `Pricing Service`, Client phải sửa code và update App (điều rất khó với Mobile App).
3.  *Security:* Tất cả Microservices phải expose ra Internet (Public IP). Việc bảo mật hàng chục endpoint khó hơn nhiều so với bảo vệ một cổng duy nhất.
4.  *Protocol:* Một số service dùng gRPC hoặc AMQP (Message Queue) không thân thiện với Web Browser.

=== Composite UI

Thay vì gọi API, Client tự lắp ghép giao diện từ các mảnh nhỏ (Fragments/Micro-frontends).

==== Server-side Composition
- Một trang web HTML được render từ phía server (Server-Side Rendering - SSR).
- Template engine (như Thymeleaf, Next.js) sẽ gọi tới User Service, Order Service... để lấy data, fill vào HTML template, rồi trả về *một trang HTML hoàn chỉnh* cho Browser.
- *Ưu điểm:* Tốt cho SEO, tải trang nhanh (First Contentful Paint).

=== Client-side Composition
- Mỗi team Microservice phát triển một UI component riêng (ví dụ: Team Order làm Web Component `<order-list>`).
- Trang chính (Shell/Container) chỉ là một khung rỗng, nó load các Web Component này về và ghép lại.
- *Ưu điểm:* Các team UI độc lập.

== 3. API Gateway

Đây là pattern tiêu chuẩn (De-facto standard) cho Microservices hiện đại.

=== Mô tả
API Gateway là một server đứng chắn giữa Client và hệ thống Microservices bên trong. Nó đóng vai trò là điểm vào duy nhất (Single Entry Point) cho mọi request từ bên ngoài.

=== Các chức năng cốt lõi

1.  *Request Routing:*
    - Client gọi: `GET /api/orders`
    - Gateway trỏ tới: `http://order-service-cluster:8080/v1/orders`
    - Client gọi: `GET /api/users`
    - Gateway trỏ tới: `http://user-service-cluster:5000/users`
    - *Lợi ích:* Ẩn giấu cấu trúc mạng nội bộ. Client chỉ cần nhớ 1 domain duy nhất.

2.  *API Composition (Tổng hợp API - Aggregator):*
    - Client gửi 1 request: `GET /api/order-details/1`
    - Gateway nhận request, sau đó âm thầm gửi 3 request song song tới `Order Service`, `User Service`, `Product Service`.
    - Gateway nhận 3 kết quả, gộp (merge) chúng lại thành một JSON duy nhất và trả về cho Client.
    - *Lợi ích:* Giảm số lượng round-trip mạng cho Client (giải quyết vấn đề Chattiness).

3.  *Protocol Translation:*
    - Bên ngoài dùng HTTP/REST thân thiện.
    - Bên trong dùng gRPC hoặc AMQP hiệu năng cao.
    - Gateway thực hiện chuyển đổi JSON <-> Protobuf.

4.  *Cross-cutting Concerns:*
    Thay vì implement Authen ở 100 services, ta chỉ làm 1 lần ở Gateway (Offloading):
    - *Authentication & Authorization:* Kiểm tra JWT Token, xác thực OAuth2.
    - *Rate Limiting:* Chống DDOS, giới hạn 100 req/s cho mỗi IP.
    - *SSL Termination:* Giải mã HTTPS tại Gateway, giao tiếp nội bộ dùng HTTP thường cho nhanh.
    - *Caching:* Cache các response tĩnh.
    - *Logging & Monitoring:* Ghi lại tất cả traffic ra vào hệ thống.

=== Pattern: Backend for Frontend (BFF)

Một biến thể của API Gateway. Thay vì 1 Gateway khổng lồ cho tất cả, ta tạo ra các Gateway nhỏ chuyên biệt:
- *Web BFF:* Tối ưu cho Web Desktop (Data nhiều, màn hình to).
- *Mobile BFF:* Tối ưu cho iOS/Android (Data ít, JSON gọn nhẹ, gộp nhiều API).
- *Public API BFF:* Cho đối tác bên thứ 3 (Rate limit chặt chẽ, Document chuẩn).

=== Lựa chọn công nghệ
- *Java:* Spring Cloud Gateway, Zuul (Netflix).
- *Go:* Kong, Tyk.
- *Node.js:* Express Gateway, Fastify (thích hợp làm BFF vì xử lý JSON cực nhanh và code I/O non-blocking).
- *Nginx/Envoy:* Hiệu năng cực cao, thường dùng làm Ingress Controller trong Kubernetes.

=== Ưu điểm
- Bảo mật tốt hơn (Giảm Attack Surface).
- Đơn giản hóa Client.
- Tối ưu hóa hiệu năng mạng.

=== Nhược điểm
- *SPOF:* Gateway chết là cả hệ thống "mất mạng". Cần triển khai HA Cluster.
- *Nút thắt cổ chai (Bottleneck):* Xử lý quá nhiều logic (Aggregation, Auth) có thể làm Gateway chậm, ảnh hưởng toàn hệ thống.
- *Phức tạp vận hành:* Thêm một lớp phải quản lý, monitor.
