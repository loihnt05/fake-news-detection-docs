== Two-Phase Commit (2PC) <two_phase_commit>

=== Mô tả tổng quan

Two-Phase Commit (2PC) là thuật toán đồng thuận cổ điển nhất để đảm bảo tính Atomic của một giao dịch phân tán. Nó hoạt động dựa trên nguyên tắc "tất cả cùng đồng ý hoặc tất cả cùng hủy bỏ".

Hệ thống trong 2PC bao gồm hai loại thành phần:
1.  *Coordinator (Điều phối viên):* Node chịu trách nhiệm quản lý transaction (thường là Transaction Manager hoặc Service khởi tạo giao dịch).
2.  *Participants (Người tham gia):* Các node chứa dữ liệu cần thay đổi (Database, Message Queue).

Đúng như tên gọi, thuật toán diễn ra trong 2 giai đoạn (phase).

#figure(image("../images/pic12.png"), caption: [Two Phase Commit Protocol Diagram])

=== Chi tiết quy trình hoạt động

==== Giai đoạn 1: Prepare

Mục tiêu: Coordinator hỏi tất cả Participants xem họ có *khả năng* thực hiện giao dịch hay không.

1.  *Gửi lệnh Prepare:* Coordinator gửi tin nhắn `PREPARE` (kèm theo Transaction ID) tới tất cả các Participants.
2.  *Xử lý cục bộ:* Mỗi Participant nhận được lệnh sẽ thực hiện các bước sau:
    - Chạy transaction cục bộ (ví dụ: kiểm tra số dư, trừ tiền, kiểm tra khóa ngoại).
    - Ghi log transaction vào đĩa cứng (để phục hồi nếu crash).
    - Giữ khóa (Lock) trên các dòng dữ liệu liên quan.
    - *Lưu ý quan trọng:* Chưa Commit thực sự, nhưng đã chiếm tài nguyên.
3.  *Bỏ phiếu (Vote):*
    - Nếu thành công: Gửi `VOTE_COMMIT` (Yes) về Coordinator.
    - Nếu thất bại (hết tiền, lỗi logic): Gửi `VOTE_ABORT` (No) về Coordinator và tự rollback cục bộ.

==== Giai đoạn 2: Commit

Mục tiêu: Dựa trên kết quả bỏ phiếu, Coordinator ra quyết định cuối cùng.

*Trường hợp 1: Tất cả Participants đều vote YES*
1.  *Ra quyết định:* Coordinator ghi vào log của mình quyết định `GLOBAL_COMMIT`.
2.  *Gửi lệnh Commit:* Coordinator gửi tin nhắn `COMMIT` tới tất cả Participants.
3.  *Thực thi:* Mỗi Participant nhận được lệnh `COMMIT`:
    - Thực hiện commit transaction vào DB.
    - Giải phóng khóa (Release Locks).
    - Gửi tin nhắn `ACK` (Xác nhận) về Coordinator.
4.  *Hoàn tất:* Khi nhận đủ ACK, Coordinator kết thúc giao dịch.

*Trường hợp 2: Ít nhất một Participant vote NO (hoặc Timeout)*
1.  *Ra quyết định:* Coordinator ghi vào log quyết định `GLOBAL_ABORT`.
2.  *Gửi lệnh Rollback:* Coordinator gửi tin nhắn `ROLLBACK` tới tất cả Participants (kể cả những người đã vote YES).
3.  *Thực thi:* Mỗi Participant nhận lệnh `ROLLBACK`:
    - Hoàn tác transaction (Undo).
    - Giải phóng khóa.
    - Gửi tin nhắn `ACK`.

=== Nhược điểm chí mạng của 2PC

Mặc dù đảm bảo Consistency mạnh (Strong Consistency), 2PC có những vấn đề nghiêm trọng khiến nó ít được dùng trong Microservices hiện đại:

==== Synchronous Blocking
Đây là vấn đề lớn nhất. Trong suốt quá trình 2PC diễn ra (từ lúc Prepare đến lúc Commit), các Participants *phải giữ khóa* trên dữ liệu.
- Nếu Coordinator bị treo (crash) sau khi gửi `PREPARE` nhưng trước khi gửi `COMMIT`:
    - Các Participants đã vote YES sẽ rơi vào trạng thái "tiến thoái lưỡng nan" (In-doubt state).
    - Họ không biết nên Commit hay Rollback.
    - Họ buộc phải *giữ khóa vĩnh viễn* cho đến khi Coordinator sống lại.
    - Hậu quả: Toàn bộ hệ thống bị treo, không ai khác truy cập được vào dữ liệu đó.

==== Single Point of Failure
Coordinator là nút thắt cổ chai. Nếu Coordinator chết, các Participants bị block. Nếu ổ cứng của Coordinator hỏng mất log, giao dịch có thể bị treo mãi mãi.

==== Performance Overhead
- Số lượng tin nhắn trao đổi qua mạng lớn ($4 * N$ tin nhắn với N participants).
- Độ trễ (Latency) của transaction bằng độ trễ của node chậm nhất (Straggler problem). Transaction chỉ xong khi người chậm nhất trả lời.

==== Không hỗ trợ Partition Tolerance
Nếu mạng bị đứt giữa Coordinator và Participant, hệ thống buộc phải ngừng hoạt động (block) để giữ Consistency, hy sinh Availability.

=== Failure Scenario

*Kịch bản:* Coordinator gửi `COMMIT` cho Participant A (thành công), nhưng chết trước khi gửi cho Participant B.
- Participant A: Đã commit, tiền đã trừ.
- Participant B: Vẫn đang chờ lệnh, tiền chưa cộng, đang giữ lock.
- Hệ thống rơi vào trạng thái không nhất quán tạm thời. Khi Coordinator hồi phục, nó đọc log, thấy mình đã quyết định Commit, nên sẽ gửi lại lệnh Commit cho B (cơ chế Retry). Nhưng trong thời gian chờ, B bị treo.