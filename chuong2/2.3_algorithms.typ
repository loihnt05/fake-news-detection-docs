== Các thuật toán phân phối tải <algorithms>

Thuật toán phân phối tải là "bộ não" của Load Balancer. Nó quyết định xem request tiếp theo sẽ được gửi đến server nào trong pool. Việc lựa chọn thuật toán phù hợp phụ thuộc vào đặc thù của ứng dụng, trạng thái của server và yêu cầu về hiệu năng.

=== Round Robin

Đây là thuật toán đơn giản nhất, cổ điển nhất và thường là mặc định trong nhiều phần mềm LB.

*Cơ chế:*
LB có một danh sách các server. Nó lần lượt gửi request theo thứ tự danh sách, xoay vòng từ đầu đến cuối rồi lặp lại.
- Request 1 -> Server A
- Request 2 -> Server B
- Request 3 -> Server C
- Request 4 -> Server A ...

*Ưu điểm:*
- Cực kỳ đơn giản, dễ cài đặt.
- Không tốn tài nguyên tính toán của LB.
- Phân phối khá đều nếu các request có chi phí xử lý tương đương nhau.

*Nhược điểm:*
- *Không quan tâm tải thực tế:* Nó không biết Server A đang quá tải hay Server B đang rảnh. Nó cứ nhắm mắt gửi.
- *Không quan tâm cấu hình:* Nếu Server A mạnh gấp đôi Server B, Server A cũng chỉ nhận lượng việc bằng Server B -> Lãng phí Server A và có thể làm sập Server B.

=== Weighted Round Robin

Phiên bản nâng cấp của Round Robin để giải quyết vấn đề chênh lệch cấu hình server.

*Cơ chế:*
Mỗi server được gán một "trọng số" (Weight) - một số nguyên dương biểu thị khả năng xử lý của nó. Server mạnh hơn có weight cao hơn.
- Server A (CPU mạnh): Weight = 3
- Server B (CPU yếu): Weight = 1
-> LB sẽ gửi 3 request cho A, rồi mới gửi 1 request cho B.

*Ưu điểm:*
- Tận dụng tốt tài nguyên của các server không đồng nhất.

*Nhược điểm:*
- Vẫn chưa quan tâm đến tải thực tế (Active Connections) tại thời điểm đó. Ví dụ: Server A tuy mạnh nhưng đang kẹt xử lý một tác vụ rất nặng (long-running process), việc dồn thêm 3 request nữa có thể làm nó chết.

=== Least Connections

Đây là thuật toán động (dynamic), thông minh hơn các thuật toán tĩnh (static) như Round Robin.

*Cơ chế:*
LB theo dõi số lượng kết nối đang mở (active connections) giữa nó và mỗi backend server. Request mới sẽ được gửi đến server nào đang có ít kết nối nhất.
- Server A: đang xử lý 10 request.
- Server B: đang xử lý 2 request.
-> Request mới -> Server B.

*Biến thể:* *Weighted Least Connections* (kết hợp trọng số và số kết nối).

*Ưu điểm:*
- Phản ánh chính xác tải của hệ thống. Server nào xử lý nhanh, trả kết nối sớm sẽ được nhận thêm việc. Server nào bị kẹt, xử lý chậm sẽ ít bị giao việc hơn.
- Rất phù hợp cho các request có thời gian xử lý chênh lệch lớn (ví dụ: request lấy ảnh mất 10ms, request xuất báo cáo mất 5s).

*Nhược điểm:*
- Tốn tài nguyên tính toán hơn một chút để theo dõi trạng thái connection.
- Trong kịch bản "TCP Connection Storm" (hàng loạt connect mới ập đến cực nhanh), số liệu counter có thể cập nhật không kịp.

=== Least Response Time

Thuật toán này còn tinh vi hơn Least Connections.

*Cơ chế:*
LB đo thời gian phản hồi (Time to First Byte - TTFB) của server đối với các request trước đó hoặc qua Health Check.
Công thức tính điểm ưu tiên thường là: \$(Active Connections) \* (Response Time)\$.
Server nào có thời gian phản hồi nhanh nhất VÀ ít kết nối nhất sẽ được chọn.

*Ưu điểm:*
- Chọn được server đang "khỏe" nhất thực sự.

*Nhược điểm:*
- Phức tạp, tốn tài nguyên tính toán nhất.

=== IP Hash

*Cơ chế:*
LB lấy địa chỉ IP của Client, đưa qua một hàm băm (hashing function) để tính ra một con số. Sau đó dùng phép chia lấy dư (modulo) cho số lượng server để xác định đích đến.
\$ ServerIndex = hash(ClientIP) % NumberOfServers \$

*Đặc điểm quan trọng:*
- Cùng một IP khách hàng sẽ *luôn luôn* được định tuyến về cùng một server (miễn là số lượng server không đổi).
- Đây là một cách đơn giản để đạt được *Session Stickiness*.

*Nhược điểm:*
- Nếu một server chết hoặc thêm server mới, công thức modulo thay đổi -> Gần như toàn bộ mapping bị xáo trộn. Tất cả user bị văng session (đăng xuất).
- Phân phối có thể không đều nếu có một lượng lớn user đến từ cùng một IP NAT (ví dụ: proxy của một trường đại học).

=== Random

*Cơ chế:*
Chọn đại một server ngẫu nhiên.

*Thực tế:*
Về mặt xác suất thống kê, khi số lượng request đủ lớn (vài triệu), Random sẽ tiệm cận với Round Robin. Thuật toán này thường dùng trong các hệ thống peer-to-peer hoặc gossip protocol hơn là LB truyền thống.

=== Consistent Hashing

Đây là thuật toán quan trọng nhất trong các hệ thống phân tán quy mô lớn (như Amazon DynamoDB, Cassandra, Memcached), giải quyết nhược điểm chí mạng của IP Hash (Modulo Hashing).

*Vấn đề của Modulo Hashing:*
Khi số lượng server \$N\$ thay đổi (thêm/bớt server), công thức \$hash(key) % N\$ thay đổi kết quả với hầu hết các key. Dữ liệu phải di chuyển tán loạn (Reshuffling).

*Giải pháp Consistent Hashing:*
- Tưởng tượng một vòng tròn số (Hash Ring) có giá trị từ 0 đến \$2^{32}-1\$.
- Các server được băm và đặt tại các điểm trên vòng tròn này.
- Request (Client IP) cũng được băm và đặt lên vòng tròn.
- Để tìm server cho request, ta đi theo chiều kim đồng hồ trên vòng tròn, gặp server nào đầu tiên thì chọn server đó.

*Ưu điểm tuyệt đối:*
- *Khi thêm server mới:* Chỉ những request nằm trong khoảng giữa server mới và server liền trước nó bị ảnh hưởng (chuyển sang server mới). Các request khác giữ nguyên.
- *Khi bỏ server cũ:* Chỉ những request đang trỏ vào server đó bị chuyển sang server kế tiếp.
-> Giảm thiểu tối đa việc di chuyển dữ liệu hoặc mất session.

*Kỹ thuật Virtual Nodes:*
Để tránh việc phân bố không đều trên vòng tròn (server A quản lý vùng quá rộng, B quá hẹp), người ta tạo ra nhiều "node ảo" cho mỗi server thật (ví dụ Server A có A1, A2, A3... rải rác khắp vòng tròn). Điều này giúp tải được chia đều hơn.