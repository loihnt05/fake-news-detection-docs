== Khuyết điểm của Microservice <disadvantages>

Microservices không phải là "viên đạn bạc" (Silver Bullet). Nó giải quyết các vấn đề của Monolith nhưng lại sinh ra một loạt các vấn đề mới, thậm chí còn đau đầu hơn.

=== Complexity vận hành
Đây là cái giá đắt nhất.
- Trong Monolith, bạn chỉ cần quản lý 1 Application Server và 1 Database.
- Trong Microservices, bạn phải quản lý hàng chục, hàng trăm service, database, message broker, service registry, config server.
- Việc deploy một tính năng mới có thể liên quan đến việc phối hợp deploy 5 services cùng lúc theo đúng thứ tự.
- *Yêu cầu:* Bắt buộc phải có DevOps xịn, hệ thống CI/CD tự động hóa cao, Container Orchestration (Kubernetes). Nếu không có những thứ này, Microservices là thảm họa.

=== Phân tán → Mạng, Latency, Partial Failures
Chúng ta rơi vào "Các lầm tưởng về tính toán phân tán" (Fallacies of Distributed Computing):
- *Lầm tưởng:* Mạng là đáng tin cậy. *Thực tế:* Packet loss, timeout xảy ra cơm bữa.
- *Lầm tưởng:* Độ trễ bằng 0. *Thực tế:* Gọi hàm local mất 10ns, gọi RPC mất 1ms -> Chậm hơn 100.000 lần.
- *Partial Failure:* Trong Monolith, nếu OS chết, toàn bộ app chết (Total failure). Trong Microservices, Order Service sống nhưng Payment Service chết -> Hệ thống ở trạng thái "Zombies" (sống dở chết dở). Xử lý partial failure cực khó.

=== Khó Debug & Test
- *Debug:* Một bug xuất hiện. Nó không nằm ở code của bạn, mà do dữ liệu sai từ Service B, mà Service B lại nhận dữ liệu từ Service C. Việc lần mò qua 3 service để tìm nguyên nhân gốc (Root Cause) là cơn ác mộng nếu không có Distributed Tracing.
- *Test:* Unit Test thì dễ. Nhưng Integration Test và End-to-End Test là cực hình. Để test luồng "Đặt hàng", bạn phải dựng (mock) cả hệ thống gồm 10 services lên. Môi trường test trở nên cồng kềnh và không ổn định (Flaky tests).

=== Consistency và Giao dịch phân tán
- Monolith: `BEGIN TX` -> Update Bảng A, Update Bảng B -> `COMMIT`. An toàn tuyệt đối (ACID).
- Microservices: Update DB A thành công, gọi API sang Service B để update DB B thì bị lỗi mạng.
  - Lúc này DB A đã commit, DB B chưa làm gì. Dữ liệu bị sai lệch (Inconsistent).
  - Phải dùng *SAGA Pattern* để rollback (Compensating transaction). Nhưng viết code SAGA phức tạp gấp 10 lần code transaction thông thường.
  - Thường phải chấp nhận *Eventual Consistency* (Nhất quán cuối cùng), điều này gây khó khăn cho logic nghiệp vụ (ví dụ: kiểm tra tồn kho chính xác).

=== Overhead tài nguyên & Chi phí
- *Tài nguyên:* 1 app Monolith chạy tốn 2GB RAM. Chia thành 10 Microservices Java, mỗi cái tốn 500MB RAM (JVM overhead) -> Tổng 5GB RAM. Tốn tài nguyên hơn để chạy cùng một lượng logic.
- *Chi phí mạng:* Traffic nội bộ tăng vọt. Serialization/Deserialization tốn CPU.
- *Chi phí nhân sự:* Cần nhiều kỹ sư giỏi hơn để vận hành.

=== Phiên bản hóa API & Backward Compatibility
- Khi Service A đổi API, Service B, C, D đang gọi A sẽ bị lỗi.
- Phải duy trì nhiều phiên bản API song song (`/v1/orders`, `/v2/orders`) cho đến khi tất cả clients nâng cấp xong. Quản lý vòng đời API (API Lifecycle) trở thành gánh nặng.

=== Yêu cầu tổ chức & Kỹ năng
- Microservices đòi hỏi thay đổi cơ cấu tổ chức (Conway's Law).
- Nếu văn hóa công ty là "Command & Control" (Sếp bảo gì làm nấy, các team không được tự quyết), Microservices sẽ thất bại.
- Đòi hỏi kỹ năng của lập trình viên cao hơn: Phải hiểu về HTTP, Async, Caching, Resilience, Monitoring.

=== Bảo mật
- Monolith: Chỉ cần bảo vệ 1 cổng vào.
- Microservices: Hàng trăm service giao tiếp với nhau. Kẻ tấn công có thể xâm nhập vào 1 service yếu nhất rồi từ đó tấn công ngang (Lateral movement) sang các service khác.
- Phải bảo mật giao tiếp nội bộ (mTLS), quản lý secrets phức tạp (Vault).

=== Duplicated Logic & Dữ liệu
- Để đảm bảo tính độc lập (Decoupling), đôi khi ta chấp nhận lặp code.
  - Ví dụ: Logic `ValidateEmail` có thể bị copy-paste ở User Service và Order Service.
  - Dữ liệu `User` có thể được lưu chính ở User Service, nhưng lại được cache một phần ở Order Service (để join nhanh). Khi User đổi tên, phải lo đi update ở tất cả các nơi (Data synchronization).

== Kết luận
Microservices là một sự đánh đổi lớn:
- Bạn đổi *sự phức tạp trong Code* (Spaghetti code của Monolith) lấy *sự phức tạp trong Vận hành* (Distributed System Hell).
- Hãy chắc chắn rằng bạn có đủ lý do chính đáng và đủ năng lực để trả cái giá đó.