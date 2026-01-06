== Deploy Patterns <deploy_patterns>

Việc lựa chọn mô hình triển khai ảnh hưởng trực tiếp đến khả năng mở rộng (scalability), độ tin cậy (reliability) và chi phí vận hành của hệ thống. Dưới đây là 3 mô hình phổ biến nhất trong lịch sử phát triển phần mềm.

=== Multiple Service Instances per Host

Đây là mô hình truyền thống nhất, thường thấy trước kỷ nguyên Container.

==== Mô tả
Chúng ta mua một máy chủ vật lý (hoặc một máy ảo VM lớn). Trên máy chủ đó, chúng ta cài đặt môi trường (Java Runtime, Node.js, Python libs) và chạy nhiều instance của các service khác nhau (hoặc cùng một service) song song.
- Ví dụ: Một máy chủ Linux chạy Tomcat (cho Java App), Nginx (cho Web Frontend) và MySQL Database cùng lúc.

==== Ưu điểm
1.  *Tận dụng tài nguyên (Resource Utilization):* Nếu Service A ít dùng CPU, Service B dùng nhiều CPU, chúng có thể bù trừ cho nhau, giúp CPU của máy chủ luôn hoạt động hiệu quả, tránh lãng phí.
2.  *Triển khai nhanh (ở quy mô nhỏ):* Chỉ cần copy file `.war` hoặc code lên server và restart process là xong. Không cần build image phức tạp.
3.  *Khởi động cực nhanh:* Process khởi động nhanh hơn VM hay Container rất nhiều.

==== Nhược điểm chí mạng
1.  *Thiếu cô lập (Poor Isolation):*
    - Nếu Service A bị Memory Leak ăn hết RAM, Service B và Database sẽ bị OOM Kill (Out Of Memory) theo, dù chúng chẳng làm gì sai.
    - Lỗi của một process có thể làm crash cả hệ điều hành.
2.  *Xung đột thư viện (Dependency Conflict - Dependency Hell):*
    - Service A cần Java 8. Service B cần Java 17. Trên cùng 1 OS chỉ cài được 1 biến môi trường `JAVA_HOME` mặc định. Việc quản lý version rất đau đầu.
3.  *Khó giới hạn tài nguyên:* Rất khó để bảo "Service A chỉ được dùng tối đa 1GB RAM".
4.  *Khó monitor:* Khi server chậm, khó biết do service nào gây ra.

=== Service Instance per Host

Để giải quyết vấn đề cô lập, ta chuyển sang mô hình "Mỗi service một nhà". Có 2 biến thể chính:

==== Service Instance per VM
Mỗi service chạy trên một EC2 Instance (AWS) hoặc VM (VMware) riêng biệt.
- *Ưu điểm:* Cô lập tuyệt đối. Mỗi service có OS riêng, kernel riêng. Service A hack cũng không ảnh hưởng Service B. Dễ dàng scale (Amazon Autoscaling Group).
- *Nhược điểm:* Lãng phí tài nguyên khủng khiếp (Mỗi VM tốn vài GB RAM cho OS kernel). Thời gian boot chậm (vài phút). Chi phí bản quyền OS đắt đỏ.

==== Service Instance per Container
Đây là tiêu chuẩn hiện đại. Mỗi service chạy trong 1 Container.
- *Mô tả:* Container ảo hóa ở tầng OS (chia sẻ Kernel), nhưng cô lập về Process ID, Network, File System (thông qua Linux Namespaces & Cgroups).
- *Ưu điểm:*
    - *Cô lập tốt:* Như VM nhưng nhẹ hơn.
    - *Tốc độ:* Khởi động trong mili-giây.
    - *Đóng gói (Packaging):* Docker Image chứa toàn bộ thư viện cần thiết. "Build once, run anywhere". Service A dùng Java 8, Service B dùng Java 17 thoải mái trên cùng 1 máy chủ.
- *Nhược điểm:* Cần học thêm công nghệ Docker/Kubernetes. Quản lý mạng giữa các container phức tạp hơn.

=== Serverless Deployment

Mô hình này trừu tượng hóa hoàn toàn khái niệm "máy chủ". Bạn chỉ quan tâm đến Code (Function).

==== Mô tả
Bạn viết code (Function), nén thành file zip và upload lên Cloud Provider (AWS Lambda, Google Cloud Functions, Azure Functions).
Bạn định nghĩa sự kiện kích hoạt (Event Trigger): "Khi có HTTP Request vào API Gateway", hoặc "Khi có file mới trong S3".
Cloud Provider sẽ tự động bật code của bạn lên chạy, xử lý xong thì tắt đi.

==== Ưu điểm
1.  *Chi phí tối ưu (Pay-per-use):* Bạn chỉ trả tiền cho thời gian code chạy (tính bằng mili-giây). Không có request -> Không tốn tiền. Không cần nuôi server 24/7.
2.  *Zero Administration:* Không cần vá lỗi OS, không cần SSH, không cần lo đầy ổ cứng. Tất cả là trách nhiệm của Cloud Provider.
3.  *Scalability vô hạn:* 1 request hay 1 triệu request, Cloud Provider tự động scale số lượng function instances lên để đáp ứng.

==== Nhược điểm
1.  *Cold Start (Khởi động lạnh):* Nếu lâu không có request, Cloud sẽ tắt function. Request tiếp theo sẽ phải chờ Cloud bật container lên, nạp code, khởi tạo runtime (mất từ 100ms đến vài giây). Không phù hợp cho ứng dụng cần độ trễ thấp liên tục (Real-time trading).
2.  *Vendor Lock-in:* Code viết cho AWS Lambda rất khó mang sang chạy ở Google Cloud Functions mà không sửa đổi nhiều.
3.  *Giới hạn tài nguyên:* Lambda thường giới hạn thời gian chạy tối đa (ví dụ 15 phút), RAM tối đa (10GB). Không chạy được các tác vụ train AI lâu dài.
4.  *Khó debug:* Không thể SSH vào server để xem log realtime hay dump heap dễ dàng. Phải phụ thuộc vào công cụ monitoring của Cloud.

=== Bảng so sánh tổng hợp

#table(
  columns: (1.2fr, 1fr, 1fr, 1fr),
  inset: 10pt,
  align: horizon,
  table.header(
    [*Tiêu chí*], [*Multiple/Host*], [*Container/Host*], [*Serverless*]
  ),
  [Cô lập (Isolation)], [Thấp (Process)], [Cao (Container)], [Rất cao (Sandbox)],
  [Hiệu suất tài nguyên], [Cao], [Rất cao], [Trung bình (tốn overhead)],
  [Chi phí vận hành], [Thấp (nhưng rủi ro)], [Trung bình (cần K8s)], [Rất thấp (NoOps)],
  [Khả năng scale], [Kém (Scale dọc)], [Tốt (Scale ngang)], [Tuyệt vời (Auto)],
  [Thời gian khởi động], [Nhanh], [Rất nhanh], [Chậm (Cold Start)]
)