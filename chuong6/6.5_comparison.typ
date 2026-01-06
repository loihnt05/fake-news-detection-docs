== So sánh Two-phase commit/Three-phase commit và Saga <comparison>

Sau khi tìm hiểu chi tiết về các giải pháp xử lý giao dịch phân tán, bảng dưới đây sẽ tổng hợp và so sánh chúng để giúp kiến trúc sư phần mềm đưa ra lựa chọn phù hợp.

=== Bảng so sánh tổng hợp

#table(
  columns: (1.2fr, 1fr, 1fr, 1.2fr),
  inset: 8pt,
  align: horizon,
  table.header(
    [*Tiêu chí*], [*2PC (Two-Phase Commit)*], [*3PC (Three-Phase Commit)*], [*Saga Pattern*]
  ),
  [*Mô hình nhất quán*], [Strong Consistency (ACID)], [Strong Consistency (ACID)], [Eventual Consistency (ACD - Thiếu Isolation)],
  [*Atomicity*], [Đảm bảo tuyệt đối (All or Nothing)], [Đảm bảo (trừ khi Network Partition)], [Đảm bảo thông qua Compensation],
  [*Isolation*], [Cao (Giữ lock trong suốt quá trình)], [Cao (Giữ lock)], [Thấp (Dirty Reads có thể xảy ra)],
  [*Blocking*], [Có (Nếu Coordinator chết)], [Không (Có timeout)], [Không (Local commit ngay)],
  [*Hiệu năng (Latency)*], [Thấp (Chậm nhất node chậm nhất)], [Rất thấp (Nhiều round-trip)], [Cao (Tận dụng song song)],
  [*Độ phức tạp cài đặt*], [Trung bình (Hỗ trợ bởi Database/XA)], [Cao (Phức tạp logic timeout)], [Cao (Phải code logic bù trừ)],
  [*Trường hợp sử dụng*], [Hệ thống ngân hàng nội bộ, SQL Databases], [Ít dùng trong thực tế], [Microservices, Long-running processes]
)

=== Phân tích chi tiết

==== Khi nào chọn 2PC?
- Khi *Data Consistency* là ưu tiên số 1 và không thể chấp nhận rủi ro sai lệch dù chỉ 1 giây.
- Khi các Transaction là *ngắn (Short-lived)*.
- Khi các Participant nằm trong mạng nội bộ tin cậy, độ trễ thấp (LAN).
- Khi tất cả Database đều hỗ trợ chuẩn *XA Transactions* (như Oracle, PostgreSQL, MySQL).
- *Ví dụ:* Chuyển tiền giữa 2 tài khoản trong cùng hệ thống Core Banking.

==== Tại sao 3PC chết yểu?
- Mặc dù lý thuyết 3PC khắc phục được Blocking của 2PC, nhưng nó vẫn không chịu được Network Partition (lỗi phổ biến nhất trong Distributed System).
- Nó tăng độ phức tạp và độ trễ (3 vòng tin nhắn) mà không mang lại sự an toàn tuyệt đối.
- Các thuật toán đồng thuận hiện đại như *Paxos* và *Raft* đã thay thế vị trí của 3PC trong việc xây dựng hệ thống phân tán nhất quán (như CockroachDB, Google Spanner).

==== Khi nào chọn Saga?
- Khi xây dựng *Microservices*.
- Khi Transaction kéo dài (Long-lived transactions). Ví dụ: Đặt vé máy bay (chờ hãng xác nhận), Quy trình duyệt vay vốn (kéo dài vài ngày).
- Khi cần *High Availability* và *Scalability*. Saga không giữ lock lâu, nên không làm tắc nghẽn DB.
- Khi chấp nhận *Eventual Consistency*: User có thể thấy trạng thái "Đang xử lý" một lúc trước khi thấy "Thành công".
- *Ví dụ:* Các sàn thương mại điện tử (Amazon, Shopee), Ứng dụng gọi xe (Uber/Grab).

=== Kết luận

Không có giải pháp nào là hoàn hảo ("No Silver Bullet").
- Nếu bạn cần ACID tuyệt đối như một khối monolith -> Dùng 2PC nhưng chấp nhận chậm và khó scale.
- Nếu bạn cần scale ra toàn cầu và chịu lỗi tốt -> Dùng Saga nhưng chấp nhận code phức tạp để xử lý bù trừ và trạng thái trung gian.
- Trong thực tế Microservices, *Saga* (kết hợp Orchestration) đang là tiêu chuẩn phổ biến nhất.