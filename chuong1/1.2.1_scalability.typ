== Scalability <scalability>

=== Định nghĩa chuyên sâu

Khả năng mở rộng (Scalability) thường bị nhầm lẫn với Hiệu năng (Performance), nhưng chúng là hai khái niệm khác nhau dù có liên quan mật thiết.
- *Performance:* Trả lời câu hỏi "Hệ thống chạy nhanh thế nào với tải hiện tại?". Ví dụ: Thời gian phản hồi là 200ms cho 1 user.
- *Scalability:* Trả lời câu hỏi "Nếu tôi thêm tài nguyên, hệ thống có giữ được performance đó khi tải tăng gấp đôi không?". Ví dụ: Nếu 1000 user cũng có thời gian phản hồi ~200ms sau khi ta thêm server, hệ thống đó scalable.

Scalability là khả năng của hệ thống trong việc xử lý lượng công việc ngày càng tăng (traffic, volume dữ liệu, độ phức tạp) bằng cách thêm tài nguyên (CPU, RAM, Disk, Network) một cách hiệu quả.

=== Chiến lược 1: Vertical Scaling

Đây là phương pháp "cổ điển" và tự nhiên nhất: Khi máy chậm, ta mua máy mạnh hơn.

==== Cơ chế hoạt động
Thay thế instance hiện tại bằng một instance có cấu hình cao hơn (High-end hardware).
- Tăng số nhân CPU (Cores).
- Tăng dung lượng RAM (Memory).
- Chuyển từ HDD sang SSD hoặc NVMe SSD.
- Nâng cấp card mạng (1Gbps lên 10Gbps/100Gbps).

==== Ưu điểm
1.  *Không cần sửa code:* Ứng dụng không cần biết nó đang chạy trên máy tính nào. Không cần thiết kế lại kiến trúc phân tán phức tạp.
2.  *Quản lý đơn giản:* Vẫn chỉ là một node duy nhất (hoặc một cặp Active-Passive). Không cần load balancer phức tạp, không lo về data consistency giữa các node.
3.  *Hiệu quả cho Database:* Với các RDBMS truyền thống (MySQL, PostgreSQL) vốn khó scale ngang cho thao tác ghi (write), scale up là giải pháp đầu tiên và hiệu quả nhất để tăng throughput.

==== Nhược điểm chí mạng
1.  *Giới hạn phần cứng (Hard Limit):* Dù bạn có bao nhiêu tiền, công nghệ hiện tại cũng có giới hạn. Không có máy chủ nào có 1 triệu Terabyte RAM hay 1 triệu CPU cores. Khi chạm trần phần cứng, bạn "hết đường".
2.  *Chi phí phi tuyến tính (Diminishing Returns):* Giá của phần cứng cao cấp tăng theo cấp số nhân so với hiệu năng. Một máy chủ 128GB RAM có thể đắt gấp 5 lần máy 64GB RAM nhưng chỉ nhanh hơn chưa đến 2 lần.
3.  *Rủi ro tập trung (SPOF):* "Bỏ tất cả trứng vào một giỏ". Khi siêu máy tính này cần bảo trì hoặc gặp sự cố, toàn bộ hệ thống tê liệt.
4.  *Vendor Lock-in:* Phụ thuộc hoàn toàn vào nhà cung cấp phần cứng hoặc cloud provider cho các instance size lớn.

=== Chiến lược 2: Horizontal Scaling

Đây là tiêu chuẩn của các hệ thống phân tán hiện đại (Cloud Native). Thay vì nuôi một con hổ lớn, ta nuôi một bầy sói.

==== Cơ chế hoạt động
Thêm nhiều node (máy chủ/container) vào hệ thống để chia sẻ tải. Các node này thường là máy chủ phổ thông (commodity hardware), giá rẻ.

==== Các thành phần thiết yếu
Để Scale Out thành công, hệ thống cần các thành phần hỗ trợ:

1.  *Load Balancer:*
    Đứng trước cụm server, phân phối traffic đến các node.
    - *Thuật toán:* Round Robin (lần lượt), Least Connections (chọn node rảnh nhất), IP Hash (dựa trên IP user để stick session).
    - *Loại:* Software (Nginx, HAProxy) hoặc Hardware (F5), Cloud (AWS ALB/NLB).

2.  *Stateless Application:*
    Đây là yêu cầu tiên quyết. Web server không được lưu trạng thái user (session, biến cục bộ) trong bộ nhớ RAM của chính nó.
    - Nếu lưu session trong RAM server A, lần sau user request vào server B sẽ bị mất session -> Đăng xuất.
    - *Giải pháp:* Đẩy trạng thái ra ngoài (External Store) như Redis, Memcached hoặc Database.

3.  *Distributed Database:*
    Database là thành phần khó scale out nhất.
    - *Replication (Master-Slave):* Tách tách vụ đọc (Read) sang Slave, ghi (Write) vào Master. Giúp scale Read tốt.
    - *Sharding:* Chia dữ liệu thành nhiều phần nhỏ (shard) dựa trên Sharding Key (ví dụ: UserID). User ID 1-1000 nằm ở Server A, 1001-2000 nằm ở Server B.
    - *NoSQL:* Các database như Cassandra, MongoDB, DynamoDB được thiết kế để scale out tự nhiên.

#figure(image("../images/pic3.jfif"), caption: [Vertical vs Horizontal Scaling Diagram])

==== Ưu điểm
1.  *Khả năng mở rộng vô hạn (về lý thuyết):* Có thể thêm hàng nghìn node để xử lý traffic toàn cầu.
2.  *Linh hoạt (Elasticity):* Có thể tự động tăng số lượng server vào giờ cao điểm (Auto-scaling) và giảm bớt vào giờ thấp điểm để tiết kiệm tiền. Đây là lợi thế lớn nhất của Cloud Computing.
3.  *Tính chịu lỗi cao (Fault Tolerance):* Mất 1 server trong cụm 100 server là chuyện nhỏ. Hệ thống vẫn chạy bình thường.

==== Nhược điểm
1.  *Độ phức tạp cao:* Lập trình phân tán rất khó. Phải xử lý race conditions, distributed transactions, data sync.
2.  *Độ trễ mạng (Network Latency):* Giao tiếp giữa các node qua mạng chậm hơn nhiều so với giao tiếp trong RAM/CPU.
3.  *Vận hành vất vả:* Cần hệ thống monitoring, logging tập trung, deployment tự động hóa.

=== Khi nào chọn cái nào?

Trong thực tế, chúng ta thường kết hợp cả hai (Hybrid Approach).

- *Giai đoạn đầu:* Dùng Vertical Scaling. Đơn giản, nhanh chóng. Mua một con database thật to để không phải lo nghĩ về sharding sớm.
- *Giai đoạn tăng trưởng:* Bắt đầu tách lớp Web/App ra và Scale Out (vì stateless dễ scale). Database vẫn giữ Scale Up hoặc thêm Read Replicas.
- *Giai đoạn khổng lồ:* Chuyển Database sang Sharding (Scale Out) hoặc dùng NoSQL. Tối ưu hóa từng service, kết hợp server mạnh cho các tác vụ nặng (AI/ML) và server nhỏ cho các tác vụ nhẹ (API Gateway).

=== Các định luật cần nhớ

1.  *Định luật Amdahl:* Sự cải thiện hiệu năng tổng thể khi dùng nhiều bộ xử lý bị giới hạn bởi phần tuần tự (không thể song song hóa) của chương trình. Nghĩa là không phải cứ thêm server là hệ thống nhanh lên tuyến tính. Sẽ có điểm bão hòa.
2.  *Universal Scalability Law (USL):* Mở rộng định luật Amdahl, tính thêm chi phí giao tiếp (coherency penalty) giữa các node. Khi số lượng node tăng quá mức, hiệu năng thậm chí có thể *giảm* do các node dành quá nhiều thời gian để "nói chuyện" và đồng bộ với nhau thay vì làm việc.