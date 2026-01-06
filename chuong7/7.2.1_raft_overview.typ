== Khái quát về Raft <raft_overview>

=== Raft là gì?

Raft là một thuật toán đồng thuận được thiết kế bởi Diego Ongaro và John Ousterhout tại Đại học Stanford vào năm 2014.

Mục tiêu tối thượng của Raft không phải là hiệu năng hay tính năng, mà là *Sự dễ hiểu (Understandability)*. Trước Raft, thuật toán Paxos (của Leslie Lamport) thống trị thế giới, nhưng Paxos quá khó hiểu và cực kỳ khó cài đặt đúng. Raft ra đời để cung cấp một giải pháp tương đương Paxos về độ mạnh, nhưng dễ tiếp cận hơn cho các kỹ sư hệ thống.

Raft phân rã bài toán Consensus thành các bài toán con độc lập để dễ giải quyết:
1.  *Leader Election:* Bầu chọn một lãnh đạo.
2.  *Log Replication:* Sao chép nhật ký từ lãnh đạo sang nhân viên.
3.  *Safety:* Đảm bảo an toàn dữ liệu.

#figure(image("../images/pic14.webp"), caption: [Raft Consensus Algorithm Diagram])

=== Server States

Tại bất kỳ thời điểm nào, mỗi server trong cụm Raft chỉ có thể nằm ở 1 trong 3 trạng thái sau. Sự chuyển đổi trạng thái (State Transition) là cốt lõi của thuật toán.

==== Leader
- *Vai trò:* Xử lý tất cả các yêu cầu từ Client (Đọc và Ghi). Điều phối việc sao chép log sang các node khác.
- *Đặc điểm:*
    - Trong điều kiện bình thường, chỉ có duy nhất 1 Leader.
    - Gửi tin nhắn *Heartbeat* (AppendEntries rỗng) định kỳ cho tất cả Followers để duy trì quyền lực.
    - Không bao giờ chấp nhận log từ người khác, chỉ ghi đè log của mình lên người khác.

==== Follower
- *Vai trò:* Thụ động. Chỉ phản hồi các yêu cầu từ Leader hoặc Candidate.
- *Đặc điểm:*
    - Không bao giờ tự gửi yêu cầu.
    - Nếu nhận được request từ Client, nó sẽ từ chối và chỉ đường cho Client đến Leader.
    - Nếu không nhận được Heartbeat từ Leader trong một khoảng thời gian (Election Timeout), nó sẽ giả định Leader đã chết và chuyển sang trạng thái Candidate.

==== Candidate
- *Vai trò:* Một trạng thái trung gian dùng để bầu cử Leader mới.
- *Đặc điểm:*
    - Khi chuyển sang Candidate, nó sẽ tự bầu cho chính mình và gửi yêu cầu `RequestVote` tới các node khác.
    - Nếu nhận được đa số phiếu (Majority Vote): Trở thành Leader.
    - Nếu phát hiện ra Leader khác hợp lệ: Trở về Follower.
    - Nếu hết giờ mà không ai thắng: Bắt đầu lại cuộc bầu cử mới.

=== Term

Trong hệ thống phân tán, chúng ta không thể dựa vào đồng hồ vật lý (Physical Clock) vì đồng hồ mỗi máy chạy nhanh chậm khác nhau (Clock Skew). Raft sử dụng khái niệm *Term* như một *Đồng hồ Logic (Logical Clock)* để phát hiện thông tin lỗi thời.

- *Cấu trúc:* Term là các số nguyên tăng dần liên tục (Term 1, Term 2, Term 3...).
- *Ý nghĩa:* Mỗi Term bắt đầu bằng một cuộc bầu cử (Election). Nếu bầu thành công, Term đó sẽ có 1 Leader duy nhất điều hành cho đến khi Term kết thúc (do Leader chết).
- *Cơ chế:*
    - Mọi tin nhắn giao tiếp trong Raft đều kèm theo `currentTerm`.
    - Nếu Server nhận được tin nhắn có `term < currentTerm` -> Nó từ chối tin nhắn đó (tin nhắn cũ).
    - Nếu Server nhận được tin nhắn có `term > currentTerm` -> Nó cập nhật `currentTerm` mới và lập tức chuyển thành Follower (nếu đang là Leader/Candidate).

*Ví dụ minh họa:*
Leader A đang ở Term 3. A bị mất mạng trong 10 phút. Trong lúc đó, cụm đã bầu ra Leader B ở Term 4, rồi Leader C ở Term 5.
Khi A kết nối lại mạng, nó gửi Heartbeat với `Term = 3`. Các node khác thấy `3 < 5` nên từ chối. A nhận ra mình đã lạc hậu, cập nhật Term lên 5 và trở thành Follower của C.

=== RPC

Raft chỉ sử dụng 2 loại Remote Procedure Call (RPC) chính:
1.  *RequestVote RPC:* Được Candidate gửi đi để xin phiếu bầu.
2.  *AppendEntries RPC:* Được Leader gửi đi để sao chép log entries và cũng dùng làm Heartbeat (khi log rỗng).

(Ngoài ra còn có InstallSnapshot RPC dùng để đồng bộ dữ liệu khi log quá dài, sẽ bàn ở phần tối ưu).