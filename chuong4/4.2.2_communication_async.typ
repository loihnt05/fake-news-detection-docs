== Giao tiếp không đồng bộ <async_communication>

Trong giao tiếp không đồng bộ, Client gửi tin nhắn (Message) nhưng *không chờ* (non-blocking) Server xử lý ngay. Client tiếp tục làm việc khác. Server (hoặc Worker) sẽ nhận và xử lý tin nhắn đó vào một thời điểm sau.

Phương thức này giúp *tách rời (decouple)* các service về mặt thời gian và sự sẵn sàng. Nếu Service B chết, Service A vẫn gửi tin nhắn được (tin nhắn nằm chờ trong hàng đợi).

=== Message Queue

Mô hình hàng đợi truyền thống (Point-to-Point). Tiêu biểu: *RabbitMQ, ActiveMQ, Amazon SQS*.

==== Cơ chế hoạt động:
1.  *Producer:* Gửi tin nhắn vào Queue.
2.  *Queue:* Lưu trữ tin nhắn theo thứ tự FIFO (First-In-First-Out).
3.  *Consumer:* Lấy tin nhắn ra khỏi Queue để xử lý.
4.  *Acknowledge (Ack):* Sau khi xử lý xong, Consumer báo cho Queue biết để *xóa* tin nhắn đó đi.

==== Đặc điểm:
- *Destructive Consumer:* Tin nhắn sau khi được tiêu thụ sẽ biến mất khỏi Queue.
- *Smart Broker, Dumb Consumer:* Broker (RabbitMQ) chịu trách nhiệm routing phức tạp, retry, load balancing giữa các consumers. Consumer chỉ việc lấy và làm.
- *Push Model:* Broker chủ động đẩy (push) tin nhắn cho Consumer khi có kết nối.

==== Khi nào dùng?
- *Task Queue:* Xử lý các tác vụ nặng (gửi email, resize ảnh, tạo báo cáo PDF) ở background.
- *Load Leveling:* Khi traffic tăng đột biến, Queue đóng vai trò bộ đệm (buffer), giúp Consumer xử lý từ từ, không bị sập.

=== Event Streaming / Pub-Sub

Mô hình xuất bản - đăng ký (Publish-Subscribe). Tiêu biểu: *Apache Kafka, Amazon Kinesis, Google Pub/Sub*.

==== Cơ chế hoạt động:
1.  *Publisher:* Gửi sự kiện (Event) vào một Topic (Chủ đề).
2.  *Topic:* Là một log file (append-only log), lưu trữ sự kiện theo thứ tự thời gian và bền vững (persistent) trên ổ cứng.
3.  *Subscriber (Consumer Group):* Đăng ký nghe Topic đó.
4.  *Offset:* Mỗi Consumer tự quản lý vị trí đọc (offset) của mình.

==== Đặc điểm:
- *Non-destructive:* Đọc xong tin nhắn *không bị xóa*. Nó được lưu giữ theo thời gian (retention policy, ví dụ 7 ngày). Nhiều Consumer khác nhau có thể đọc lại cùng một tin nhắn.
- *Dumb Broker, Smart Consumer:* Broker (Kafka) chỉ ghi nhận tin nhắn cực nhanh. Consumer phải tự quản lý offset, tự poll dữ liệu.
- *Pull Model:* Consumer chủ động kéo (pull) dữ liệu khi rảnh.

==== Khi nào dùng?
- *Data Pipeline/ETL:* Chuyển dữ liệu từ DB sang Data Warehouse/Analytics.
- *Event Sourcing:* Lưu trữ lại toàn bộ lịch sử thay đổi trạng thái của hệ thống.
- *Microservices Communication:* Thông báo sự kiện "UserCreated" cho 10 service khác nhau (Email, Profile, Loyalty...) cùng biết.

=== Các mẫu sử dụng

==== Fire-and-Forget
Service A gửi tin nhắn và không quan tâm ai xử lý, bao giờ xong.
- *Ví dụ:* Gửi log, gửi metric thống kê.
- *Ưu:* Nhanh.
- *Nhược:* Có thể mất tin nhắn mà không biết.

==== Publish-Subscribe
Một Producer gửi tin nhắn, N Consumer nhận được bản sao.
- *RabbitMQ:* Dùng Exchange type `Fanout` hoặc `Topic`.
- *Kafka:* Nhiều Consumer Group cùng subscribe 1 Topic.

==== Competing Consumers
Nhiều instance của cùng 1 Service (cùng Consumer Group) cùng lắng nghe 1 Queue để chia tải.
- Tin nhắn 1 -> Consumer A.
- Tin nhắn 2 -> Consumer B.
-> Mỗi tin nhắn chỉ được xử lý bởi 1 Consumer duy nhất trong nhóm đó. Giúp scale out hệ thống xử lý (parallel processing).

=== Vấn đề cần chú ý

==== Độ phức tạp vận hành
Vận hành một cụm Kafka hay RabbitMQ ổn định (High Availability, No Data Loss) khó hơn nhiều so với vận hành HTTP Server. Cần giám sát Disk, I/O, Network, Partition rebalancing.

==== Eventual Consistency
Do xử lý không đồng bộ, Service A đã xong nhưng Service B chưa nhận được tin nhắn.
- User vừa tạo đơn hàng xong (Service A thành công), nhưng qua trang Lịch sử đơn hàng (Service B) chưa thấy đơn hàng đâu (do tin nhắn chưa tới).
- Phải thiết kế UI để handle việc này (ví dụ: hiển thị "Đang xử lý...").

==== Message Delivery Semantics
Đây là bài toán khó nhất trong Async Communication.
1.  *At-most-once:* Tin nhắn có thể mất, nhưng không bao giờ bị trùng. (Gửi đi là xong, không retry). -> Dùng cho Log.
2.  *At-least-once:* Tin nhắn đảm bảo đến nơi, nhưng có thể bị trùng (Duplicate). (Gửi lại nếu không nhận được Ack). -> Phổ biến nhất.
    - *Hệ quả:* Consumer phải được thiết kế *Idempotent* (Thực hiện 1 lần hay n lần kết quả vẫn y nguyên). Ví dụ: `SET status = PAID` (Idempotent) vs `status = status + 1` (Not Idempotent).
3.  *Exactly-once:* Tin nhắn đến đúng 1 lần duy nhất. (Rất khó, tốn kém hiệu năng. Kafka hỗ trợ qua Transactional API nhưng phức tạp).

==== Message Ordering
Trong Distributed System, đảm bảo thứ tự toàn cục (Global Order) là bất khả thi nếu muốn scale.
- Kafka chỉ đảm bảo thứ tự trong 1 Partition.
- RabbitMQ đảm bảo thứ tự trong 1 Queue (nếu 1 consumer).
- Nếu cần thứ tự tuyệt đối cho một Entity (ví dụ: các sự kiện của đơn hàng #123), phải dùng *Partition Key* (Kafka) hoặc *Consistent Hashing* để định tuyến tất cả tin nhắn của #123 vào cùng 1 partition/queue.