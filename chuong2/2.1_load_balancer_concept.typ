== Load Balancer <load_balancer_concept>

=== Định nghĩa và Khái niệm cốt lõi

Trong kỷ nguyên số, khi hàng triệu người dùng cùng truy cập vào một ứng dụng web, một máy chủ đơn lẻ (dù mạnh mẽ đến đâu) cũng không thể gánh vác toàn bộ khối lượng công việc. Nó sẽ nhanh chóng bị quá tải, dẫn đến độ trễ cao, treo máy, hoặc sập hoàn toàn. Để giải quyết vấn đề này, kỹ thuật *Load Balancing (Cân bằng tải)* ra đời.

*Load Balancer* là một thiết bị phần cứng hoặc một phần mềm đóng vai trò như một "cảnh sát giao thông" điều phối lưu lượng mạng (network traffic) đến một nhóm các máy chủ backend (server farm hoặc server pool).

Nhiệm vụ cốt lõi của nó là phân phối khối lượng công việc (workload) một cách hiệu quả nhất trên nhiều tài nguyên tính toán, nhằm mục đích:
- Tối ưu hóa việc sử dụng tài nguyên (không để server nào ngồi chơi, không để server nào làm quá sức).
- Tối đa hóa thông lượng (Throughput).
- Giảm thiểu thời gian phản hồi (Response Time).
- Tránh quá tải cho bất kỳ nguồn lực đơn lẻ nào.

=== Vai trò chính trong Kiến trúc hệ thống

Load Balancer không chỉ đơn thuần là bộ chia tải. Trong các kiến trúc hiện đại (Microservices, Cloud-Native), nó đóng vai trò trung tâm với nhiều chức năng mở rộng:

==== Phân phối lưu lượng
Đây là chức năng cơ bản nhất. Load Balancer tiếp nhận các yêu cầu từ client (trình duyệt, ứng dụng mobile, các service khác) và chuyển tiếp chúng đến một server cụ thể trong cụm backend dựa trên các thuật toán định sẵn.
- Đảm bảo tính cân bằng: Giúp các server chịu tải đồng đều.
- Xử lý đột biến (Spike): Khi traffic tăng đột ngột, LB giúp phân tán áp lực, tránh hiện tượng "thắt cổ chai" (bottleneck).

#figure(image("../images/pic4.jpg"), caption: [Load Balancer Architecture Diagram])

==== Đảm bảo tính sẵn sàng
Load Balancer đóng vai trò quan trọng trong việc loại bỏ điểm chết duy nhất (Single Point of Failure - SPOF) ở tầng ứng dụng.
- *Health Checks:* LB liên tục gửi các tín hiệu (ping, HTTP request) đến các backend server để kiểm tra trạng thái sống/chết.
- *Automatic Failover:* Nếu một server không phản hồi Health Check, LB sẽ lập tức loại server đó ra khỏi danh sách điều hướng (pool) và chỉ gửi traffic đến các server còn sống. Khi server đó hồi phục, LB sẽ tự động đưa nó trở lại pool.

==== Bảo mật
Load Balancer thường là chốt chặn đầu tiên bảo vệ hệ thống backend (First line of defense).
- *SSL/TLS Termination:* Thay vì để web server tốn CPU giải mã HTTPS, LB sẽ đảm nhận việc này. Traffic từ Client -> LB là HTTPS (mã hóa), traffic từ LB -> Server là HTTP (không mã hóa, đi trong mạng nội bộ an toàn). Điều này giúp giảm tải đáng kể cho Web Server.
- *DDoS Mitigation:* LB có thể phát hiện và ngăn chặn các cuộc tấn công từ chối dịch vụ (SYN flood, UDP flood) trước khi chúng chạm tới server ứng dụng.
- *Web Application Firewall:* Nhiều LB hiện đại tích hợp WAF để chặn SQL Injection, XSS.

==== Khả năng mở rộng linh hoạt
Load Balancer cho phép quản trị viên thêm hoặc bớt server vào cụm backend một cách trong suốt (transparent) đối với người dùng cuối.
- Khi cần mở rộng: Chỉ cần bật thêm server mới và đăng ký IP của nó với LB. Traffic sẽ tự động chảy vào server mới.
- Khi bảo trì: Có thể rút từng server ra khỏi LB (draining), nâng cấp, rồi đưa lại mà không làm gián đoạn dịch vụ (Zero-downtime deployment).

=== Nguyên lý hoạt động chi tiết

Quy trình xử lý một request qua Load Balancer thường diễn ra như sau:

1.  *Client Request:* Người dùng nhập `www.example.com`. DNS server trả về IP của Load Balancer (VIP - Virtual IP). Client gửi HTTP Request đến VIP này.
2.  *Listener tiếp nhận:* LB lắng nghe trên port 80 hoặc 443. Nó kiểm tra gói tin xem có hợp lệ không.
3.  *Lựa chọn Server:* Dựa trên thuật toán cấu hình (ví dụ: Round Robin) và trạng thái Health Check, LB chọn ra server tốt nhất để xử lý (ví dụ: Server B).
4.  *NAT/Forwarding:* LB thay đổi địa chỉ đích của gói tin từ VIP sang IP thực của Server B (Destination NAT). Hoặc LB đóng vai trò Reverse Proxy, tạo kết nối mới tới Server B.
5.  *Processing:* Server B xử lý yêu cầu, truy vấn database, tạo HTML/JSON trả về.
6.  *Response:* Server B gửi phản hồi lại cho LB.
7.  *Return to Client:* LB thay đổi địa chỉ nguồn từ IP Server B thành VIP của chính nó, rồi gửi phản hồi về cho Client. Client hoàn toàn không biết sự tồn tại của Server B.

=== Ví dụ thực tế

Hãy tưởng tượng một siêu thị lớn (Hệ thống Web).
- *Khách hàng (Client):* Hàng trăm người muốn thanh toán cùng lúc.
- *Quầy thu ngân (Backend Servers):* Có 10 quầy đang hoạt động.
- *Người điều phối (Load Balancer):* Một nhân viên đứng đầu hàng.

*Kịch bản hoạt động:*
Khi khách đến, người điều phối quan sát:
- Quầy 1 đang trống -> Mời khách vào quầy 1.
- Quầy 2 đang có khách nhưng sắp xong -> Mời khách tiếp theo chờ quầy 2.
- Quầy 3 nhân viên bị ốm đột xuất (Server Crash) -> Người điều phối lập tức đóng làn quầy 3, không cho ai vào đó nữa (Health Check fail).
- Khách quá đông -> Siêu thị mở thêm Quầy 11, 12. Người điều phối bắt đầu chia khách sang quầy mới (Scalability).

Nếu không có người điều phối (Load Balancer), khách hàng sẽ chen lấn vào một quầy duy nhất gây tắc nghẽn, trong khi các quầy khác lại vắng tanh.

=== Lịch sử phát triển

- *Thập kỷ 90:* Load Balancing bắt đầu dưới dạng các thiết bị phần cứng đắt tiền, chủ yếu dùng DNS Round Robin đơn giản.
- *Thập kỷ 2000:* Sự ra đời của Application Delivery Controllers (ADC) - Load Balancer thông minh hơn, có thể offload SSL, nén dữ liệu, caching.
- *Thập kỷ 2010:* Software Load Balancer lên ngôi (Nginx, HAProxy) và các dịch vụ LB trên Cloud (AWS ELB, Google Cloud Load Balancing) trở thành tiêu chuẩn.
- *Hiện nay:* Sự trỗi dậy của Client-side Load Balancing và Service Mesh (Istio, Linkerd) để xử lý giao tiếp Đông-Tây (East-West traffic) giữa hàng nghìn service nhỏ.