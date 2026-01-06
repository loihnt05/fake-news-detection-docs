== Local Cache <local_cache>

=== Mô tả chi tiết

Local Cache là hình thức caching đơn giản và nhanh nhất, trong đó dữ liệu được lưu trữ trực tiếp trong bộ nhớ (RAM) của chính tiến trình (process) đang chạy ứng dụng.

- Nếu ứng dụng viết bằng Java, cache nằm trong Heap Memory (hoặc Off-Heap).
- Nếu là Node.js, nó nằm trong bộ nhớ V8 engine.
- Dữ liệu được truy xuất thông qua tham chiếu bộ nhớ (memory reference), không cần đi qua bất kỳ giao thức mạng nào.

*Cấu trúc dữ liệu:* Thường là một Hash Map (Key-Value) kèm theo các danh sách liên kết (Linked List) để quản lý thuật toán xóa (Eviction).

=== Các thư viện phổ biến

- *Java:*
    - *Guava Cache (Google):* Huyền thoại một thời.
    - *Caffeine:* Phiên bản hiện đại, hiệu năng cao hơn Guava, sử dụng thuật toán Window TinyLFU.
    - *Ehcache:* Hỗ trợ cả disk storage và tiering.
- *Go:* `go-cache`, `bigcache` (tối ưu để tránh GC overhead).
- *Python:* `functools.lru_cache`, `cachetools`.
- *Node.js:* `node-cache`, `lru-cache`.

=== Khi nào nên dùng?

Local Cache phù hợp nhất cho:
1.  *Dữ liệu bất biến (Immutable) hoặc rất ít thay đổi:* Cấu hình hệ thống, danh sách danh mục sản phẩm, whitelist IP.
2.  *Dữ liệu riêng tư của từng instance:* Ví dụ bộ đếm request rate-limit cục bộ.
3.  *Hệ thống nhỏ (Single Node):* Khi chỉ chạy 1 server, Local Cache là lựa chọn tối ưu vì không cần cài đặt Redis.
4.  *L1 Cache trong mô hình Multi-level Cache:* Dùng Local Cache làm tầng đệm trước khi gọi ra Redis (L2 Cache).

=== Ưu điểm

1.  *Tốc độ ánh sáng:*
    - Thời gian truy xuất chỉ tính bằng nano-giây (ns) hoặc micro-giây (µs).
    - Nhanh hơn Redis (mạng nội bộ) khoảng 100-1000 lần.
    - Không tốn chi phí Serialization/Deserialization (nếu lưu object trực tiếp).

2.  *Không phụ thuộc hạ tầng:*
    - Không cần cài đặt, vận hành thêm server Redis/Memcached.
    - Không lo đứt cáp mạng, timeout kết nối.

3.  *Chi phí vận hành bằng 0:* Tận dụng RAM dư thừa của Web Server.

=== Nhược điểm và Rủi ro

==== Vấn đề nhất quán dữ liệu
Đây là "tử huyệt" của Local Cache trong môi trường Distributed System (chạy nhiều server).
- *Kịch bản:* Hệ thống có 3 server A, B, C.
    1.  User 1 gửi request vào Server A -> A cache `product_1` giá 100\$.
    2.  User 2 gửi request vào Server B -> B cache `product_1` giá 100\$.
    3.  Admin cập nhật giá `product_1` thành 200\$. Request cập nhật rơi vào Server A.
    4.  Server A cập nhật cache của nó thành 200\$.
    5.  *Vấn đề:* Server B và Server C vẫn giữ giá 100\$ (stale data).
    6.  User truy cập vào B sẽ thấy giá cũ, truy cập vào A thấy giá mới. Trải nghiệm người dùng không đồng nhất.

*Giải pháp:*
- Đặt TTL (Time-To-Live) thật ngắn (ví dụ 1 phút). Chấp nhận sai lệch trong 1 phút.
- Sử dụng cơ chế Pub/Sub (Redis Pub/Sub hoặc Kafka): Khi A thay đổi dữ liệu, A bắn tin nhắn "Invalidate product_1". B và C lắng nghe tin nhắn và xóa cache của mình. (Phức tạp hóa hệ thống).

==== Vấn đề bộ nhớ
- Local Cache ăn vào RAM của ứng dụng.
- Nếu cache quá lớn -> Gây lỗi `OutOfMemoryError` (OOM).
- Với các ngôn ngữ có Garbage Collection (Java, Go, Node.js): Cache chứa quá nhiều object sống lâu (long-lived objects) sẽ gây áp lực lớn lên bộ dọn rác (GC), làm ứng dụng bị khựng (Stop-the-world pauses).

==== Vấn đề "Cold Start"
- Khi deploy phiên bản mới (restart server), Local Cache bị mất trắng.
- Server mới khởi động sẽ phải chịu tải lớn từ Database để làm nóng (warm-up) lại cache.
- Trong khi Distributed Cache (Redis) vẫn sống độc lập qua các lần deploy app.

=== Best Practices

1.  *Luôn luôn đặt giới hạn kích thước:*
    - Không bao giờ dùng `HashMap` thường để làm cache. Hãy dùng thư viện (như Caffeine) và cấu hình `maximumSize=10000`.
    - Tránh OOM crash.

2.  *Luôn luôn đặt TTL:*
    - Dữ liệu không bao giờ nên sống vĩnh viễn trong Local Cache. Hãy để nó tự chết sau 5-10 phút để đảm bảo eventual consistency.

3.  *Sử dụng Weak/Soft References (Java):*
    - Cho phép GC thu hồi bộ nhớ cache nếu hệ thống thiếu RAM, tránh crash app.

4.  *Giám sát:*
    - Expose các chỉ số: Hit rate, Eviction count, Heap usage.
    - Nếu Hit rate < 50% với Local Cache, có thể bạn đang lãng phí RAM vô ích.

5.  *Cân nhắc "Off-heap" caching:*
    - Với Java, sử dụng bộ nhớ ngoài Heap (trực tiếp từ OS) để tránh GC pause, nhưng đổi lại phải chịu chi phí serialization.

=== Ví dụ cấu hình

```java
Cache<String, User> cache = Caffeine.newBuilder()
    .initialCapacity(100)
    .maximumSize(1000) // Giới hạn 1000 phần tử
    .expireAfterWrite(10, TimeUnit.MINUTES) // Tự xóa sau 10p ghi
    .recordStats() // Bật thống kê
    .build();

// Sử dụng
User user = cache.get(userId, k -> database.findUser(k));
```
Mã trên đảm bảo an toàn bộ nhớ và tính tươi mới của dữ liệu một cách tự động.