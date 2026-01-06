== Patterns & Hybrid <comm_patterns>

Trong thực tế, hệ thống không chỉ thuần túy Sync hoặc Async. Chúng ta kết hợp chúng để giải quyết các bài toán nghiệp vụ phức tạp.

=== Request-Reply over Message Bus

Đôi khi ta muốn dùng Message Queue (để tận dụng khả năng decoupling và buffering) nhưng nghiệp vụ lại yêu cầu phải nhận kết quả trả về ngay lập tức.

*Cơ chế:*
1.  *Client (Producer):* Tạo một `CorrelationId` (Mã định danh duy nhất) và một `ReplyToQueue` (Queue tạm thời để nhận trả lời).
2.  Gửi tin nhắn request chứa 2 thông tin trên vào Request Queue.
3.  Client lắng nghe (block/wait) trên `ReplyToQueue`.
4.  *Server (Consumer):* Nhận tin nhắn, xử lý.
5.  Gửi kết quả vào `ReplyToQueue` kèm theo `CorrelationId` cũ.
6.  *Client:* Nhận được tin nhắn, khớp `CorrelationId` để biết đây là câu trả lời cho request nào.

*Ứng dụng:* Dùng khi cần giao tiếp 2 chiều nhưng muốn tận dụng độ tin cậy của Queue. Tuy nhiên, pattern này làm mất đi lợi thế non-blocking của Queue, biến nó thành blocking.

=== CQRS

CQRS tách biệt việc Đọc (Query) và Ghi (Command) thành hai mô hình riêng biệt, thậm chí hai database riêng biệt.

*Vấn đề của CRUD truyền thống:*
Trong Monolith, cùng 1 model `Order` vừa dùng để tính toán (domain logic) vừa dùng để hiển thị lên UI (DTO). Khi hệ thống lớn, mô hình Ghi cần phức tạp (normalized), mô hình Đọc cần nhanh (denormalized/join sẵn). Dùng chung 1 model gây tắc nghẽn.

*Giải pháp CQRS:*
1.  *Command Side (Write):* Xử lý `Create`, `Update`, `Delete`.
    - Validate logic nghiệp vụ phức tạp.
    - Lưu vào Write DB (ví dụ: PostgreSQL, Normalized).
    - Sau khi ghi xong, phát ra một *Event* (ví dụ: `OrderCreated`).
2.  *Query Side (Read):* Xử lý `Get`, `List`.
    - Lắng nghe Event `OrderCreated`.
    - Cập nhật vào Read DB (ví dụ: Elasticsearch, Redis, MongoDB - Denormalized, Flat structure).
    - API Đọc chỉ việc `SELECT *` từ Read DB cực nhanh, không cần join.

*Đánh đổi:*
- *Eventual Consistency:* Dữ liệu bên Đọc sẽ trễ hơn bên Ghi vài giây.
- *Complexity:* Phải quản lý 2 database, sync dữ liệu, xử lý lỗi khi sync.

=== SAGA Pattern

Trong Microservices, *Database per Service* khiến chúng ta mất đi ACID Transactions (không thể `BEGIN TRANSACTION`... `COMMIT` trên nhiều DB khác nhau). SAGA là giải pháp thay thế.
SAGA là một chuỗi các giao dịch cục bộ (Local Transactions). Mỗi giao dịch cục bộ cập nhật DB và publish 1 message/event để kích hoạt giao dịch tiếp theo.

*Nếu có lỗi:* SAGA phải chạy các *Compensating Transactions* (Giao dịch đền bù) để hoàn tác (undo) các bước đã thành công trước đó.

==== Choreography
Các service tự biết phải làm gì khi nhận được sự kiện từ người khác. Không có nhạc trưởng.

*Ví dụ: Đặt hàng*
1.  `Order Service`: Tạo đơn hàng (Pending) -> Phát `OrderCreated`.
2.  `Payment Service`: Nghe `OrderCreated` -> Trừ tiền -> Phát `PaymentProcessed`.
3.  `Inventory Service`: Nghe `PaymentProcessed` -> Trừ kho -> Phát `InventoryUpdated`.
4.  `Order Service`: Nghe `InventoryUpdated` -> Cập nhật đơn hàng (Completed).

*Rollback (Nếu kho hết hàng):*
1.  `Inventory Service`: Phát `InventoryFailed`.
2.  `Payment Service`: Nghe `InventoryFailed` -> Hoàn tiền (Refund) -> Phát `PaymentRefunded`.
3.  `Order Service`: Nghe `PaymentRefunded` -> Cập nhật đơn hàng (Cancelled).

*Ưu:* Đơn giản, loosely coupled.
*Nhược:* Khó theo dõi quy trình tổng thể (Process flow). Dễ bị "Cyclic dependencies" (A gọi B, B gọi A).

==== Orchestration
Có một service trung tâm (Orchestrator, ví dụ `Order Saga Coordinator`) điều phối mọi việc.

*Quy trình:*
1.  Coordinator ra lệnh cho Payment: "Thanh toán đi".
2.  Payment trả lời: "Xong rồi".
3.  Coordinator ra lệnh cho Inventory: "Trừ kho đi".
4.  Inventory trả lời: "Hết hàng rồi".
5.  Coordinator ra lệnh cho Payment: "Hoàn tiền lại đi".

*Ưu:* Dễ quản lý, logic tập trung, tránh vòng lặp.
*Nhược:* Coordinator trở thành điểm nghẽn logic (God Service).
*Công cụ:* Camunda, Netflix Conductor, Temporal, Cadence.

=== API Gateway / BFF

Khi có 100 microservices, Client (Mobile/Web) không thể gọi trực tiếp 100 đầu mối.

==== API Gateway
Là cổng vào duy nhất (Single Entry Point) cho tất cả client.
- *Routing:* `/orders` -> Order Service, `/users` -> User Service.
- *Authentication:* Check JWT Token ở đây, services bên trong không cần check lại.
- *Rate Limiting:* Chống DDOS.
- *Aggregation:* Gọi 3 service A, B, C rồi gộp kết quả trả về 1 lần cho Client (GraphQL thường dùng ở đây).
- *Công cụ:* Kong, Nginx, Amazon API Gateway, Spring Cloud Gateway.

==== BFF
Thay vì 1 API Gateway khổng lồ cho tất cả, ta tạo ra các Gateway riêng biệt cho từng loại Client.
- `Mobile BFF`: API tối ưu cho mobile (ít dữ liệu, màn hình nhỏ).
- `Web BFF`: API cho web (nhiều dữ liệu hơn).
- `3rd Party BFF`: API public cho đối tác.
Giúp team Mobile và Web không dẫm chân lên nhau khi sửa API.