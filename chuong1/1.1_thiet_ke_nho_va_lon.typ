== Thiết kế trong các hệ thống nhỏ và trong các hệ thống lớn <thiet_ke_nho_va_lon>

=== Giới thiệu chung

Thiết kế hệ thống không phải là một công thức cứng nhắc áp dụng cho mọi tình huống. Nó là nghệ thuật của việc đánh đổi (art of trade-offs). Một giải pháp tuyệt vời cho một startup 5 người có thể là thảm họa cho một tập đoàn 5000 kỹ sư, và ngược lại. Sự khác biệt giữa hệ thống nhỏ và hệ thống lớn không chỉ nằm ở số lượng dòng code (LOC) hay số lượng server, mà còn nằm ở triết lý quản lý, quy trình vận hành và văn hóa kỹ thuật.

Trong phần này, chúng ta sẽ đi sâu phân tích sự khác biệt cốt lõi, từ đó rút ra các nguyên tắc thiết kế phù hợp cho từng quy mô.

=== Hệ thống nhỏ

Hệ thống nhỏ thường là điểm khởi đầu của hầu hết các dự án phần mềm, từ các đồ án sinh viên, dự án cá nhân (pet projects) đến các sản phẩm MVP (Minimum Viable Product) của các startup giai đoạn sớm (Seed/Series A).

==== Đặc điểm nhận diện
- *Lượng người dùng:* Thấp đến trung bình. Thường dưới 1000 người dùng đồng thời (CCU) hoặc dưới 100 requests/giây.
- *Dữ liệu:* Kích thước dữ liệu có thể quản lý được trên một hoặc một vài ổ cứng vật lý. Schema dữ liệu thay đổi linh hoạt nhưng phạm vi ảnh hưởng hẹp.
- *Đội ngũ phát triển:* Nhóm nhỏ (2-10 người), giao tiếp trực tiếp, không cần nhiều quy trình phê duyệt phức tạp.
- *Yêu cầu phi chức năng:* Chấp nhận được downtime ngắn để bảo trì. Độ trễ (latency) không phải là vấn đề sống còn.

==== Kiến trúc điển hình: Monolithic
Trong hệ thống nhỏ, kiến trúc Monolithic là lựa chọn tối ưu nhất. Toàn bộ logic nghiệp vụ, giao diện người dùng, và lớp truy cập dữ liệu được đóng gói trong một đơn vị triển khai (deployment unit) duy nhất (ví dụ: một file `.war` trong Java, một thư mục code trong Node.js/Python).

*Cấu trúc thường thấy:*
- *Load Balancer:* Tùy chọn, thường chỉ cần nếu muốn dự phòng cơ bản.
- *Application Server:* Chạy mã nguồn backend (Django, Rails, Express, Spring Boot).
- *Database:* Một instance RDBMS duy nhất (PostgreSQL, MySQL). Có thể kèm theo một cache đơn giản (Redis) nếu cần tăng tốc đọc.

==== Lợi thế cạnh tranh
- *Tốc độ phát triển:* Đây là ưu điểm lớn nhất. Mọi thứ nằm ở một chỗ giúp việc code, refactor và thêm tính năng mới diễn ra cực nhanh. IDE hỗ trợ tốt việc điều hướng code (code navigation) và tìm kiếm tham chiếu.
- *Đơn giản trong triển khai:* Chỉ cần copy file lên server và khởi động lại. Không cần container orchestration phức tạp như Kubernetes. Có thể sử dụng các dịch vụ PaaS như Heroku, Render, hoặc Vercel để "deploy in one click".
- *Kiểm thử dễ dàng:* Có thể chạy End-to-End test trên máy local của lập trình viên mà không cần mock quá nhiều services phụ thuộc.
- *Hiệu suất:* Do các lời gọi hàm là cục bộ (in-process calls) thay vì qua mạng (RPC/HTTP), độ trễ gần như bằng 0. Không tốn chi phí serilization/deserialization dữ liệu.

==== Hạn chế tiềm ẩn
- *Điểm chết duy nhất:* Một lỗi bộ nhớ (memory leak) hoặc lỗi logic nhỏ ở một module ít quan trọng cũng có thể kéo sập toàn bộ process, làm ngưng trệ toàn bộ hệ thống.
- *Khó mở rộng theo chiều ngang:* Khi tải tăng, bạn buộc phải nhân bản toàn bộ khối monolith, ngay cả khi chỉ có một module nhỏ (ví dụ: xử lý ảnh) cần nhiều tài nguyên. Điều này gây lãng phí tài nguyên phần cứng.
- *Rào cản công nghệ:* Khó áp dụng công nghệ mới. Nếu backend viết bằng Java, rất khó để viết một module con bằng Python trong cùng một codebase mà không làm phức tạp hóa quy trình build.

=== Hệ thống lớn

Hệ thống lớn là sân chơi của các tập đoàn công nghệ (Big Tech), các nền tảng thương mại điện tử quốc tế, mạng xã hội, hoặc các hệ thống tài chính ngân hàng lõi.

==== Đặc điểm nhận diện
- *Lượng người dùng:* Hàng triệu đến hàng tỷ người dùng active. Traffic có thể đạt hàng triệu requests/giây.
- *Dữ liệu:* Dữ liệu khổng lồ (Big Data), đa dạng về chủng loại (Structured, Unstructured, Time-series). Yêu cầu lưu trữ phân tán, đa vùng địa lý.
- *Đội ngũ:* Hàng trăm đến hàng nghìn kỹ sư, chia thành nhiều team nhỏ (Squads/Tribes). Yêu cầu quy trình giao tiếp và chuẩn hóa code nghiêm ngặt.
- *Yêu cầu phi chức năng:* High Availability (99.99% trở lên), Low Latency, Strong Consistency (đối với giao dịch tài chính).

==== Kiến trúc điển hình: Microservices & Event-Driven
Hệ thống được chia nhỏ thành hàng trăm, hàng nghìn dịch vụ nhỏ độc lập (Microservices). Các dịch vụ này giao tiếp với nhau qua API (REST/gRPC) hoặc qua các kênh sự kiện bất đồng bộ (Message Queues/Event Bus).

*Thành phần phức tạp:*
- *API Gateway:* Cửa ngõ duy nhất cho client, xử lý authen/authz, rate limiting, routing.
- *Service Discovery:* Giúp các service tìm thấy nhau trong môi trường mạng động (Consul, Eureka).
- *Inter-service Communication:* Sử dụng gRPC cho hiệu năng cao hoặc Kafka/RabbitMQ để tách rời sự phụ thuộc (decoupling).
- *Polyglot Persistence:* Mỗi service sở hữu database riêng phù hợp với nghiệp vụ của nó (User service dùng MySQL, Catalogue service dùng MongoDB, Search service dùng Elasticsearch).
- *Observability:* Hệ thống giám sát tập trung (Prometheus, Grafana), Distributed Tracing (Jaeger, Zipkin) và Centralized Logging (ELK Stack).

==== Thách thức kỹ thuật
- *Độ phức tạp vận hành:* Không thể quản lý thủ công. Bắt buộc phải áp dụng DevOps, CI/CD, Infrastructure as Code (Terraform, Ansible) và Container Orchestration (Kubernetes).
- *Nhất quán dữ liệu:* Giao dịch phân tán (Distributed Transactions) là bài toán khó. Phải sử dụng các mẫu thiết kế phức tạp như Saga Pattern, 2-Phase Commit (2PC) hoặc chấp nhận Eventual Consistency.
- *Lỗi mạng và độ trễ:* Lập trình viên phải luôn giả định rằng "mạng sẽ lỗi". Cần cài đặt cơ chế Retry, Circuit Breaker, Timeout, Bulkhead để ngăn chặn lỗi lan truyền (Cascading Failures).

==== Quy trình và Con người
Ở quy mô lớn, vấn đề con người trở nên quan trọng hơn vấn đề kỹ thuật (Conway's Law).
- Các team phải hoạt động độc lập để giảm sự phụ thuộc chéo.
- Cần có các tiêu chuẩn chung (Standardization) về logging, error handling, API design để đảm bảo hệ thống đồng bộ.
- Văn hóa "Blameless Post-mortem" (Rút kinh nghiệm không đổ lỗi) khi sự cố xảy ra.

=== Bảng so sánh tổng hợp

#table(
  columns: (1fr, 1fr, 1fr),
  inset: 10pt,
  align: horizon,
  table.header(
    [*Tiêu chí*], [*Hệ thống nhỏ*], [*Hệ thống lớn*]
  ),
  [Kiến trúc], [Monolithic (Nguyên khối)], [Microservices / SOA / Event-Driven],
  [Cơ sở dữ liệu], [Đơn lẻ (Single RDBMS)], [Đa dạng (Polyglot), Phân mảnh (Sharding)],
  [Deploy], [Thủ công hoặc Script đơn giản], [Tự động hóa hoàn toàn (CI/CD, K8s)],
  [Giao tiếp], [In-process (Function calls)], [Network calls (RPC, REST, MQ)],
  [Ưu tiên], [Tốc độ phát triển (Time-to-market)], [Khả năng mở rộng, Ổn định, Bảo mật],
  [Team], [Nhỏ, Agile, Full-stack], [Lớn, Chuyên môn hóa (Backend, Frontend, DevOps, Data)],
  [Chi phí], [Thấp, tối ưu chi phí hạ tầng], [Cao, tối ưu chi phí vận hành và rủi ro]
)
#figure(image("../images/pic1.webp"), caption: [Monolithic Architecture Diagram])
=== Kết luận: Hành trình tiến hóa

Không ai xây dựng Google hay Facebook ngay từ ngày đầu tiên. Một sai lầm phổ biến của các kỹ sư trẻ là "Over-engineering" - áp dụng kiến trúc của hệ thống lớn cho một dự án nhỏ xíu. Điều này dẫn đến sự phức tạp không cần thiết, làm chậm tiến độ và lãng phí nguồn lực.

Chiến lược đúng đắn là: *"Start Small, Scale Fast"*.
1.  Bắt đầu với Monolith được thiết kế tốt (Modular Monolith).
2.  Tách biệt rõ ràng các module logic bên trong code.
3.  Khi một module cụ thể trở thành điểm nghẽn (bottleneck) về hiệu năng hoặc quy trình phát triển, hãy tách nó ra thành một Microservice riêng biệt.
4.  Dần dần chuyển dịch sang kiến trúc phân tán theo nhu cầu thực tế.

Thiết kế hệ thống là một quá trình tiến hóa liên tục, không phải là một đích đến cố định.