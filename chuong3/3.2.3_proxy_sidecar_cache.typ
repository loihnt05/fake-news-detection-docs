== Network-Level Caching Patterns <network_caching>

Ngoài Local Cache (Application Layer) và Distributed Cache (Data Layer), chúng ta còn có thể cache dữ liệu ngay trên đường truyền mạng. Đây là lớp phòng thủ đầu tiên và hiệu quả nhất để giảm tải cho toàn bộ hệ thống backend.

=== Reverse Proxy Cache

==== Mô tả
Reverse Proxy Cache (như Nginx, Varnish, Squid) đứng chắn trước các Web Server. Nó chặn các HTTP Request từ client.
- Nếu nó có bản sao response hợp lệ (fresh) trong bộ nhớ hoặc ổ cứng -> Trả về ngay lập tức (Cache Hit).
- Nếu không -> Chuyển request xuống Backend -> Nhận response -> Lưu vào cache -> Trả cho Client.

Đây chính là nguyên lý hoạt động của CDN (Content Delivery Network).

==== Khi nào dùng?
- *Static Content:* Ảnh, CSS, JS, Video. Đây là trường hợp sử dụng kinh điển (hit rate > 95%).
- *Public API:* Các API trả về dữ liệu ít thay đổi và giống nhau cho mọi user (ví dụ: Danh sách tỉnh thành, Tin tức trang chủ).
- *Hệ thống CMS:* WordPress, Drupal hưởng lợi rất lớn từ lớp cache này (FastCGI Cache).

==== Kỹ thuật quan trọng: HTTP Caching Headers
Reverse Proxy hoạt động dựa trên các tiêu chuẩn HTTP RFC. Backend điều khiển hành vi của Proxy thông qua Headers:

- `Cache-Control: public, max-age=3600`: "Hãy cache cái này 1 tiếng, ai cũng xem được".
- `Cache-Control: private`: "Chỉ cache trên trình duyệt người dùng, đừng cache ở Proxy chung" (dùng cho thông tin cá nhân).
- `Vary: User-Agent`: "Hãy lưu bản cache riêng cho Mobile và Desktop".
- `ETag / If-None-Match`: Cơ chế xác thực lại (Revalidation). Proxy hỏi Server: "File này có đổi gì không?". Server trả lời `304 Not Modified` (không tốn băng thông gửi body).

==== Ưu/Nhược điểm
- *Ưu:* Giảm tải khủng khiếp cho backend. Xử lý hàng chục nghìn request/giây dễ dàng. Ẩn topology hệ thống.
- *Nhược:* Khó invalidate (xóa) cache một cách tức thì. Thường phải chờ TTL hết hạn hoặc dùng lệnh PURGE chuyên biệt. Không phù hợp cho dữ liệu cá nhân hóa cao.

---

=== Sidecar Cache

==== Mô tả
Trong kiến trúc Microservices và Container (Kubernetes), Sidecar Cache là một container phụ chạy song song cùng pod với container ứng dụng chính (share network namespace).
- Thay vì App gọi ra Redis trung tâm qua mạng, App gọi vào Sidecar (localhost).
- Sidecar (thường là Envoy, proxy chuyên dụng) sẽ lo việc caching, hoặc định tuyến đến Redis.

==== Mô hình triển khai
Mỗi Pod có một cache riêng (Local) nhưng được quản lý bởi một process bên ngoài (Sidecar) thay vì thư viện trong code.
- *Ví dụ:* Ứng dụng Python dùng Envoy làm sidecar. App gọi `GET localhost:9090/user/1`. Envoy kiểm tra cache của nó. Nếu có trả về. Nếu không, Envoy gọi sang User Service thật.

==== Ưu điểm
- *Đa ngôn ngữ (Polyglot):* Team Java, Go, Nodejs không cần viết lại logic caching. Chỉ cần cấu hình Sidecar.
- *Trong suốt (Transparency):* Ứng dụng không biết caching đang tồn tại. Code đơn giản hơn.
- *Quản trị tập trung:* Cấu hình chính sách cache qua Control Plane (như Istio).

==== Nhược điểm
- Tốn tài nguyên: Mỗi pod thêm 1 container phụ -> Tốn thêm RAM/CPU của Cluster.
- Độ trễ: Thêm 1 hop (nhảy) qua localhost (tuy nhiên rất nhỏ, micro-seconds).

---

=== Reverse Proxy Sidecar Cache

Đây là sự kết hợp nâng cao, thường thấy trong *Service Mesh* (như Istio, Linkerd).

==== Mô tả
Sidecar proxy (Envoy) không chỉ làm nhiệm vụ định tuyến (routing) mà còn đóng vai trò như một Distributed Cache Proxy.
- App A gọi App B.
- Request đi qua Sidecar A (Egress Proxy).
- Sidecar A có thể cache response từ B.
- Lần sau App A gọi B, Sidecar A trả về ngay lập tức.

==== Phối hợp nhiều tầng

Một hệ thống lớn sẽ có nhiều tầng cache lồng nhau (Cache Sandwich). Cần cẩn trọng để tránh "Stale Data Hell" (Dữ liệu cũ không thể xóa).

*Chiến lược đề xuất:*

1.  *Browser Cache:* `max-age` ngắn hoặc dùng ETag.
2.  *CDN/Edge Cache:* Cache static assets (ảnh, js) lâu dài. Dùng versioning file name (`style.v1.css`) để bust cache.
3.  *Reverse Proxy (Gateway):* Cache các API public ngắn hạn (5-10s) để chống DDOS/Micro-bursts.
4.  *Service Cache (Redis):* Cache dữ liệu nghiệp vụ, TTL tùy chỉnh.
5.  *Local Cache (App):* Cache cấu hình, immutable data.

*Nguyên tắc vàng:* *"Càng gần Database, TTL càng dài. Càng gần User, TTL càng ngắn."*
- Lý do: Cache ở Browser (gần User nhất) rất khó xóa (phải chờ user reload). Cache ở Redis (gần DB) dễ xóa chủ động bởi App.

==== Kỹ thuật ESI
Cho phép cache từng phần (fragments) của trang web.
- Trang chủ có: Header (tĩnh), Footer (tĩnh), News (động), UserInfo (cá nhân).
- Reverse Proxy sẽ cache Header/Footer. Khi request đến, nó lấy Header từ cache, Footer từ cache, rồi chỉ gọi Backend lấy News/UserInfo, sau đó ghép lại trả cho user.
- Tối ưu hóa cực cao cho các trang báo chí, thương mại điện tử.