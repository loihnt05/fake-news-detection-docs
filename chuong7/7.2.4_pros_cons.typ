== Ưu và nhược điểm của Raft <raft_pros_cons>

Raft đã trở thành tiêu chuẩn vàng cho các hệ thống phân tán hiện đại (như Kubernetes, Docker Swarm, CockroachDB). Tuy nhiên, không có thuật toán nào là hoàn hảo.

=== Pros

==== Understandability
Đây là mục tiêu thiết kế số 1 của Raft.
- Raft tách biệt rõ ràng các module: Leader Election, Log Replication, Safety. Điều này giúp sinh viên và kỹ sư dễ dàng hình dung và cài đặt.
- So với Paxos (nơi mọi node đều có vai trò ngang nhau và luồng tin nhắn rất rối rắm), mô hình "Strong Leader" của Raft trực quan hơn nhiều.

==== Strong Leader
- Trong Raft, luồng dữ liệu chỉ đi một chiều: Leader -> Follower.
- Việc quản lý log trở nên đơn giản: Chỉ cần quản lý log trên Leader, các Follower chỉ việc copy theo. Không cần cơ chế merge log phức tạp.
- Hiệu năng đọc (Read performance) có thể được tối ưu: Client có thể đọc trực tiếp từ Leader mà không cần qua vòng Consensus (nếu dùng Lease Read).

==== Safety
Raft chứng minh được tính đúng đắn một cách chặt chẽ.
- Không bao giờ có 2 Leader cùng lúc (trong cùng 1 Term).
- Không bao giờ mất dữ liệu đã Commit (Committed entries are durable).
- Log Matching Property đảm bảo log luôn nhất quán.

==== Hệ sinh thái phong phú
Do dễ hiểu, Raft có hàng trăm thư viện implementation chất lượng cao trên mọi ngôn ngữ:
- Go: `etcd/raft`, `hashicorp/raft`.
- Java: `Apache Ratis`.
- C++: `LogCabin`.

=== Cons

==== Leader Bottleneck
- *Vấn đề:* Mọi thao tác Ghi (Write) đều PHẢI đi qua Leader. Leader làm việc cật lực, trong khi các Follower chỉ ngồi chơi xơi nước (Idle).
- *Hậu quả:* Throughput (Thông lượng) ghi của cả cụm Raft không bao giờ vượt quá khả năng xử lý của 1 máy đơn lẻ (Leader). Thêm 100 node vào cụm cũng không làm tăng tốc độ ghi, chỉ tăng độ an toàn.
- *So sánh:* Các giao thức như *Multi-Master* hoặc *Epaxos* cho phép ghi vào bất kỳ node nào, giúp scale-out tốt hơn Raft.

==== Geo-distributed Latency
- Raft yêu cầu đa số (Quorum) xác nhận.
- Nếu bạn triển khai cụm Raft trên 3 châu lục: Mỹ, Á, Âu. Mỗi lần ghi, Leader (ở Mỹ) phải chờ tín hiệu từ Á hoặc Âu. Round-trip time (RTT) qua đại dương là hàng trăm mili-giây.
- Điều này làm giảm đáng kể tốc độ phản hồi.

==== Stop-the-world khi bầu cử
- Khi Leader chết, hệ thống sẽ bị "đóng băng" (Unavailable) trong khoảng thời gian Election Timeout (vài trăm ms đến vài giây).
- Trong thời gian này, không request nào được xử lý. Đối với các hệ thống yêu cầu độ trễ cực thấp (Real-time trading), đây là một vấn đề.

==== Log Log Log
- Raft dựa trên Log. Nếu ổ cứng chậm (Disk I/O bottleneck), toàn bộ hệ thống chậm.
- Việc Snapshotting (nén log) tiêu tốn nhiều CPU và I/O, có thể gây giật lag (jitter) cho hệ thống nếu không được tối ưu kỹ.

=== So sánh nhanh với các đối thủ

#table(
  columns: (1fr, 1fr, 1fr),
  inset: 10pt,
  align: horizon,
  table.header(
    [*Tiêu chí*], [*Raft*], [*Paxos (Multi-Paxos)*]
  ),
  [Độ dễ hiểu], [Cao], [Rất thấp (Hàn lâm)],
  [Cài đặt thực tế], [Dễ, chuẩn hóa], [Khó, nhiều biến thể],
  [Hiệu năng], [Tốt], [Tốt (tối ưu hơn Raft chút xíu)],
  [Đại diện], [Etcd, Consul], [Google Spanner, Chubby]
)

== Kết luận
Raft là lựa chọn tốt nhất cho hầu hết các nhu cầu Consensus hiện nay nhờ sự cân bằng giữa Hiệu năng, Độ tin cậy và Khả năng bảo trì. Tuy nhiên, nếu cần hiệu năng ghi cực cao (High Write Throughput), cần cân nhắc các giải pháp Sharding kết hợp Raft (như CockroachDB) thay vì một cụm Raft đơn lẻ.