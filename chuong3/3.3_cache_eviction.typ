== Cache Eviction <cache_eviction>

=== Tại sao phải Evict?

Bộ nhớ cache (RAM) là tài nguyên hữu hạn và đắt đỏ. Chúng ta không thể lưu trữ toàn bộ dữ liệu của Database vào Cache (trừ khi DB quá nhỏ).
Khi Cache đầy (Full Capacity), để nhường chỗ cho dữ liệu mới (New Item), hệ thống buộc phải chọn ra một hoặc nhiều dữ liệu cũ để xóa đi. Quá trình này gọi là *Eviction*.

Việc chọn "ai là người phải ra đi" ảnh hưởng trực tiếp đến Hit Rate. Nếu chọn sai (xóa dữ liệu sắp được dùng), Hit Rate giảm -> App chậm.

#figure(image("../images/pic7.jpg"), caption: [Cache Eviction Diagram])

=== Các thuật toán Eviction phổ biến

Các thuật toán này trả lời câu hỏi: *"Trong hàng triệu item, cái nào ít giá trị nhất hiện tại?"*

==== LRU
- *Nguyên lý:* Nếu một dữ liệu lâu rồi không ai sờ đến, khả năng cao trong tương lai gần cũng không ai cần nó.
- *Cài đặt:* Sử dụng `Doubly Linked List` kết hợp `HashMap`.
    - Khi truy cập item X: Bốc X từ vị trí hiện tại chuyển lên đầu danh sách (Most Recently Used).
    - Khi đầy: Cắt đuôi danh sách (Least Recently Used) vứt đi.
- *Ưu điểm:* Đơn giản, hiệu quả với hầu hết các workload thông thường (Recency bias).
- *Nhược điểm:* Bị đánh lừa bởi *Scans* (Quét toàn bộ). Nếu một tiến trình backup quét qua toàn bộ DB 1 lần, nó sẽ đẩy toàn bộ cache nóng (Hot data) ra ngoài và thay bằng dữ liệu rác chỉ dùng 1 lần.

==== LFU
- *Nguyên lý:* Dữ liệu nào được dùng nhiều lần (tần suất cao) thì nên được giữ lại, dù lâu rồi chưa dùng.
- *Cài đặt:* Mỗi item kèm theo một bộ đếm (Frequency Counter). Xóa item có counter thấp nhất.
- *Ưu điểm:* Chống lại Scans tốt hơn LRU. Giữ được dữ liệu hot bền vững.
- *Nhược điểm:*
    - Tốn bộ nhớ lưu counter.
    - *Aging Problem:* Một item trong quá khứ rất hot (counter = 1 triệu), nhưng giờ hết thời. Nó vẫn nằm lì trong cache mãi mãi vì counter quá cao, chiếm chỗ của item mới. Cần cơ chế "lão hóa" (giảm counter theo thời gian).

==== TinyLFU / W-TinyLFU
- Đây là thuật toán hiện đại (dùng trong Caffeine, Ristretto).
- Kết hợp ưu điểm của LRU và LFU.
- Dùng *Bloom Filter* (cụ thể là Count-Min Sketch) để đếm tần suất một cách siêu tiết kiệm bộ nhớ.
- Dùng cơ chế *Admission Policy:* Khi Cache đầy, Item mới muốn vào phải "thi đấu" với Item cũ (Candidate vs Victim). Nếu tần suất Item mới > Item cũ thì mới cho vào, không thì vứt Item mới đi luôn.
-> Đạt Hit Rate cao nhất hiện nay trong các benchmark.

==== FIFO & Random
- *FIFO:* Vào trước ra trước. Tồi tệ về hiệu năng hit rate. Ít dùng.
- *Random:* Xóa ngẫu nhiên.
    - *Bất ngờ:* Trong một số trường hợp, Random lại tốt ngang ngửa LRU mà cài đặt cực dễ, không tốn bộ nhớ meta-data, không cần lock danh sách liên kết.
    - Redis sử dụng một biến thể của Random (lấy ngẫu nhiên 5 mẫu, chọn cái cũ nhất trong 5 cái để xóa) để tránh tốn RAM quản lý Linked List.

==== TTL Based
- Không chờ đầy mới xóa. Xóa khi hết hạn.
- *Lazy Expiration:* Khi user get key, kiểm tra nếu hết hạn thì xóa và trả về null. (Redis dùng cách này).
- *Active Expiration:* Có một thread chạy ngầm, định kỳ random kiểm tra các key và xóa key hết hạn.

=== Các thảm họa và cách phòng chống

Khi làm việc với Cache Eviction và Expiration, có những kịch bản "ác mộng" sau:

==== Cache Stampede
- *Kịch bản:* Một Key cực hot (ví dụ: Trang chủ báo VnExpress, thông tin vé trận chung kết) có 10,000 request/giây. Đúng lúc 12:00:00, Key này hết hạn (Expire).
- *Hậu quả:*
    1.  Request 1 đến -> Miss -> Gọi DB.
    2.  Trong khi Request 1 chưa kịp ghi lại vào Cache, Request 2 đến 10,000 cũng Miss -> Gọi DB.
    3.  10,000 queries đập vào DB cùng lúc -> DB sập.
- *Giải pháp:*
    - *Mutex Locking:* Chỉ cho 1 luồng được build lại cache. Các luồng khác chờ hoặc trả về dữ liệu cũ.
    - *Logical Expiration:* Trong value cache lưu thêm field `expire_at`.
        - Value thực sự set TTL = vĩnh viễn (hoặc rất dài).
        - Khi App đọc, thấy `expire_at` đã qua -> Trả về dữ liệu cũ cho user (cho nhanh), đồng thời kích hoạt 1 thread ngầm đi update lại cache (Asynchronous Refresh).

==== Cache Avalanche
- *Kịch bản:* Bạn set cache cho 1 triệu sản phẩm cùng TTL = 60 phút. Bạn khởi động server lúc 8:00.
- *Hậu quả:* Đến 9:00, đồng loạt 1 triệu key hết hạn cùng lúc. Tải DB tăng dựng đứng từ 0 lên đỉnh.
- *Giải pháp:* *Jitter (Độ lệch ngẫu nhiên).*
    - Thay vì set TTL cứng 60 phút. Hãy set \$TTL = 60 + Random(-5, +5)\$ phút.
    - Các key sẽ hết hạn rải rác, tải DB sẽ đều hơn.

==== Stale Reads
- Trong mô hình Master-Slave của DB.
- App update Master (xóa cache). Master chưa kịp replicate sang Slave.
- Request khác Miss cache -> Đọc từ Slave -> Thấy dữ liệu cũ -> Ghi lại vào Cache.
- Kết quả: Cache lưu dữ liệu cũ vĩnh viễn cho đến khi hết TTL.
- *Giải pháp:* Dùng binlog của DB để invalidate cache (Write-behind pattern) có độ trễ, hoặc set TTL ngắn.

=== Best Practices tóm tắt

1.  *Luôn dùng Jitter cho TTL.*
2.  *Tách biệt Cache Hot và Cache Cold:* Cấu hình chính sách eviction khác nhau.
3.  *Monitor Eviction Rate:* Nếu thấy Redis liên tục evict key (non-TTL), có nghĩa là bạn thiếu RAM, hãy scale up hoặc giảm lượng dữ liệu cache.
4.  *Cẩn thận với Keys `KEYS *`:* Không bao giờ dùng lệnh này trong production để tìm key xóa, nó sẽ lock toàn bộ Redis. Dùng `SCAN`.