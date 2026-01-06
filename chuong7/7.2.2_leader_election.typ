== Leader Election <leader_election>

Raft sử dụng cơ chế Heartbeat để kích hoạt bầu cử. Khi hệ thống khởi động, tất cả các node đều là Follower. Chúng chờ đợi tín hiệu từ Leader. Nếu Follower không nhận được Heartbeat trong khoảng thời gian `Election Timeout`, nó sẽ coi như Leader đã chết và bắt đầu bầu cử.

=== Quy trình bầu cử chi tiết

Khi một Follower quyết định tranh cử, nó thực hiện các bước sau:
1.  *Tăng Term:* Tăng `currentTerm` lên 1.
2.  *Chuyển trạng thái:* Chuyển từ Follower sang Candidate.
3.  *Tự bầu cử:* Bỏ 1 phiếu cho chính mình.
4.  *Gửi RequestVote:* Gửi tin nhắn `RequestVote RPC` song song tới tất cả các node khác trong cụm.

Nội dung tin nhắn `RequestVote` bao gồm:
- `term`: Nhiệm kỳ hiện tại của ứng viên.
- `candidateId`: ID của ứng viên.
- `lastLogIndex`: Index của log cuối cùng mà ứng viên có.
- `lastLogTerm`: Term của log cuối cùng đó.

=== Voters

Mỗi node nhận được `RequestVote` sẽ quyết định cho phiếu (Grant Vote) hay không dựa trên logic chặt chẽ:

1.  *Kiểm tra Term:*
    - Nếu `term` của ứng viên < `currentTerm` của cử tri -> *Từ chối* (Ứng viên lạc hậu).
    - Nếu `term` của ứng viên > `currentTerm` của cử tri -> Cử tri cập nhật Term mới, chuyển thành Follower.

2.  *Kiểm tra phiếu đã bỏ:*
    - Trong một Term, mỗi Follower chỉ được bầu cho *tối đa 1 ứng viên*. (First-come-first-served).
    - Nếu đã bầu cho người khác rồi -> *Từ chối*.

3.  *Kiểm tra độ tươi mới của Log (Log Matching Property):*
    - Đây là điều kiện quan trọng nhất để đảm bảo an toàn dữ liệu (Safety). Raft không cho phép bầu một Leader bị mất dữ liệu.
    - Cử tri so sánh Log của mình với Log của ứng viên.
    - Nếu Log của ứng viên "kém cập nhật hơn" (stale) so với cử tri -> *Từ chối*.
    - *Định nghĩa "Cập nhật hơn":* Log A cập nhật hơn Log B nếu `Term` cuối cùng của A lớn hơn B, hoặc nếu Term bằng nhau thì `Index` của A lớn hơn B.

=== Kết quả bầu cử

Sau khi gửi RequestVote, Candidate chờ đợi 1 trong 3 kịch bản:

==== Win
- Candidate nhận được phiếu bầu từ *đa số* (Majority / Quorum) các node trong cụm.
- *Công thức Quorum:* $N/2 + 1$. Ví dụ cụm 5 node cần 3 phiếu. Cụm 3 node cần 2 phiếu.
- Hành động:
    - Chuyển trạng thái thành *Leader*.
    - Gửi ngay lập tức *Heartbeat* (AppendEntries) tới tất cả để khẳng định chủ quyền và ngăn chặn các cuộc bầu cử khác.

==== Lose
- Trong khi đang chờ phiếu, Candidate nhận được một Heartbeat từ một node khác tự xưng là Leader.
- Nếu Heartbeat đó có `term >= currentTerm`:
    - Candidate thừa nhận Leader mới hợp pháp.
    - Chuyển trạng thái về *Follower*.

==== Split Vote
- Không ai đạt được đa số phiếu.
- *Ví dụ:* Cụm 5 node. Node A nhận 2 phiếu, Node B nhận 2 phiếu, Node C nhận 1 phiếu. Không ai đủ 3.
- Hậu quả: Election Timeout hết hạn mà chưa có Leader.

=== Randomized Election Timeout

Nếu các node có Timeout giống hệt nhau (ví dụ cùng 150ms), chúng sẽ cùng phát hiện Leader chết cùng lúc, cùng ứng cử cùng lúc, và chia phiếu liên tục -> Hệ thống treo vĩnh viễn (Livelock).

Raft giải quyết cực kỳ đơn giản và thanh lịch bằng *Sự ngẫu nhiên*:
- Mỗi node chọn một `Election Timeout` ngẫu nhiên trong khoảng cố định (ví dụ: 150ms - 300ms).
- Node nào có Timeout ngắn hơn sẽ tỉnh dậy trước, ứng cử trước và gom hết phiếu trước khi các node khác kịp tỉnh dậy.

*Ví dụ:*
- Node A random được 150ms.
- Node B random được 280ms.
- Leader chết.
- Sau 150ms, A tỉnh dậy, gửi RequestVote.
- B vẫn đang ngủ (còn 130ms nữa mới dậy). B nhận được RequestVote của A -> B bầu cho A -> A thắng.

=== Majority

Tại sao không chỉ cần 1 phiếu là thắng?
Để ngăn chặn *Split-Brain*.
- Nếu mạng bị chia cắt thành 2 vùng: Vùng 1 (2 node), Vùng 2 (3 node).
- Nếu chỉ cần ít phiếu, Vùng 1 bầu ra Leader A, Vùng 2 bầu ra Leader B.
- Dữ liệu sẽ bị ghi chéo -> Hỏng Database.
- Với luật Majority (Quorum), Vùng 1 (2/5 node) không đủ phiếu bầu Leader. Chỉ Vùng 2 (3/5 node) bầu được Leader. Hệ thống vẫn nhất quán.