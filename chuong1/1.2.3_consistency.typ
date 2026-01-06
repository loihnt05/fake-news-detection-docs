== Consistency <consistency>

=== Bản chất của Consistency trong Hệ thống phân tán

Trong một hệ thống chỉ có một máy chủ (single node), tính nhất quán là điều hiển nhiên: Khi bạn thay đổi giá trị của biến X từ 5 thành 10, lần đọc tiếp theo chắc chắn sẽ trả về 10. Nhưng trong hệ thống phân tán (distributed systems) với dữ liệu được sao chép (replicated) ra nhiều nơi, điều này trở thành một thách thức khổng lồ.

Consistency trong ngữ cảnh này được hiểu là: *Sự đồng bộ dữ liệu giữa các bản sao (replicas).* Khi một user ghi dữ liệu vào Node A, mất bao lâu để user khác đọc từ Node B thấy được dữ liệu đó?

=== Định lý CAP và PACELC

Không thể nói về Consistency mà không nhắc đến CAP Theorem.

==== CAP Theorem
Định lý phát biểu rằng một hệ thống phân tán chỉ có thể đảm bảo tối đa 2 trong 3 thuộc tính sau:
- *Consistency (C):* Mọi lần đọc đều trả về dữ liệu mới nhất hoặc báo lỗi. (Đồng nhất dữ liệu).
- *Availability (A):* Mọi yêu cầu đều nhận được phản hồi (không bị báo lỗi), nhưng không đảm bảo dữ liệu là mới nhất. (Sẵn sàng phục vụ).
- *Partition Tolerance (P):* Hệ thống vẫn hoạt động dù mạng bị đứt gãy, làm mất kết nối giữa các node. (Chịu lỗi phân vùng mạng).

*Thực tế:* Trong hệ thống phân tán qua mạng internet, P là điều *bắt buộc* (vì mạng luôn có thể đứt). Do đó, ta chỉ được chọn giữa C và A (CP hoặc AP).
- *Chọn CP (Consistency over Availability):* Khi mạng đứt, thà từ chối phục vụ (downtime) còn hơn trả về dữ liệu sai/cũ. (Ví dụ: Ngân hàng, ATM).
- *Chọn AP (Availability over Consistency):* Khi mạng đứt, cứ trả về dữ liệu cũ cũng được, miễn là hệ thống vẫn chạy. Sau khi mạng có lại sẽ đồng bộ sau. (Ví dụ: Facebook News Feed, Amazon Shopping Cart).

==== Định lý PACELC
CAP chỉ nói về trường hợp mạng bị đứt (Partition). Vậy khi mạng bình thường (Else - E) thì sao? PACELC bổ sung:
- *P (Partition):* Chọn A hoặc C.
- *E (Else - Normal operation):* Chọn L (Latency - Độ trễ thấp) hoặc C (Consistency - Nhất quán cao).

Nghĩa là: Ngay cả khi mạng tốt, bạn vẫn phải đánh đổi. Muốn dữ liệu đồng bộ tức thì (Strong Consistency) thì phải chấp nhận độ trễ cao (do phải chờ các node xác nhận). Muốn nhanh (Low Latency) thì phải chấp nhận dữ liệu có thể chưa đồng bộ kịp (Eventual Consistency).

=== Các mức độ nhất quán

Có một phổ (spectrum) rộng các mô hình nhất quán, từ mạnh đến yếu:

==== Strong Consistency
- *Đặc điểm:* Hệ thống hoạt động như thể chỉ có một bản sao dữ liệu duy nhất. Ngay sau khi thao tác ghi hoàn tất, mọi thao tác đọc ở bất kỳ đâu đều thấy giá trị mới.
- *Cài đặt:* Thường dùng các thuật toán đồng thuận như Paxos, Raft, hoặc 2-Phase Commit (2PC). Khi ghi, phải khóa (lock) hoặc chờ đa số (quorum) xác nhận.
- *Ưu điểm:* Dễ lập trình, logic đơn giản.
- *Nhược điểm:* Hiệu năng thấp, độ trễ cao, Availability thấp (dễ bị treo nếu một vài node chết).

==== Weak Consistency
- *Đặc điểm:* Sau khi ghi, hệ thống không đảm bảo user sẽ thấy dữ liệu mới ngay. Có thể thấy, có thể không.
- *Ví dụ:* Hệ thống chat realtime (đôi khi tin nhắn đến trễ hoặc mất), VoIP, Game online.

==== Eventual Consistency
- *Đặc điểm:* Là dạng phổ biến nhất của Weak Consistency trong các hệ thống lớn. Đảm bảo rằng nếu không có cập nhật mới nào, thì *cuối cùng* (sau một khoảng thời gian không xác định), tất cả các bản sao sẽ đồng bộ.
- *Ưu điểm:* Hiệu năng cực cao, Availability tuyệt đối.
- *Nhược điểm:* Gây bối rối cho user (Ví dụ: Vừa comment xong F5 lại không thấy comment đâu).

==== Các biến thể mạnh hơn của Eventual Consistency
Để khắc phục nhược điểm của Eventual Consistency, người ta đẻ ra các mô hình lai:
- *Read-your-writes Consistency:* Đảm bảo rằng sau khi TÔI ghi, TÔI sẽ đọc lại được cái tôi vừa ghi (dù người khác có thể chưa thấy). Cái này quan trọng nhất cho UX.
- *Monotonic Reads:* Nếu bạn đã đọc được bản ghi version 2, bạn sẽ không bao giờ bị đọc lại version 1 (cũ hơn) trong tương lai.
- *Causal Consistency:* Đảm bảo thứ tự nhân quả. Nếu comment B trả lời comment A, thì mọi người phải thấy A trước rồi mới thấy B. Không bao giờ được hiện B trước A.

=== Cơ chế Quorum

Trong các hệ thống như Cassandra hay DynamoDB, ta có thể tùy chỉnh mức độ Consistency linh hoạt thông qua 3 tham số:
- *N:* Số lượng bản sao (Replicas).
- *W:* Số lượng node cần xác nhận GHI thành công thì mới báo thành công cho client.
- *R:* Số lượng node cần xác nhận ĐỌC thành công (để so sánh lấy bản mới nhất).

Công thức Quorum:
- Nếu $R + W > N$: Ta đạt được *Strong Consistency* (Vì chắc chắn tập hợp node đọc và tập hợp node ghi sẽ giao nhau ít nhất 1 node chứa dữ liệu mới nhất).
- Nếu $R + W <= N$: Ta có *Eventual Consistency* (Có khả năng đọc phải toàn các node chưa được cập nhật).

*Ví dụ cấu hình:*
- Cần tốc độ ghi cực nhanh: Đặt W = 1 (chỉ cần 1 node nhận là xong). Rủi ro mất dữ liệu cao.
- Cần an toàn dữ liệu: Đặt W = Majority (ví dụ N=3, W=2).
- Cần đọc nhanh: Đặt R = 1.

=== Kết luận

Consistency là một sự lựa chọn, không phải là một tính năng mặc định.
- Với dữ liệu tiền bạc, kho hàng: Chọn *Strong Consistency*. Chậm chút nhưng đúng.
- Với dữ liệu mạng xã hội, lượt view, trạng thái online: Chọn *Eventual Consistency*. Nhanh là trên hết, sai lệch chút không sao.
- Kỹ sư giỏi là người biết phân loại dữ liệu để áp dụng mô hình Consistency phù hợp cho từng phần của hệ thống.