== Messaging / Event-driven <messaging_events>

Kiến trúc hướng sự kiện (Event-driven Architecture - EDA) giúp giảm sự phụ thuộc (Decoupling) giữa các microservices và tăng khả năng mở rộng.

#figure(image("../images/pic19.jpg"), caption: [Event Driven Node.js Architecture])

=== RabbitMQ

- *Mô hình:* Smart Broker, Dumb Consumer.
- *Giao thức:* AMQP (Advanced Message Queuing Protocol).
- *Thư viện:* `amqplib` (low-level), `nestjs/microservices` (high-level).
- *Cơ chế:*
    - Producer gửi message vào *Exchange*.
    - Exchange định tuyến (route) message vào các *Queue* dựa trên Routing Key.
    - Consumer lắng nghe Queue và xử lý.
- *Patterns:*
    - *Work Queues:* Phân phối task nặng cho nhiều worker (Round-robin).
    - *Pub/Sub (Fanout):* Một event (UserCreated) được gửi tới nhiều Queue (EmailService, AnalyticsService) cùng lúc.
- *Ưu điểm:* Độ tin cậy cao (Ack mode), routing phức tạp linh hoạt. Phù hợp cho *Command/Job processing*.

=== Apache Kafka

- *Mô hình:* Dumb Broker, Smart Consumer.
- *Giao thức:* Kafka TCP Protocol.
- *Thư viện:* `kafkajs` (khuyên dùng), `node-rdkafka`.
- *Cơ chế:*
    - Dữ liệu được lưu vào *Log* (Append-only file) trên đĩa cứng, chia thành các *Topic* và *Partition*.
    - Consumer tự quản lý *Offset* (vị trí đọc). Đọc xong dữ liệu không mất đi, consumer khác có thể đọc lại.
- *Ưu điểm:* Throughput cực khủng (hàng triệu msg/s). Lưu trữ lịch sử sự kiện (Event Sourcing).
- *Nhược điểm:* Phức tạp trong vận hành và setup.

=== Task Queues: BullMQ

Khi không cần một hệ thống Broker phức tạp như RabbitMQ, mà chỉ cần xử lý background job trong hệ sinh thái Node.js/Redis.

- *Dựa trên:* Redis.
- *Tính năng:*
    - Delayed jobs (Gửi email sau 15 phút).
    - Scheduled jobs (Chạy cron job mỗi ngày).
    - Retries with Backoff (Tự thử lại nếu lỗi).
    - Priority Queues (Job VIP chạy trước).
    - Rate Limiting (Giới hạn số job chạy trong 1 giây).
- *Ứng dụng:* Xử lý resize ảnh, gửi OTP, tạo báo cáo PDF.

=== Saga / Distributed Transaction

Trong Microservices, mỗi service có DB riêng. Làm sao đảm bảo giao dịch (Transaction) trải dài qua nhiều service? (Ví dụ: Tạo đơn hàng -> Trừ kho -> Trừ tiền).

==== Choreography
Các service tự trao đổi event với nhau.
- Order Service tạo đơn -> Bắn event `OrderCreated`.
- Inventory Service nghe `OrderCreated` -> Trừ kho -> Bắn event `InventoryReserved`.
- Payment Service nghe `InventoryReserved` -> Trừ tiền -> Bắn event `PaymentSuccess`.
- *Ưu:* Loose coupling.
- *Nhược:* Khó theo dõi quy trình, dễ bị vòng lặp (Cyclic dependency).

==== Orchestration
Có một service trung tâm (Orchestrator) điều phối.
- Order Service ra lệnh cho Inventory: "Trừ kho đi".
- Inventory trả lời: "OK".
- Order Service ra lệnh cho Payment: "Trừ tiền đi".
- Payment trả lời: "Lỗi rồi".
- Order Service ra lệnh cho Inventory: "Hoàn lại kho đi" (*Compensating Transaction*).
- *Ưu:* Dễ quản lý, logic tập trung.
- *Nhược:* Orchestrator trở thành điểm nghẽn.

*Lưu ý:* Node.js xử lý Saga Orchestration rất tốt nhờ tính chất Async non-blocking.