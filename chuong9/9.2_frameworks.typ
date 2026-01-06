== Framework & Kiến trúc ứng dụng <frameworks_architecture>

Trong hệ sinh thái Node.js, việc chọn đúng Framework và kiến trúc ngay từ đầu quyết định 50% sự thành bại của dự án về lâu dài.

=== NestJS

NestJS hiện là framework số 1 cho các ứng dụng Node.js quy mô doanh nghiệp (Enterprise). Nó được xây dựng trên nền tảng TypeScript và lấy cảm hứng mạnh mẽ từ Angular (Frontend) và Spring Boot (Java Backend).

#figure(image("../images/pic17.webp"), caption: [Nestjs Module Architecture])

==== Đặc điểm cốt lõi
- *Opinionated:* Khác với Express "muốn làm gì thì làm", NestJS áp đặt một cấu trúc thư mục và quy tắc code rõ ràng. Điều này giúp team lớn dễ dàng làm việc chung, code nhất quán.
- *Dependency Injection (DI):* Hệ thống DI mạnh mẽ tích hợp sẵn, giúp quản lý sự phụ thuộc và dễ dàng viết Unit Test.
- *Platform Agnostic:* NestJS mặc định dùng Express bên dưới, nhưng có thể chuyển sang Fastify để tăng hiệu năng chỉ bằng vài dòng config.

==== Building Blocks

1.  *Modules:*
    - Đơn vị tổ chức code. Mỗi ứng dụng có ít nhất một `AppModule`.
    - Module gói gọn các Controller, Provider và export các service cần thiết cho module khác dùng.
    - Giúp chia nhỏ ứng dụng Monolith thành các khối *Modular Monolith*.

2.  *Controllers:*
    - Chịu trách nhiệm tiếp nhận Request và trả về Response.
    - Định nghĩa Routing (Path, HTTP Method).
    - Sử dụng DTO (Data Transfer Object) để validate dữ liệu đầu vào.

3.  *Providers / Services:*
    - Nơi chứa logic nghiệp vụ (Business Logic).
    - Có thể được inject vào Controller hoặc các Service khác.
    - Ví dụ: `UserService`, `AuthService`, `PrismaService`.

4.  *Interceptors, Pipes, Guards:*
    - *Guards:* Xác thực (Authentication) và Phân quyền (Authorization). Chạy trước Controller. Quyết định request có được đi tiếp hay không. (Ví dụ: `JwtAuthGuard`).
    - *Pipes:* Chuyển đổi (Transform) và Xác thực (Validate) dữ liệu đầu vào. (Ví dụ: `ValidationPipe` dùng `class-validator`).
    - *Interceptors:* Can thiệp vào quá trình trước khi xử lý và sau khi trả về (AOP - Aspect Oriented Programming). Dùng để logging, transform response format, caching.

==== Integration
NestJS hỗ trợ "out-of-the-box" cho:
- *Microservices:* Hỗ trợ Transport Layer qua TCP, Redis, Kafka, gRPC, RabbitMQ, MQTT.
- *GraphQL:* Code-first hoặc Schema-first approach với Apollo Server.
- *WebSockets:* Gateway cho Real-time apps.

=== Express vs Fastify

Dành cho các dự án nhỏ, microservices đơn giản hoặc khi cần tối ưu hiệu năng cực đại.

==== Express
- *Vị thế:* "Ông tổ" của Node.js framework. Cộng đồng lớn nhất, plugin nhiều nhất.
- *Đặc điểm:* Tối giản, linh hoạt. Không có DI, không cấu trúc bắt buộc.
- *Vấn đề:*
    - Performance trung bình (do kiến trúc cũ, tạo nhiều closure object).
    - Không hỗ trợ tốt Async/Await trong Middleware (phiên bản v4 cũ, v5 đã cải thiện).

==== Fastify
- *Vị thế:* Kẻ thách thức Express về tốc độ.
- *Đặc điểm:*
    - *Schema-based:* Sử dụng JSON Schema để validate input và serialize output -> Tăng tốc độ xử lý JSON lên gấp đôi Express.
    - *Developer Experience:* Hỗ trợ Async/Await native, plugin system đóng gói (encapsulated) giúp tránh xung đột biến toàn cục.
    - *Hiệu năng:* Gần như nhanh nhất trong thế giới Node.js (Low overhead).

==== Bảng so sánh nhanh

#table(
  columns: (1fr, 1fr, 1fr),
  inset: 8pt,
  align: horizon,
  table.header(
    [*Tiêu chí*], [*NestJS*], [*Express / Fastify*]
  ),
  [Cấu trúc], [Chặt chẽ (Angular-style)], [Tự do (Lỏng lẻo)],
  [Ngôn ngữ], [TypeScript (First-class)], [JS hoặc TS],
  [Learning Curve], [Cao (Nhiều concept)], [Thấp (Dễ học)],
  [Use Case], [Enterprise, Complex Logic], [Simple API, Microservice, MVP]
)

=== Monolith vs Modular Monolith vs Microservices

Khi bắt đầu dự án Node.js, đừng chọn Microservices ngay lập tức (Premature Optimization).

1.  *Monolith:*
    - Tất cả code trong 1 repo, deploy 1 cục.
    - *Ưu:* Dev nhanh, deploy dễ, debug dễ.
    - *Nhược:* Code rối khi lớn, khó scale từng phần.

2.  *Modular Monolith:*
    - Vẫn là 1 khối code, nhưng chia folder rõ ràng theo nghiệp vụ (`modules/users`, `modules/orders`). Các module KHÔNG được import chéo lộn xộn, chỉ giao tiếp qua public API của module.
    - *NestJS sinh ra để làm việc này.*
    - *Lợi ích:* Giữ được tốc độ của Monolith nhưng clean như Microservices. Dễ dàng tách thành Microservices sau này khi cần.

3.  *Microservices:*
    - Tách thành nhiều service chạy riêng biệt, database riêng.
    - *Khi nào dùng:* Team > 20 người, traffic cực lớn, yêu cầu scale độc lập.
    - *Thách thức:* Distributed Transaction (Saga), Network Latency, Devops phức tạp.

*Lời khuyên:* Hãy bắt đầu với *Modular Monolith* bằng NestJS.