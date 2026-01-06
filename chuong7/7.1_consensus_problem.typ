== Consensus <consensus_problem>

=== Định nghĩa và Bản chất

Trong khoa học máy tính, đặc biệt là trong lĩnh vực hệ thống phân tán (Distributed Systems), *Consensus (Sự đồng thuận)* là quá trình đạt được sự thống nhất về một giá trị dữ liệu duy nhất giữa các tiến trình (processes) hoặc node phân tán, ngay cả khi một số thành phần trong hệ thống bị lỗi hoặc mạng bị gián đoạn.

Nói một cách đơn giản: Làm sao để một nhóm 5 máy chủ cùng đồng ý rằng "x = 5", dù 2 máy chủ trong đó đang bị mất điện?

==== State Machine Replication (SMR)
Bài toán Consensus thường được đặt trong bối cảnh của *State Machine Replication*.
- Hãy tưởng tượng một máy chủ là một Cỗ máy trạng thái (State Machine). Nếu ta xuất phát từ cùng một trạng thái đầu (Initial State) và áp dụng cùng một chuỗi các lệnh (Logs) theo đúng thứ tự, thì ta sẽ luôn đạt được cùng một trạng thái cuối cùng.
- Mục tiêu của Consensus là đảm bảo *Replicated Log* (Nhật ký được sao chép) là giống hệt nhau trên tất cả các server.

*Tính chất bắt buộc của Consensus:*
Một thuật toán đồng thuận đúng đắn phải đảm bảo 3 tính chất:
1.  *Termination (Kết thúc):* Mọi node không bị lỗi cuối cùng phải quyết định một giá trị. (Không được treo mãi mãi).
2.  *Agreement (Thỏa thuận):* Mọi node không bị lỗi phải quyết định cùng một giá trị. (Không được node A chọn X, node B chọn Y).
3.  *Validity (Tính hợp lệ):* Nếu tất cả các node đề xuất giá trị V, thì giá trị được quyết định phải là V. (Không được bịa ra giá trị ngẫu nhiên).

#figure(image("../images/pic24.png"), caption: [Raft Consensus Algorithm Diagram])

=== Vấn đề cần giải quyết: Tại sao nó khó?

Đồng thuận trong một phòng họp với con người đã khó, đồng thuận giữa các máy tính qua mạng còn khó hơn gấp bội vì các lý do sau:

==== Unreliable Network
- Tin nhắn gửi đi có thể bị mất (Packet loss).
- Tin nhắn có thể bị trễ ngẫu nhiên (Latency jitter).
- Tin nhắn có thể bị lặp lại hoặc đảo lộn thứ tự.
- Mạng có thể bị phân vùng (Network Partition/Split-brain), chia cụm server thành 2 đảo không nhìn thấy nhau.

==== Node Failures
- *Fail-Stop:* Máy chủ bị crash, mất điện và ngừng hoạt động hoàn toàn. Đây là mô hình lỗi mà Raft/Paxos giải quyết.
- *Byzantine Failure:* Máy chủ bị lỗi phần cứng hoặc bị hack, gửi thông tin sai lệch để phá hoại. (Raft không giải quyết lỗi này, cần PBFT).

==== FLP Impossibility Result
Năm 1985, Fischer, Lynch và Paterson đã chứng minh một định lý gây chấn động: *"Trong một hệ thống không đồng bộ (asynchronous system) nơi mà chỉ cần 1 process có thể bị crash, không tồn tại một thuật toán đồng thuận tất định (deterministic) nào có thể đảm bảo cả 3 tính chất (Termination, Agreement, Validity)."*

Tuy nhiên, trong thực tế, chúng ta vẫn xây dựng được các hệ thống đồng thuận (như Raft, Paxos) bằng cách nới lỏng yêu cầu về "tính không đồng bộ" (sử dụng timeout/clock) để đảm bảo tính thực tế (Liveness) trong hầu hết các trường hợp.

=== Ví dụ thực tế

Tại sao chúng ta cần Consensus? Hãy xem xét các hệ thống "xương sống" của Internet:

==== Leader Election
Trong một cụm Database Master-Slave. Nếu Master chết, ai sẽ lên thay?
- Nếu không có Consensus, Node A nghĩ mình là Master, Node B cũng nghĩ mình là Master (Split-brain).
- Cả hai cùng nhận lệnh ghi (Write) từ client.
- Dữ liệu bị xung đột, hỏng hóc vĩnh viễn.

==== Distributed Lock / Coordination
Kubernetes sử dụng *Etcd* (dùng thuật toán Raft) để lưu trữ trạng thái của toàn bộ cluster.
- Khi bạn deploy một Pod, lệnh đó được ghi vào Etcd thông qua Consensus.
- Nếu Etcd không đồng thuận, Kubernetes có thể deploy cùng 1 Pod lên 2 node khác nhau, hoặc mất luôn Pod đó.

==== Distributed Database
Các database NewSQL sử dụng Consensus Group (Raft Group) cho từng Shard (phân vùng dữ liệu).
- Mỗi Shard có 3 bản sao.
- Khi ghi dữ liệu, ít nhất 2/3 bản sao phải xác nhận "Đã ghi" thì mới báo thành công cho Client.

=== Kết luận
Consensus là "trái tim" của các hệ thống phân tán mạnh mẽ. Nó biến một cụm máy chủ hỗn độn, dễ lỗi thành một thực thể logic duy nhất, nhất quán và có khả năng chịu lỗi cao (Fault Tolerant).