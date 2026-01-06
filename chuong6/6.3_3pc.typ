== Three-Phase Commit (3PC) <three_phase_commit>

=== Động lực ra đời

Giao thức Two-Phase Commit (2PC) có một nhược điểm chí mạng: *Blocking (Chặn)*. Nếu Coordinator chết sau khi Participants đã vote YES, Participants sẽ bị kẹt trong trạng thái chờ đợi không xác định, giữ khóa tài nguyên và làm tê liệt hệ thống.

Three-Phase Commit (3PC) được sinh ra để khắc phục vấn đề này bằng cách thêm cơ chế *Timeout* vào giao thức. Mục tiêu là đảm bảo rằng Participants có thể tự đưa ra quyết định (Commit hoặc Rollback) ngay cả khi Coordinator chết, mà không làm sai lệch dữ liệu.

#figure(image("../images/pic13.png"), caption: [Three Phase Commit Protocol Diagram])

=== Chi tiết quy trình hoạt động

3PC chia nhỏ giai đoạn Commit của 2PC thành 2 bước nhỏ hơn, tổng cộng là 3 giai đoạn:

==== Giai đoạn 1: CanCommit
1.  *Coordinator:* Gửi `CAN_COMMIT?` tới tất cả Participants.
2.  *Participants:* Kiểm tra xem có thể thực hiện giao dịch không (Check constraints, lock resources).
    - Nếu OK: Trả lời `YES`.
    - Nếu không: Trả lời `NO`.

*Khác biệt với 2PC:* Ở bước này, Participants *chưa thực hiện ghi log hay thay đổi dữ liệu nặng*, chỉ kiểm tra khả năng (viability check).

==== Giai đoạn 2: PreCommit
Nếu tất cả vote YES ở giai đoạn 1:
1.  *Coordinator:* Gửi lệnh `PRE_COMMIT` tới tất cả.
2.  *Participants:*
    - Thực hiện transaction cục bộ (ghi log, giữ lock thực sự).
    - Trả lời `ACK`.
    - *Quan trọng:* Sau khi gửi ACK, Participant chuyển sang trạng thái "Sẵn sàng Commit". Nếu lúc này Coordinator chết (timeout), Participant sẽ *tự động Commit*.

Nếu có ai vote NO ở giai đoạn 1:
- Coordinator gửi `ABORT`.

==== Giai đoạn 3: DoCommit
Nếu nhận đủ ACK ở giai đoạn 2:
1.  *Coordinator:* Gửi lệnh `DO_COMMIT`.
2.  *Participants:*
    - Chính thức commit dữ liệu.
    - Giải phóng khóa.
    - Trả lời `ACK`.

=== Cơ chế Timeout giải quyết Blocking

Điểm mấu chốt của 3PC là việc xử lý Timeout ở các vị trí khác nhau:

1.  *Timeout ở Giai đoạn 1 (CanCommit):* Nếu Participant chờ mãi không thấy Coordinator nói gì -> Tự động `ABORT`. (An toàn vì chưa ai làm gì cả).
2.  *Timeout ở Giai đoạn 2 (PreCommit):* Nếu Participant đã vote YES ở G1 nhưng chờ mãi không thấy lệnh PreCommit -> Tự động `ABORT`.
3.  *Timeout ở Giai đoạn 3 (DoCommit):* Đây là điểm thiên tài của 3PC.
    - Nếu Participant đã nhận được `PRE_COMMIT` và gửi ACK, nhưng chờ mãi không thấy `DO_COMMIT` (do Coordinator chết).
    - Participant suy luận: "Mình đã nhận được PreCommit, nghĩa là TẤT CẢ mọi người khác đều đã vote YES ở giai đoạn 1 (vì nếu có 1 ai NO thì Coordinator đã gửi ABORT rồi). Vậy khả năng cao là mọi người đều sẵn sàng."
    - -> Participant *tự động COMMIT*.

Nhờ cơ chế này, Participants không bao giờ bị treo vĩnh viễn. Khóa luôn được giải phóng.

=== Nhược điểm và Tại sao 3PC ít được dùng?

Mặc dù giải quyết được Blocking trong trường hợp Coordinator chết (Fail-Stop Model), nhưng 3PC lại thất bại thảm hại trong trường hợp *Phân vùng mạng (Network Partition)*.

==== Kịch bản lỗi "Split-Brain"
Giả sử hệ thống có Coordinator C và 2 Participant P1, P2.
Đang ở giai đoạn 2 (PreCommit).
1.  C gửi `PRE_COMMIT` cho P1 và P2.
2.  P1 nhận được, P2 nhận được. Cả hai gửi ACK.
3.  C nhận đủ ACK, chuyển sang giai đoạn 3. C gửi `DO_COMMIT`.
4.  *SỰ CỐ MẠNG XẢY RA:*
    - C gửi được `DO_COMMIT` cho P1 -> P1 Commit thành công.
    - Mạng giữa C và P2 bị đứt. P2 không nhận được `DO_COMMIT`.
    - Đồng thời, mạng giữa C và P2 bị chập chờn khiến P2 nghĩ rằng C đã chết, nhưng thực ra C vẫn sống và nói chuyện với P1.
5.  *P2 xử lý Timeout:*
    - Tùy thuộc vào cài đặt cụ thể của 3PC, P2 có thể quyết định Commit (theo logic ở mục 3) hoặc Abort.
    - Nếu P2 quyết định Commit -> OK (Consistent với P1).
    - Nhưng nếu sự cố xảy ra sớm hơn một chút: C chết sau khi gửi `PRE_COMMIT` cho P1 nhưng *trước khi* gửi cho P2. P2 chưa nhận được `PRE_COMMIT` nên timeout ở Giai đoạn 2 -> P2 tự động `ABORT`. Trong khi đó P1 nhận được `PRE_COMMIT` và sau đó timeout ở Giai đoạn 3 -> P1 tự động `COMMIT`.
    - *Hậu quả:* P1 Commit, P2 Abort -> *Dữ liệu không nhất quán (Inconsistency).*

==== Kết luận
3PC quá phức tạp, tăng số lượng tin nhắn lên 1.5 lần so với 2PC, nhưng vẫn không đảm bảo Atomicity trong môi trường mạng không ổn định. Do đó, trong thực tế (như các hệ thống Database phân tán), người ta thường dùng các thuật toán đồng thuận mạnh hơn như *Paxos* hoặc *Raft*, hoặc chấp nhận Eventual Consistency với *Saga Pattern*.