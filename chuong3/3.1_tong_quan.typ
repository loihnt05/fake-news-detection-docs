== Tổng quan về Caching <tong_quan_caching>

=== Khái niệm cốt lõi

Caching là kỹ thuật lưu trữ tạm thời các bản sao của dữ liệu ở một nơi có tốc độ truy xuất nhanh hơn (thường là RAM) so với nơi lưu trữ gốc (thường là ổ cứng HDD/SSD hoặc qua mạng).

Trong khoa học máy tính, Caching không chỉ là một công cụ, nó là một chiến lược tối ưu hóa dựa trên sự chênh lệch về tốc độ giữa các tầng lưu trữ phần cứng.

==== Bản chất vật lý: Memory Hierarchy

Để hiểu tại sao cần caching, ta phải nhìn vào các con số độ trễ (Latency Numbers Every Programmer Should Know):

- *L1 Cache:* ~0.5 ns
- *L2 Cache:* ~7 ns
- *Main Memory:* ~100 ns
- *SSD Random Read:* ~150,000 ns (150 µs)
- *Network Round-trip:* ~500,000 ns (0.5 ms)
- *Disk Seek:* ~10,000,000 ns (10 ms)
- *Internet Round-trip:* ~150,000,000 ns (150 ms)

*Nhận xét:*
Truy cập RAM nhanh gấp *1,500 lần* so với SSD và gấp *5,000 lần* so với mạng nội bộ. Nếu không có Caching, CPU sẽ dành 99% thời gian để "chờ" dữ liệu từ ổ cứng hoặc mạng, gây lãng phí tài nguyên tính toán khổng lồ.

==== Nguyên lý nền tảng: Locality of Reference

Caching hoạt động hiệu quả nhờ vào tính chất "cục bộ tham chiếu" của các chương trình máy tính:

1.  *Temporal Locality:*
    - Nếu một dữ liệu được truy cập ngay bây giờ, khả năng cao nó sẽ được truy cập lại trong tương lai gần.
    - *Ví dụ:* Một biến đếm trong vòng lặp `for`, hoặc trang chủ của một tờ báo vừa được đăng tải.

2.  *Spatial Locality:*
    - Nếu một dữ liệu được truy cập, khả năng cao các dữ liệu nằm *gần nó* (trong bộ nhớ) cũng sẽ được truy cập.
    - *Ví dụ:* Khi đọc phần tử `arr[i]`, CPU cache sẽ load luôn cả `arr[i+1]`, `arr[i+2]`... (Cache Line). Trong database, khi đọc một row, hệ thống thường load cả page chứa row đó.

=== Mục tiêu chính

Việc triển khai Caching trong hệ thống phân tán nhắm đến 4 mục tiêu lớn:

1.  *Giảm độ trễ:*
    - Trả kết quả cho người dùng trong vài mili-giây thay vì vài giây.
    - Tăng trải nghiệm người dùng (UX) và chỉ số chuyển đổi (Conversion Rate) trong thương mại điện tử.

2.  *Tăng thông lượng:*
    - Cùng một hạ tầng server, caching giúp phục vụ số lượng request lớn hơn gấp nhiều lần (do thời gian xử lý mỗi request giảm xuống).

3.  *Giảm tải cho Backend:*
    - Bảo vệ Database khỏi việc bị quá tải bởi các truy vấn lặp lại (Read-heavy workloads).
    - Giảm chi phí hạ tầng (cần ít CPU/RAM cho Database server hơn).

4.  *Giảm chi phí băng thông:*
    - Đặc biệt quan trọng với CDN. Cache dữ liệu gần người dùng giúp giảm lượng dữ liệu phải truyền tải qua đường trục (Backbone) đắt đỏ.

=== Các chỉ số quan trọng

Để đánh giá hiệu quả của hệ thống Cache, ta dùng các chỉ số sau:

==== Hit Rate
Tỷ lệ phần trăm request được phục vụ từ Cache.
$ "Hit Rate" = ("Số request tìm thấy trong Cache") / ("Tổng số request") * 100% $
- Một hệ thống cache tốt thường có Hit Rate > 80-90%.
- Nếu Hit Rate < 30%, cần xem xét lại chiến lược cache (có thể bạn đang cache sai dữ liệu hoặc dung lượng cache quá nhỏ).

==== Miss Rate
$ "Miss Rate" = 100% - "Hit Rate" $
Khi Miss xảy ra, hệ thống phải thực hiện *Penalty Round-trip*: Đọc từ Cache (thất bại) -> Đọc từ Database -> Ghi vào Cache -> Trả về. Việc này chậm hơn so với không có cache.

==== Cache Size & Eviction Rate
- Dung lượng bộ nhớ cache đang sử dụng.
- Tốc độ cache bị đầy và phải xóa bớt phần tử cũ (Eviction). Nếu Eviction Rate quá cao, chứng tỏ cache bị "thashing" (vào ra liên tục), cần tăng size hoặc đổi thuật toán.

=== Trade-offs

"There are only two hard things in Computer Science: cache invalidation and naming things." - Phil Karlton.

Sử dụng Cache không phải là miễn phí, nó đi kèm các cái giá phải trả:

1.  *Consistency:*
    - Đây là vấn đề lớn nhất. Dữ liệu trong Cache là bản sao, nên nó luôn có nguy cơ bị cũ (stale) so với dữ liệu gốc trong Database.
    - *Ví dụ:* Người dùng đổi mật khẩu, nhưng Cache vẫn lưu mật khẩu cũ.
    - *Giải pháp:* Phải chấp nhận Eventual Consistency hoặc thiết kế cơ chế Invalidation phức tạp.

2.  *Complexity:*
    - Code logic trở nên phức tạp hơn: Phải xử lý logic "Check Cache -> If Miss -> Load DB -> Set Cache".
    - Phải xử lý các trường hợp lỗi: Cache sập, Cache timeout.

3.  *Availability Risk:*
    - Nếu hệ thống quá phụ thuộc vào Cache (Hit Rate 99%), khi Cache bị sập, toàn bộ tải sẽ dồn thẳng xuống Database (thảm họa Cache Avalanche), có thể làm sập luôn cả Database.

4.  *Cost:*
    - RAM đắt hơn nhiều so với SSD. Lưu trữ 1TB dữ liệu trên Redis tốn kém hơn nhiều so với lưu trên PostgreSQL.

=== Phân loại dữ liệu để Cache

Không phải dữ liệu nào cũng nên cache. Chiến lược tốt là phân loại:

- *Static Data:* (Ảnh, CSS, JS) -> Cache vĩnh viễn, dùng CDN.
- *Reference Data:* (Danh sách quốc gia, cấu hình hệ thống) -> Ít thay đổi, đọc nhiều -> Cache cục bộ (Local Cache) với TTL dài.
- *Transactional Data:* (Số dư tài khoản, trạng thái đơn hàng) -> Thay đổi liên tục -> Cần cân nhắc kỹ, thường chỉ cache trong thời gian cực ngắn hoặc không cache.
- *User Session:* -> Cache trên Distributed Cache (Redis) để hỗ trợ scale out.