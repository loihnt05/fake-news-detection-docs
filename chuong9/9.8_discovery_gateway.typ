== Service Discovery, API Gateway & Service Mesh <discovery_gateway>

=== Service Discovery

Trong môi trường Container (K8s) động, IP của các service thay đổi liên tục. Service A không thể hardcode IP của Service B.

- *Cơ chế:*
    - *Service Registry:* Nơi lưu danh sách IP của các service đang sống. (Consul, Etcd, Eureka).
    - *Client-side Discovery:* Service A tự hỏi Registry lấy IP của B rồi gọi.
    - *Server-side Discovery:* Service A gọi qua Load Balancer (LB), LB hỏi Registry rồi forward. (K8s Service dùng cách này).

=== API Gateway

Cổng vào duy nhất (Single Entry Point) cho toàn bộ hệ thống Microservices.

- *Công cụ:* Kong, Nginx, APISIX, Tyk, hoặc tự viết bằng NestJS/Express.
- *Chức năng chính:*
    1.  *Routing:* `/users` -> User Service, `/orders` -> Order Service.
    2.  *Authentication Offloading:* Kiểm tra JWT Token tại Gateway. Nếu hợp lệ mới cho vào trong. Backend Service không cần lo verify token nữa.
    3.  *Rate Limiting:* Chống DDOS, giới hạn request/s cho từng user.
    4.  *Protocol Translation:* Chuyển đổi REST (bên ngoài) sang gRPC (bên nội bộ).
    5.  *Aggregation (BFF - Backend For Frontend):* Gọi 3 service con và gộp kết quả lại trả về cho Frontend 1 lần duy nhất (GraphQL thường dùng ở đây).

=== Envoy + Sidecar Patterns

Envoy là một L7 Proxy hiệu năng cao (C++).
Trong mô hình *Sidecar*:
- Mỗi Microservice (Node.js) chạy kèm một container Envoy (localhost).
- Node.js App không gọi trực tiếp ra mạng, mà gọi qua Envoy localhost.
- Envoy lo việc Retries, Timeout, Circuit Breaker, Tracing, mTLS.
- *Lợi ích:* Tách biệt logic mạng (Network Concerns) ra khỏi logic nghiệp vụ (Business Logic). Lập trình viên Node.js không cần code chức năng Retry/Circuit Breaker nữa.

=== Service Mesh

Là một lớp hạ tầng (Infrastructure Layer) quản lý giao tiếp giữa các service.
- *Control Plane (Istiod):* Quản lý cấu hình toàn bộ hệ thống proxy.
- *Data Plane (Envoy Proxies):* Thực hiện chuyển tiếp gói tin.
- *Chức năng:*
    - *Observability:* Tự động vẽ bản đồ service (Service Map), đo latency, tỉ lệ lỗi mà không cần sửa code app.
    - *Security:* Tự động mã hóa toàn bộ giao tiếp nội bộ bằng mTLS.
    - *Traffic Control:* Canary Deployment (Chuyển 1% traffic sang version mới), A/B Testing.