== Distributed Cache <distributed_cache>

=== Mô tả chi tiết

Distributed Cache là hệ thống lưu trữ đệm hoạt động độc lập với ứng dụng, thường chạy trên các cụm máy chủ riêng biệt. Tất cả các node của ứng dụng (App Servers) đều kết nối và chia sẻ chung một kho dữ liệu cache này.

*Công nghệ phổ biến:*
- *Redis:* Vua của cache hiện tại. Hỗ trợ cấu trúc dữ liệu phong phú (List, Set, Hash, Sorted Set), độ bền dữ liệu (Persistence), và High Availability (Sentinel/Cluster).
- *Memcached:* Đơn giản, thuần túy key-value, đa luồng (multi-threaded) cực tốt, nhưng tính năng hạn chế hơn Redis.
- *Hazelcast / Apache Ignite:* In-memory Data Grid, thường dùng cho Java enterprise.

=== Khi nào dùng?

Distributed Cache là tiêu chuẩn bắt buộc cho:
1.  *Hệ thống Microservices / Auto-scaling:* Khi ứng dụng có nhiều hơn 1 server và cần chia sẻ trạng thái (Shared State).
2.  *Lưu trữ Session (Session Store):* Để user login ở Server A nhưng request sau vào Server B vẫn được nhận diện.
3.  *Rate Limiting toàn cục:* Đếm số request của 1 IP trên toàn bộ hệ thống.
4.  *Dữ liệu biến động và cần chia sẻ:* Giỏ hàng (Shopping Cart), Leaderboard (Bảng xếp hạng game).

=== Kiến trúc triển khai

Có hai mô hình chính để triển khai Distributed Cache:

==== Dedicated Cluster
- Cache chạy trên một dàn máy chủ riêng. Ứng dụng kết nối qua mạng (TCP/IP).
- *Ưu điểm:* Tách biệt tài nguyên. Cache sập không làm chết App. App sập không làm mất Cache. Dễ dàng scale độc lập.
- *Nhược điểm:* Độ trễ mạng (Network Latency).

==== Co-located
- Mỗi App server chạy kèm một tiến trình Redis (localhost).
- Thường không được coi là "Distributed" thực sự trừ khi các Redis này tạo thành Cluster. Ít dùng trong thực tế production lớn.

#figure(image("../images/pic6.jpg"), caption: [Local Cache vs Distributed Cache Diagram])

=== Ưu điểm

1.  *Nhất quán dữ liệu:*
    - Giải quyết vấn đề của Local Cache. Dù request rơi vào server nào, nó cũng đọc từ một nguồn duy nhất (Redis).
    - Dễ dàng invalidate: Xóa key ở Redis là tất cả server đều thấy hết dữ liệu.

2.  *Độc lập và Bền bỉ:*
    - App Server restart (deploy code mới) -> Cache vẫn còn nguyên. Hệ thống không bị "Cold Start".
    - Redis có thể cấu hình Snapshot (RDB) hoặc Log (AOF) để khôi phục dữ liệu khi mất điện.

3.  *Dung lượng khổng lồ:*
    - Có thể gộp hàng trăm GB hoặc cả Terabyte RAM từ nhiều máy chủ lại thành một khối (Redis Cluster).
    - Không bị giới hạn bởi Heap size của ứng dụng.

4.  *Tính năng nâng cao:*
    - Redis hỗ trợ Pub/Sub, Geo-spatial, Lua Scripting, Transactions.

=== Nhược điểm và Rủi ro

==== Độ trễ mạng
- Truy cập Local Cache: ~100ns.
- Truy cập Redis: ~500µs - 1ms.
- Chậm hơn gấp ngàn lần. Cần cân nhắc chi phí serialize/deserialize object.
- *Lưu ý:* Nếu một request cần gọi Redis 50 lần (N+1 query problem), độ trễ sẽ cộng dồn thành 50ms, rất đáng kể.

==== Sự phức tạp vận hành
- Phải quản lý một cụm server mới. Cần monitor, backup, patch lỗi bảo mật.
- Cấu hình Redis High Availability (Sentinel/Cluster) khá phức tạp và dễ làm sai (split-brain).

==== Điểm chết
- Nếu dùng 1 node Redis duy nhất và nó chết -> Toàn bộ hệ thống có thể tê liệt (nếu Database không gánh nổi tải thay thế).
- *Giải pháp:* Dùng Replication (Master-Slave) và Sentinel để tự động failover.

=== Các vấn đề kỹ thuật chuyên sâu

==== Serialization
Dữ liệu trong App là Object (Java Bean, Python Dict), trong Redis là Byte array hoặc String.
- Cần chọn format hiệu quả:
    - *Java Serialization:* Chậm, output lớn, bảo mật kém. Tránh dùng.
    - *JSON (Jackson/Gson):* Dễ đọc (human-readable), tương thích đa ngôn ngữ, nhưng tốn dung lượng (text base) và chậm.
    - *Protocol Buffers / MsgPack / Avro:* Binary format. Nhanh, gọn nhẹ, tiết kiệm băng thông mạng và RAM Redis. *Khuyên dùng cho hệ thống lớn.*

==== Thundering Herd
Khi một key quan trọng (Hot key) hết hạn (expire) hoặc bị xóa.
- Hàng nghìn request đồng thời ập đến -> Cùng không thấy trong Cache -> Cùng lao xuống DB để query -> Cùng cố gắng ghi đè vào Cache.
- Hậu quả: DB quá tải, CPU Redis tăng vọt.
- *Giải pháp:* Dùng Distributed Lock (Redis Lock) để chỉ cho phép 1 thread đi query DB, các thread khác chờ. Hoặc dùng kỹ thuật "Probabilistic Early Expiration".

==== Hot Key issue
- Trong Redis Cluster, dữ liệu được chia (sharding) theo slot.
- Nếu Key "Justin_Bieber_Profile" nằm ở Node A. Hàng triệu fan truy cập cùng lúc.
- Node A bị quá tải CPU/Network, trong khi Node B, C ngồi chơi.
- *Giải pháp:* Local Cache (L1) đè lên trên Distributed Cache (L2). Cache profile Justin Bieber ngay tại RAM của Web Server trong vài giây.

=== Triển khai & Lưu ý thực tế

1.  *Kết nối (Connection Pooling):*
    - Luôn dùng Pool (như HikariCP cho DB, JedisPool/Lettuce cho Redis).
    - Tạo kết nối TCP tốn kém (3-way handshake). Đừng tạo mới connection cho mỗi request.

2.  *Timeouts:*
    - Luôn đặt Connection Timeout và Read Timeout.
    - Nếu Redis treo, App phải fail-fast (lỗi nhanh) hoặc fallback, đừng treo mãi mãi chờ Redis.

3.  *Namespace:*
    - Đặt prefix cho các key để dễ quản lý. Ví dụ: `user:123:profile`, `product:456:price`.
    - Tránh xung đột key giữa các module khác nhau dùng chung 1 Redis.

4.  *Memory Policy:*
    - Cấu hình `maxmemory` cho Redis.
    - Chọn chính sách eviction: `allkeys-lru` (xóa key cũ nhất bất kỳ) hay `volatile-lru` (chỉ xóa key có TTL). Đừng để Redis bị OOM kill bởi OS.