== Saga Pattern <saga_pattern>

=== Mô tả tổng quan

Trong thế giới Microservices, việc sử dụng 2PC/3PC (Distributed Transactions ACID) thường bị coi là "anti-pattern" vì nó làm giảm độ sẵn sàng (Availability) và tăng độ trễ (Latency). Để giải quyết vấn đề giao dịch phân tán mà vẫn đảm bảo hiệu năng, *Saga Pattern* ra đời.

*Định nghĩa:*
Một Saga là một chuỗi các giao dịch cục bộ (Local Transactions). Mỗi giao dịch cục bộ cập nhật cơ sở dữ liệu bên trong một service và xuất bản một thông báo (message/event) để kích hoạt giao dịch cục bộ tiếp theo trong chuỗi.

- Nếu một giao dịch cục bộ thất bại (vì vi phạm quy tắc nghiệp vụ), Saga sẽ thực thi một chuỗi các *Giao dịch bù trừ (Compensating Transactions)* để hoàn tác (undo) các thay đổi đã được thực hiện bởi các giao dịch cục bộ trước đó.

*Tính chất ACD (Thiếu I - Isolation):*
Saga đảm bảo Atomicity (cam kết tất cả hoặc hoàn tác tất cả), Consistency (dữ liệu cuối cùng đúng), Durability (bền vững), nhưng *không đảm bảo Isolation*. Các giao dịch con được commit ngay lập tức, nên người dùng khác có thể nhìn thấy dữ liệu trung gian (Dirty Read).

#figure(image("../images/pic25.png"), caption: [Saga Distributed Transaction Diagram])

=== Các phương pháp triển khai

Có hai cách chính để điều phối các bước trong Saga:

==== Choreography

Các service tự trao đổi event với nhau mà không cần nhạc trưởng.

*Ví dụ: Đặt hàng (E-commerce)*
1.  *Order Service:* Tạo đơn hàng (Status: PENDING) -> Publish Event `OrderCreated`.
2.  *Payment Service:* Lắng nghe `OrderCreated` -> Trừ tiền thẻ tín dụng -> Publish Event `PaymentProcessed`.
3.  *Inventory Service:* Lắng nghe `PaymentProcessed` -> Trừ tồn kho -> Publish Event `InventoryUpdated`.
4.  *Order Service:* Lắng nghe `InventoryUpdated` -> Update đơn hàng (Status: APPROVED).

*Xử lý lỗi (Rollback):*
Nếu Inventory Service hết hàng:
1.  *Inventory Service:* Publish Event `InventoryFailed`.
2.  *Payment Service:* Lắng nghe `InventoryFailed` -> Hoàn tiền (Refund) -> Publish Event `PaymentRefunded`.
3.  *Order Service:* Lắng nghe `PaymentRefunded` -> Update đơn hàng (Status: REJECTED).

*Ưu điểm:*
- Đơn giản, dễ bắt đầu.
- Loosely coupled (các service không biết nhau trực tiếp, chỉ biết event).
- Không có điểm chết trung tâm (SPOF).

*Nhược điểm:*
- Khó theo dõi toàn bộ quy trình: Muốn biết "Đơn hàng đang ở đâu?", bạn phải nghe ngóng ở 4 service.
- Cyclic dependencies: Dễ tạo ra vòng lặp vô tận (A gọi B, B gọi A).

==== Orchestration

Sử dụng một service trung tâm (Saga Orchestrator) để điều phối mọi bước.

*Ví dụ:*
1.  *Order Service* tạo đơn hàng và gọi *Order Saga Orchestrator*.
2.  *Orchestrator* gửi lệnh `ExecutePayment` cho Payment Service.
3.  Payment Service trả lời `Success`.
4.  *Orchestrator* gửi lệnh `ReserveInventory` cho Inventory Service.
5.  Inventory Service trả lời `Failed`.
6.  *Orchestrator* nhận thấy lỗi, gửi lệnh `RefundPayment` cho Payment Service (Bù trừ).
7.  Orchestrator đánh dấu Saga thất bại.

*Ưu điểm:*
- Logic quy trình tập trung ở một chỗ, dễ hiểu, dễ debug.
- Tránh phụ thuộc vòng tròn.
- Service con (Payment, Inventory) không cần biết về Saga, chỉ cần cung cấp API Execute và Compensate.

*Nhược điểm:*
- Orchestrator có thể trở thành "God Service" chứa quá nhiều logic.
- Thêm một điểm chết (SPOF) nếu Orchestrator không được HA.

=== Compensating Transactions

Trong Saga, chúng ta không thể `ROLLBACK` database của service khác (vì nó đã commit rồi). Cách duy nhất là thực hiện một hành động ngược lại để sửa sai về mặt nghiệp vụ.

*Bảng đối chiếu:*
#table(
  columns: (1fr, 1fr),
  inset: 5pt,
  align: horizon,
  table.header([*Giao dịch thuận*], [*Giao dịch bù trừ (Compensate)*]),
  [Trừ tiền (Debit)], [Cộng tiền/Hoàn tiền (Credit/Refund)],
  [Tạo đơn hàng], [Hủy đơn hàng (Cancel)],
  [Trừ kho], [Cộng lại kho (Restock)],
  [Gửi Email xác nhận], [Gửi Email xin lỗi ("Oops, we made a mistake")]
)

*Lưu ý khi thiết kế:*
1.  *Idempotency (Tính lũy đẳng):* Lệnh Compensate có thể bị gửi trùng lặp (do mạng lag). Service phải đảm bảo nhận lệnh "Hoàn tiền" 2 lần thì chỉ hoàn tiền 1 lần.
2.  *Không thể hoàn tác hoàn toàn:* Có những việc không thể undo (ví dụ: đã gửi email cho khách, hoặc tên lửa đã phóng). Trong trường hợp này, bù trừ có thể là hành động sửa sai khác (tặng voucher xin lỗi).
3.  *Thứ tự:* Giao dịch bù trừ phải được thực hiện theo thứ tự ngược lại của giao dịch thuận.

=== Isolation Anomalies

Vì Saga commit cục bộ ngay lập tức, các transaction khác có thể xen vào giữa.
- *Lost Updates:* A ghi đè lên thay đổi của B.
- *Dirty Reads:* User thấy đơn hàng "Đã thanh toán" (nhưng sau đó bị Refund do hết kho).
- *Non-repeatable reads.*

*Giải pháp:*
- *Semantic Lock:* Đánh dấu trạng thái `PENDING` (ví dụ `ORDER_PENDING_APPROVAL`). Các transaction khác khi thấy trạng thái này thì né ra hoặc chờ.
- *Commutative updates:* Thiết kế các update sao cho thứ tự không quan trọng (ví dụ: `balance = balance + 10` thay vì `balance = 100`).
- *Pessimistic View:* Reorder các bước saga để giảm rủi ro (ví dụ: cái gì dễ fail làm trước, cái gì không thể undo làm cuối cùng).