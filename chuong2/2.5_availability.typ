== Load Balancer giúp tăng Availability của hệ thống <availability_increase>

Tính sẵn sàng (Availability) là thước đo quan trọng nhất của một hệ thống online. Load Balancer (LB) không chỉ là công cụ chia tải, mà còn là "người bảo vệ" giúp hệ thống sống sót qua các sự cố và bảo trì. Dưới đây là các cơ chế chi tiết.

=== Loại bỏ điểm chết duy nhất

Trong mô hình không có LB, Client kết nối trực tiếp đến Server.
- Nếu Server chết -> Client lỗi -> Availability = 0%.

Với LB:
- Client kết nối đến LB. LB kết nối đến một cụm (Cluster) gồm N Server.
- Nếu 1 Server chết -> LB điều hướng sang N-1 Server còn lại.
- Hệ thống vẫn hoạt động bình thường.
-> LB biến sự cố "chết server" từ một thảm họa thành một sự kiện vận hành bình thường.

=== Health Checks

Health Check là trái tim của khả năng phục hồi. LB liên tục "bắt mạch" các server backend để biết ai còn sống, ai đã chết.

==== Active Health Check
LB định kỳ gửi request giả lập đến server (ví dụ mỗi 5 giây).
- *TCP Check:* Thử mở kết nối đến port 80. Nếu kết nối thành công (SYN-ACK) -> Sống. Nếu Time-out hoặc Connection Refused -> Chết. (Nhanh, nhẹ, nhưng không đảm bảo App chạy đúng, chỉ biết OS còn sống).
- *HTTP Check:* Gửi `GET /health` đến server. Nếu nhận HTTP 200 OK -> Sống. Nếu nhận 500 hoặc 404 -> Chết. (Chính xác hơn, kiểm tra được cả logic database, cache connection).

==== Passive Health Check
LB quan sát các traffic thực tế của người dùng.
- Nếu LB gửi request của user A vào server X và bị lỗi (timeout hoặc 5xx), LB sẽ ghi nhận "Server X đang có vấn đề".
- Nếu số lần lỗi vượt ngưỡng (Failure Threshold), LB tạm ngắt server X.
-> Ưu điểm: Không tạo thêm traffic rác. Phát hiện lỗi mà Active Check có thể bỏ sót (ví dụ Active Check OK nhưng traffic thật bị lỗi do tải cao).

=== Failover tự động

Quy trình tự động cách ly lỗi:
1.  *Detection:* Health Check phát hiện Server A không phản hồi 3 lần liên tiếp (Unhealthy Threshold).
2.  *Removal:* LB đánh dấu Server A là "Down" và xóa nó khỏi danh sách định tuyến. Không request mới nào được gửi vào A nữa.
3.  *Recovery:* LB vẫn âm thầm gửi Health Check vào A. Kỹ sư khởi động lại Server A.
4.  *Rejoining:* Khi A trả lời Health Check thành công 2 lần liên tiếp (Healthy Threshold), LB đánh dấu A là "Up" và bắt đầu chia tải lại cho A.

Toàn bộ quá trình diễn ra trong vài giây và hoàn toàn trong suốt với người dùng cuối.

=== Rolling Update & Blue-Green Deployment

Làm sao để cập nhật phiên bản phần mềm mới (Deploy code) mà không cần dừng hệ thống (Zero Downtime)? LB là chìa khóa.

==== Rolling Update
Giả sử có 10 server.
1.  LB ngắt kết nối Server 1 (Draining).
2.  Update code mới cho Server 1.
3.  Đưa Server 1 trở lại LB.
4.  Lặp lại với Server 2, 3... cho đến hết.
-> Tại mọi thời điểm, luôn có 9 server phục vụ khách. Hệ thống không bao giờ chết.

==== Blue-Green Deployment
1.  *Blue Environment:* Cụm server hiện tại (Version 1) đang chạy live.
2.  *Green Environment:* Dựng một cụm server mới hoàn toàn (Version 2) song song.
3.  Test kỹ trên Green.
4.  *Switch:* Trên LB, đổi cấu hình để trỏ toàn bộ traffic từ Blue sang Green.
-> Chuyển đổi tức thì. Nếu Green bị lỗi, chỉ cần switch ngược lại Blue (Rollback) trong 1 giây. An toàn tuyệt đối.

==== Canary Deployment
Thử nghiệm phiên bản mới trên một nhóm nhỏ người dùng.
1.  LB cấu hình: 95% traffic vào Version cũ, 5% traffic vào Version mới.
2.  Theo dõi log/monitoring của 5% đó.
3.  Nếu ổn, tăng dần lên 10%, 50%, 100%.
4.  Nếu lỗi, quay về 0% ngay.
-> Giảm thiểu rủi ro ảnh hưởng diện rộng.

=== Geo-distribution & Disaster Recovery

Trong mô hình GSLB (Global Server Load Balancing):
- Nếu Data Center (DC) Hà Nội bị mất điện toàn phần.
- GSLB (thường là DNS LB) phát hiện toàn bộ IP ở Hà Nội không ping được.
- GSLB tự động đổi DNS record, trỏ người dùng sang DC Hồ Chí Minh.
-> Hệ thống vẫn Available dù mất cả một trung tâm dữ liệu.

=== Kết hợp Caching & CDN

Load Balancer hiện đại (như Nginx, Varnish) thường tích hợp khả năng Caching.
- LB lưu trữ các file tĩnh (ảnh, css, js) hoặc thậm chí kết quả API (nếu ít thay đổi) vào RAM.
- Request tới -> LB trả về ngay từ RAM, không cần gọi vào Backend Server.
-> Giảm tải cho Backend, tăng tốc độ phản hồi, và quan trọng nhất: *Server Backend chết thì LB vẫn trả về nội dung cache được*. Giúp hệ thống "sống dai" hơn (Graceful Degradation).

=== Ví dụ thực tế: Sự cố Black Friday

Một trang thương mại điện tử lớn dự kiến traffic tăng gấp 10 lần vào Black Friday.
- *Trước giờ G:* Đội kỹ thuật dùng Auto Scaling Group (ASG) kết hợp với LB. Cấu hình: "Nếu CPU > 60%, tự động bật thêm server và add vào LB".
- *Giờ G:* Traffic ùa vào. CPU tăng vọt.
- *Hệ thống tự động:* ASG bật thêm 50 server mới trong 5 phút. LB tự động nhận diện 50 server mới và chia tải đều.
- *Kết quả:* Website vẫn mượt mà. Không có LB, 10 server cũ đã sập ngay phút đầu tiên.