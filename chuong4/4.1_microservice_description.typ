== Miêu tả Microservice <microservice_description>

=== Định nghĩa và Bản chất

Kiến trúc Microservice không chỉ là một phương pháp lập trình, mà là một tư duy tổ chức hệ thống. Martin Fowler, một trong những cha đẻ của khái niệm này, định nghĩa:

> *"Kiến trúc Microservice là một phương pháp phát triển ứng dụng phần mềm như một bộ sưu tập các dịch vụ nhỏ (services), mỗi dịch vụ chạy trên quy trình riêng (process) và giao tiếp với nhau thông qua các cơ chế nhẹ (lightweight mechanisms), thường là HTTP API."*

Khác với kiến trúc Nguyên khối (Monolithic) nơi tất cả logic nghiệp vụ, giao diện, và truy cập dữ liệu được đóng gói trong một khối duy nhất (`.war`, `.jar`, `.exe`), Microservice chia nhỏ bài toán lớn thành nhiều bài toán con. Mỗi dịch vụ con này:
- Được xây dựng xung quanh một *khả năng nghiệp vụ* cụ thể (ví dụ: Quản lý đơn hàng, Quản lý kho, Thanh toán).
- Có thể được *triển khai độc lập* hoàn toàn tự động.
- Có sự *quản lý phi tập trung* về ngôn ngữ lập trình và dữ liệu.

#figure(image("../images/pic8.png"), caption: [Monolith vs Microservices Architecture Diagram])

=== Các đặc điểm chính

Để phân biệt Microservice "chuẩn" với các hệ thống phân tán hỗn độn, chúng ta dựa trên các đặc điểm cốt lõi sau:

==== Componentization via Services
Trong Monolith, "component" thường là các thư viện (libraries) được gọi trong cùng bộ nhớ (in-process calls). Trong Microservice, "component" là các services giao tiếp qua mạng (RPC/REST).
- *Lợi ích:* Bạn có thể update Service A mà không cần redeploy Service B (nếu giữ nguyên hợp đồng API).
- *Thách thức:* Gọi qua mạng chậm hơn gọi hàm, và interface qua mạng (API) khó thay đổi hơn interface trong code.

==== Organized around Business Capabilities
Luật Conway (Conway's Law) phát biểu: *"Các tổ chức thiết kế hệ thống ... bị giới hạn bởi cấu trúc giao tiếp của chính tổ chức đó."*
- *Monolith truyền thống:* Chia team theo tầng kỹ thuật (UI Team, Server-side Team, DBA Team). Khi cần sửa một tính năng, phải họp cả 3 team -> Chậm chạp.
- *Microservice:* Chia team theo nghiệp vụ (Order Team, Shipping Team). Team này là *Cross-functional* (có đủ UI, BE, DB, QA). Họ sở hữu sản phẩm từ lúc code đến lúc vận hành (You build it, you run it).

==== Products not Projects
- Tư duy dự án: Code xong, bàn giao cho đội vận hành (Ops), rồi giải tán team làm dự án khác.
- Tư duy sản phẩm (Microservice): Team gắn bó với service trọn đời. Họ liên tục cải tiến nó dựa trên phản hồi thực tế.

==== Smart endpoints and dumb pipes
Đây là điểm khác biệt lớn nhất với SOA (Service Oriented Architecture).
- *SOA (ESB - Enterprise Service Bus):* Dồn logic phức tạp vào đường ống nối (Routing, Transformation, Orchestration nằm ở ESB). ESB trở thành điểm nghẽn và cực kỳ đắt đỏ.
- *Microservice:* Logic nằm ở chính các service (Smart endpoints). Đường ống kết nối (HTTP, RabbitMQ) chỉ làm nhiệm vụ chuyển tin nhắn đơn thuần (Dumb pipes).

==== Decentralized Governance
- Không có chuẩn cứng nhắc "Toàn bộ công ty phải dùng Java".
- Service A cần hiệu năng cao -> Viết bằng C++/Go.
- Service B cần xử lý dữ liệu nhanh -> Viết bằng Python.
- Service C là CRUD đơn giản -> Viết bằng Node.js.
Tuy nhiên, vẫn cần các chuẩn chung về giao tiếp (API contracts), logging, và monitoring (Standardized Observability).

==== Decentralized Data Management
- *Monolith:* 1 Database khổng lồ dùng chung cho tất cả module. Dễ join bảng, nhưng schema bị ràng buộc chặt (tight coupling).
- *Microservice:* Mỗi service sở hữu database riêng (Database per Service pattern). Order Service không được phép `SELECT` trực tiếp vào bảng `Customers` của Customer Service. Nó phải gọi API `GET /customers/{id}`.
- *Hệ quả:* Dữ liệu bị dư thừa (Redundancy) và khó đảm bảo tính nhất quán (Consistency).

==== Infrastructure Automation
Không thể quản lý 100 microservices bằng tay. Bắt buộc phải có:
- *CI/CD:* Automated Testing và Deployment.
- *Containerization:* Docker, Kubernetes.
- *IaC:* Terraform, Ansible.

==== Design for Failure
Trong Monolith, các hàm gọi nhau rất tin cậy. Trong Microservice, service gọi qua mạng nên *mạng sẽ lỗi*.
- Service phải biết cách xử lý khi đối tác bị chậm hoặc chết.
- Áp dụng Circuit Breaker, Retry, Timeout, Bulkhead.
- Hệ thống phải có khả năng tự phục hồi (Resilience).

=== Lợi ích chính

1.  *Khả năng mở rộng:* Scale đúng chỗ cần thiết. Module "Báo cáo" chạy nặng thì chỉ cần tăng server cho service Báo cáo, không cần scale service Đăng nhập.
2.  *Tốc độ phát triển:* Các team nhỏ làm việc song song, không dẫm chân lên nhau. Deploy tính năng mới nhanh chóng (Time-to-market).
3.  *Cô lập lỗi:* Một service bị Memory Leak chết không kéo theo cả hệ thống chết (nếu thiết kế tốt).
4.  *Tự do công nghệ:* Dễ dàng thử nghiệm công nghệ mới ở quy mô nhỏ mà không rủi ro đập đi xây lại toàn bộ.

=== Lưu ý khi áp dụng

*"Microservices is not a free lunch."*
Đừng dùng Microservice nếu hệ thống của bạn chưa đủ phức tạp. Chi phí quản lý hệ thống phân tán (Distributed System Complexity) thường cao hơn chi phí quản lý Monolith ở quy mô nhỏ.

Chỉ nên chuyển sang Microservice khi:
- Team quá lớn, giao tiếp trở nên tắc nghẽn.
- Monolith quá lớn, thời gian build và deploy mất hàng giờ.
- Các module có yêu cầu về tài nguyên xung đột nhau (cái cần nhiều RAM, cái cần nhiều CPU).
- Cần độ sẵn sàng (Availability) cực cao.