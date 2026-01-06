== Fault Tolerance <fault_tolerance>

=== Bản chất của Lỗi trong Hệ thống phân tán

Trong lập trình truyền thống (single-threaded, single-machine), lỗi là ngoại lệ (exception) và thường dẫn đến việc chương trình dừng lại. Nhưng trong hệ thống phân tán quy mô lớn, *lỗi là điều bình thường (norm)*.
- Với 10 server, xác suất 1 server chết mỗi ngày là thấp.
- Với 10,000 server, xác suất 1 server chết mỗi ngày là gần như 100%. Luôn luôn có một cái gì đó đang hỏng ở đâu đó.

Khả năng chịu lỗi (Fault Tolerance) là khả năng hệ thống tiếp tục vận hành đúng chức năng (có thể ở mức hiệu năng thấp hơn) khi một hoặc nhiều thành phần của nó bị lỗi. Mục tiêu không phải là ngăn chặn lỗi (vì không thể), mà là ngăn chặn lỗi lan rộng (containment) và tự khôi phục (recovery).

=== Các mô hình lỗi

Để thiết kế hệ thống chịu lỗi, ta cần hiểu "kẻ thù" là ai. Các nhà khoa học máy tính phân loại lỗi thành các mô hình:

1.  *Crash Failure:* Process dừng hoạt động đột ngột và im lặng hoàn toàn. Đây là loại lỗi "dễ chịu" nhất vì ta biết chắc nó đã chết.
2.  *Omission Failure:* Process bỏ sót không gửi hoặc không nhận được tin nhắn (do lỗi buffer, lỗi mạng).
3.  *Timing Failure:* Process phản hồi đúng nhưng quá chậm (timeout), vi phạm ràng buộc thời gian thực. Trong hệ thống đồng bộ, chậm coi như là lỗi.
4.  *Response Failure:* Process trả về giá trị sai (logic bug).
5.  *Byzantine Failure:* (Sẽ nói kỹ ở phần 1.2.4.2) Process hoạt động tàn độc, chủ ý lừa đảo hoặc bị hack.

=== Các chiến lược phát hiện lỗi

Làm sao biết một server đã chết?
- *Ping / Heartbeat:* Các node gửi tín hiệu "I'm alive" định kỳ (ví dụ mỗi giây) cho node giám sát. Nếu quá thời gian (timeout) mà không nhận được heartbeat -> coi như đã chết.
- *Lease (Hợp đồng thuê):* Node nhận được quyền làm chủ (leader) trong 10 giây. Sau 10 giây nếu không gia hạn (renew lease), quyền làm chủ tự động mất. Tránh trường hợp Leader chết mà vẫn giữ lock.
- *Phi Accrual Failure Detector:* Thay vì phán quyết nhị phân (sống/chết), nó tính ra *xác suất* server bị chết dựa trên lịch sử phản hồi. Giúp giảm thiểu báo động giả (false positives) khi mạng chập chờn.

=== Các mẫu thiết kế chịu lỗi

Đây là các pattern kinh điển được áp dụng trong Microservices (ví dụ qua thư viện Hystrix, Resilience4j):

==== Circuit Breaker
Bảo vệ hệ thống khỏi việc gọi liên tục vào một service đã chết.
- *Trạng thái Closed (Đóng):* Dòng điện (request) đi qua bình thường. Nếu lỗi ít -> OK.
- *Trạng thái Open (Mở):* Nếu lỗi vượt ngưỡng (ví dụ 50% request fail), cầu dao bật mở. Ngắt toàn bộ request ngay lập tức (Fail fast), không gọi sang service lỗi nữa để tránh treo hệ thống gọi.
- *Trạng thái Half-Open (Nửa mở):* Sau một khoảng thời gian, cho phép vài request đi qua để thăm dò ("thả thính"). Nếu thành công -> Đóng cầu dao lại. Nếu vẫn lỗi -> Mở lại.

==== Bulkhead
Ngăn chặn lỗi lan truyền (Cascading Failures).
- Ý tưởng lấy từ thiết kế tàu thủy: Chia khoang tàu thành nhiều vách ngăn kín nước. Nếu một khoang thủng, nước chỉ tràn vào khoang đó, tàu không chìm.
- Trong phần mềm: Chia Thread Pool hoặc Connection Pool riêng cho từng service.
- *Ví dụ:* Service A gọi Service B và Service C. Nếu Service B chết và làm treo các thread gọi nó, việc này không được làm ảnh hưởng đến các thread đang gọi Service C. Nếu dùng chung một Thread Pool khổng lồ, B chết sẽ kéo theo C chết (do hết sạch thread).

==== Retry with Exponential Backoff
Khi gọi lỗi, đừng retry ngay lập tức liên tục (sẽ làm DDOS chính hệ thống mình). Hãy chờ và thử lại.
- Lần 1: Chờ 1s -> Retry.
- Lần 2: Chờ 2s -> Retry.
- Lần 3: Chờ 4s -> Retry.
- Lần 4: Chờ 8s -> Retry.
- Kèm theo *Jitter* (độ lệch ngẫu nhiên) để tránh việc hàng nghìn client cùng retry vào đúng một thời điểm (Thundering Herd).

==== Fallback
Khi mọi nỗ lực đều thất bại (Circuit Breaker mở, Retry hết lượt), hãy trả về một giá trị mặc định an toàn.
- Ví dụ: Dịch vụ "Gợi ý phim" bị chết. Fallback: Trả về danh sách "Top 10 phim kinh điển" (được hardcode hoặc lấy từ cache) thay vì báo lỗi "Internal Server Error".

=== Redundancy & Replication

Đây là cốt lõi của Fault Tolerance (đã nhắc ở phần Availability nhưng đi sâu hơn ở góc độ chịu lỗi).

- *Active-Passive Replication:* Đơn giản nhưng lãng phí. Thời gian khôi phục (MTTR) phụ thuộc vào tốc độ promote Slave lên Master.
- *Active-Active Replication:* Phức tạp xử lý conflict.
- *Erasure Coding:* Thay vì sao chép dữ liệu nguyên bản (x3 dung lượng), ta chia dữ liệu thành các mảnh và mã hóa thêm các mảnh chẵn lẻ (parity). Ví dụ: Chia file thành 4 phần, tạo thêm 2 phần parity (Tổng 6 phần). Chỉ cần còn 4 phần bất kỳ là khôi phục được file gốc. Tiết kiệm dung lượng lưu trữ hơn Replication nhưng tốn CPU tính toán hơn. Thường dùng trong các hệ thống lưu trữ object như S3, HDFS.

=== Kết luận
Fault Tolerance không phải là làm cho hệ thống không bao giờ lỗi.
Fault Tolerance là nghệ thuật *"Fail Gracefully"* (Thất bại một cách duyên dáng).
Hệ thống tốt là hệ thống:
1.  Người dùng không nhận ra nó bị lỗi.
2.  Nếu nhận ra, họ vẫn dùng được các tính năng cơ bản.
3.  Hệ thống tự động hồi phục mà không cần kỹ sư thức dậy lúc 3 giờ sáng.