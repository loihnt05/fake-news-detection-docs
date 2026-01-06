== Log Replication <normal_operation>

Sau khi bầu được Leader, hệ thống đi vào trạng thái hoạt động bình thường. Nhiệm vụ chính lúc này là sao chép các lệnh từ Client tới tất cả các node để đảm bảo Replicated State Machine.

=== Cấu trúc của Log

Mỗi Log Entry (Mục nhật ký) chứa 3 thông tin:
1.  *Command:* Lệnh thay đổi trạng thái (ví dụ: `x = 5`, `SET key value`).
2.  *Term:* Nhiệm kỳ tại thời điểm lệnh được tạo.
3.  *Index:* Số thứ tự của entry trong danh sách log (1, 2, 3...).

=== Quy trình xử lý Client Request

Toàn bộ quy trình diễn ra như một giao thức *Two-Phase Commit* (nhưng đơn giản hơn 2PC truyền thống vì có Leader điều phối).

==== Append Local
- Client gửi request `SET x=5` tới Leader.
- Leader ghi log entry mới `[Term=1, Cmd="x=5"]` vào log của chính mình (nhưng chưa thực thi/apply).

==== Replicate
- Leader gửi tin nhắn `AppendEntries RPC` tới tất cả Followers song song.
- Tin nhắn chứa log entry mới.

==== Follower Acknowledge
- Follower nhận được `AppendEntries`.
- Nó kiểm tra tính nhất quán (Consistency Check - xem mục 3 bên dưới).
- Nếu OK, nó ghi log vào đĩa cứng và trả lời `Success` cho Leader.

==== Commit & Apply
- Khi Leader nhận được `Success` từ *đa số* (Majority) các Followers.
- Leader đánh dấu log entry đó là *Committed*.
- Leader thực thi lệnh `x=5` vào State Machine của mình.
- Leader trả kết quả "OK" cho Client.

==== Notify Followers
- Trong lần Heartbeat tiếp theo, Leader thông báo cho Followers biết: "Entry này đã Commit rồi nhé".
- Followers nghe thấy thế cũng thực thi lệnh `x=5` vào State Machine của họ.
-> *Kết quả:* Tất cả các máy đều có `x=5`.

=== Log Consistency

Trong thực tế, log của Follower có thể khác với Leader (do Follower bị crash, mạng lag).
Raft đảm bảo thuộc tính *Log Matching Property*:
- Nếu 2 log entry có cùng Index và Term, chúng chứa cùng Command.
- Nếu 2 log entry có cùng Index và Term, thì *tất cả các entry đứng trước nó* cũng giống hệt nhau.

Để duy trì thuộc tính này, Raft sử dụng cơ chế kiểm tra trong `AppendEntries RPC`.
Khi Leader gửi entry tại Index 10, nó đính kèm thông tin của entry tại Index 9 (`prevLogIndex=9`, `prevLogTerm=...`).

*Kịch bản sửa lỗi:*
1.  Leader gửi entry 10 kèm `prevLogIndex=9`.
2.  Follower kiểm tra log của mình tại Index 9.
    - Nếu khớp Term: Ghi entry 10, trả `Success`.
    - Nếu không khớp (hoặc không có entry 9): Từ chối, trả `Fail`.
3.  Nếu Leader nhận được `Fail`:
    - Leader biết Follower này bị lạc hậu.
    - Leader lùi lại 1 bước, gửi lại entry 9 kèm `prevLogIndex=8`.
    - Cứ lùi dần (Decrement `nextIndex`) cho đến khi tìm được điểm chung khớp nhau giữa Leader và Follower.
    - Sau khi khớp, Leader gửi toàn bộ log từ điểm đó trở đi đè lên log cũ của Follower.
    - *Kết quả:* Log của Follower trở nên giống hệt Leader.

=== Heartbeat

- Leader định kỳ gửi `AppendEntries` rỗng (không có data) để:
    1.  Ngăn Follower timeout và bầu cử lại.
    2.  Cập nhật `commitIndex` cho Follower (để Follower biết mà apply log).
- Chu kỳ Heartbeat thường là 50ms - 100ms (nhỏ hơn nhiều so với Election Timeout).

=== Tối ưu hóa

- *Batching:* Leader không gửi từng lệnh lẻ tẻ mà gom nhiều lệnh vào một gói tin mạng để tăng Throughput.
- *Pipelining:* Leader gửi liên tiếp các AppendEntries mà không cần chờ ACK của cái trước (tuy nhiên phải xử lý cẩn thận thứ tự).
- *Snapshotting (Log Compaction):* Log không thể dài vô tận. Khi log đạt dung lượng lớn, Server tự động chụp ảnh trạng thái hiện tại (Snapshot), lưu vào file riêng và xóa toàn bộ log cũ đi để giải phóng ổ cứng.