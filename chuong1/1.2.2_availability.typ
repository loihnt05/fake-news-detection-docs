== Availability <availability>

=== Định nghĩa và Tầm quan trọng

Tính sẵn sàng (Availability) không chỉ đơn thuần là việc hệ thống "còn sống" hay không. Trong kỹ thuật phần mềm hiện đại, nó được định nghĩa là xác suất mà một hệ thống hoạt động đúng chức năng và có thể truy cập được tại một thời điểm bất kỳ khi được yêu cầu.

Đối với các doanh nghiệp số, Availability ảnh hưởng trực tiếp đến doanh thu và uy tín.
- Một trang thương mại điện tử như Amazon nếu sập trong 1 phút vào ngày Prime Day có thể mất hàng triệu đô la.
- Một hệ thống giao dịch chứng khoán nếu downtime trong phiên giao dịch có thể gây ra hỗn loạn thị trường và kiện tụng pháp lý.
- Một ứng dụng gọi xe nếu không book được xe, khách hàng sẽ chuyển ngay sang ứng dụng đối thủ chỉ trong 30 giây.

=== Các chỉ số đo lường (Metrics)

Để quản lý tính sẵn sàng, chúng ta cần lượng hóa nó qua các con số cụ thể, thường được quy định trong *SLA*.

==== Công thức tính toán
Availability thường được tính dựa trên thời gian hoạt động (Uptime) và thời gian chết (Downtime):

\$ A = (Uptime) / (Uptime + Downtime) \* 100% \$

Hoặc dựa trên thời gian trung bình giữa các lỗi (MTBF - Mean Time Between Failures) và thời gian trung bình để khôi phục (MTTR - Mean Time To Recovery):

\$ A = (MTBF) / (MTBF + MTTR) \$

Điều này cho thấy, để tăng Availability, ta có hai cách:
1.  *Tăng MTBF:* Làm cho hệ thống ít lỗi hơn (Code tốt hơn, phần cứng xịn hơn).
2.  *Giảm MTTR:* Sửa lỗi nhanh hơn khi nó xảy ra (Monitoring tốt, quy trình rollback tự động). *Cách này thường hiệu quả và rẻ hơn cách 1.*

==== Bảng quy đổi "Các con số 9" (The Nines)

#table(
  columns: (1fr, 1fr, 1fr),
  inset: 10pt,
  align: horizon,
  table.header(
    [*Mức độ (Availability)*], [*Downtime / Năm*], [*Downtime / Tháng*]
  ),
  [99% (2 nines)], [3 ngày 15 giờ], [7.2 giờ],
  [99.9% (3 nines)], [8.76 giờ], [43.8 phút],
  [99.95% (3.5 nines)], [4.38 giờ], [21.9 phút],
  [99.99% (4 nines)], [52.56 phút], [4.38 phút],
  [99.999% (5 nines)], [5.26 phút], [26 giây]
)

- *99%:* Website cá nhân, blog, hệ thống nội bộ không quan trọng.
- *99.9%:* Tiêu chuẩn cho hầu hết các dịch vụ SaaS, Web App thương mại.
- *99.99%:* Yêu cầu cho các hệ thống thanh toán, cổng API quan trọng. Đòi hỏi kiến trúc dự phòng cao.
- *99.999%:* "Five Nines". Tiêu chuẩn viễn thông (Telco), hệ thống kiểm soát không lưu, y tế. Đạt được mức này cực khó, đòi hỏi tự động hóa hoàn toàn việc khôi phục lỗi.

==== Phân biệt SLA, SLO, SLI
- *SLI (Service Level Indicator):* Chỉ số đo lường thực tế (Ví dụ: latency trung bình đo được là 150ms).
- *SLO (Service Level Objective):* Mục tiêu nội bộ (Ví dụ: 99.9% requests phải < 200ms).
- *SLA (Service Level Agreement):* Cam kết với khách hàng, kèm hình phạt (Ví dụ: Nếu uptime < 99.9%, chúng tôi sẽ đền bù 30% phí dịch vụ tháng đó).

=== Các kiến trúc đảm bảo tính sẵn sàng (HA Architectures)

Nguyên tắc vàng của High Availability là *Redundancy (Dư thừa)*. Không được có điểm chết duy nhất (No Single Point of Failure).

==== Active-Passive
- *Mô tả:* Có 2 node. Node A (Active) xử lý toàn bộ traffic. Node B (Passive) ở chế độ chờ (standby), liên tục nhận sao chép dữ liệu từ A (heartbeat replication).
- *Cơ chế Failover:* Khi A chết, hệ thống giám sát phát hiện và chuyển IP/DNS sang B. B trở thành Active.
- *Ưu điểm:* Dễ triển khai, đảm bảo nhất quán dữ liệu tốt hơn Active-Active.
- *Nhược điểm:* Lãng phí tài nguyên (Node B ngồi chơi). Thời gian failover có thể mất vài giây đến vài phút (downtime ngắn).

==== Active-Active
- *Mô tả:* Cả 2 node A và B đều xử lý traffic đồng thời. Thường có Load Balancer chia tải (50/50 hoặc Round Robin).
- *Ưu điểm:* Tận dụng tối đa tài nguyên phần cứng. Nếu một node chết, node kia gánh tải ngay lập tức (không có downtime chuyển đổi).
- *Nhược điểm:* Phức tạp cực kỳ. Phải xử lý xung đột dữ liệu (data conflict) khi cả 2 node cùng ghi vào một bản ghi database. Cần kỹ thuật đồng bộ hai chiều (bi-directional replication).
- *Rủi ro:* "Thundering Herd Problem" - Nếu A chết, toàn bộ 100% tải dồn sang B. Nếu B không đủ khỏe để gánh 100% tải, B cũng chết theo -> Sập toàn hệ thống.

==== N+1 và N+M Redundancy
- *N+1:* Cần N server để chạy, mua thêm 1 server dự phòng. (Ví dụ: Cần 10 server, chạy 11 cái). Tiết kiệm hơn Active-Passive (1+1).
- *N+M:* Cần N server, mua thêm M server dự phòng. Tăng độ an toàn hơn.

==== Geographic Redundancy
- *Mô tả:* Triển khai hệ thống trên nhiều Data Center (DC) hoặc nhiều Region khác nhau (Ví dụ: US-East và US-West).
- *Mục đích:* Chống lại thảm họa thiên nhiên (động đất, lũ lụt, cắt cáp quang biển) làm sập hoàn toàn một khu vực.
- *Thách thức:* Độ trễ đồng bộ dữ liệu giữa các châu lục là rất lớn (vài trăm ms), ảnh hưởng đến Consistency.

=== Chiến lược đối phó với sự cố

Để duy trì Availability cao, ngoài kiến trúc, cần có chiến lược vận hành:

1.  *Graceful Degradation:* Khi hệ thống quá tải hoặc một phần bị lỗi, đừng sập hoàn toàn. Hãy tắt bớt tính năng phụ.
    - Ví dụ: Facebook bị lỗi database load ảnh -> Vẫn cho user chat text, chỉ ẩn ảnh đi thay vì báo lỗi 500 toàn trang.
2.  *Rate Limiting & Throttling:* Từ chối bớt yêu cầu nếu vượt quá ngưỡng chịu đựng để bảo vệ server cho những người dùng còn lại.
3.  *Circuit Breaker:* Nếu Service A gọi Service B mà B bị lỗi liên tục, A nên tự động ngắt kết nối đến B ngay lập tức để tránh chờ đợi (timeout) gây treo hệ thống A. Sau một thời gian, A thử kết nối lại.

=== Kết luận
Availability là một tính năng đắt đỏ. Từ 99% lên 99.9% chi phí có thể tăng gấp đôi. Từ 99.99% lên 99.999% chi phí có thể tăng gấp 10 lần. Kỹ sư cần cân nhắc bài toán kinh tế để chọn mức Availability phù hợp nhất.