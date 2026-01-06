== Tổng quan về Transaction <transaction_overview>

=== Định nghĩa Transaction

Trong khoa học máy tính và hệ quản trị cơ sở dữ liệu (DBMS), một *Transaction (Giao dịch)* là một đơn vị công việc (unit of work) logic, bao gồm một hoặc nhiều thao tác truy cập/cập nhật dữ liệu, được thực hiện trọn vẹn như một hành động duy nhất.

Một transaction không được phép thực hiện "nửa vời". Hoặc là tất cả các bước bên trong nó đều thành công (Commit), hoặc là không có bước nào được lưu lại cả (Rollback).

*Ví dụ kinh điển: Chuyển tiền ngân hàng*
Giả sử có giao dịch chuyển 100\$ từ tài khoản A sang tài khoản B. Giao dịch này gồm 2 bước:
1.  Trừ 100\$ từ tài khoản A (`UPDATE accounts SET balance = balance - 100 WHERE id = 'A'`).
2.  Cộng 100\$ vào tài khoản B (`UPDATE accounts SET balance = balance + 100 WHERE id = 'B'`).

Nếu bước 1 thành công nhưng bước 2 thất bại (do mất điện, lỗi mạng), tiền sẽ biến mất khỏi A nhưng không đến được B. Transaction đảm bảo điều này không bao giờ xảy ra.

=== Thuộc tính ACID

Để đảm bảo tính đúng đắn của dữ liệu, Jim Gray và các nhà nghiên cứu đã định nghĩa 4 thuộc tính bắt buộc của một transaction, gọi tắt là ACID.

==== Atomicity
*Định nghĩa:* "All or Nothing". Giao dịch được coi là một nguyên tử không thể chia cắt.
- Nếu mọi thao tác trong transaction thành công -> Transaction thành công (Committed).
- Nếu có bất kỳ thao tác nào lỗi -> Transaction thất bại (Aborted), và database phải được hoàn tác (Rollback) về trạng thái y hệt như trước khi transaction bắt đầu.

*Cơ chế thực hiện:*
Các RDBMS thường sử dụng *Write-Ahead Logging (WAL)*. Mọi thao tác đều được ghi vào log file trước khi ghi vào data file. Nếu hệ thống crash giữa chừng, khi khởi động lại, DB sẽ đọc WAL để "undo" các transaction chưa hoàn tất.

==== Consistency
*Định nghĩa:* Transaction phải đưa database từ một trạng thái hợp lệ này sang một trạng thái hợp lệ khác.
- "Hợp lệ" nghĩa là tuân thủ tất cả các ràng buộc toàn vẹn (Integrity Constraints) như Primary Key, Foreign Key, Check constraints, Trigger...
- *Ví dụ:* Nếu có ràng buộc `balance >= 0`, transaction nào làm cho số dư âm sẽ bị từ chối ngay lập tức.

*Lưu ý:* Consistency trong ACID khác với Consistency trong CAP Theorem.
- ACID Consistency: Dữ liệu đúng logic nghiệp vụ.
- CAP Consistency: Dữ liệu giống nhau trên mọi node (Linearizability).



==== Isolation
*Định nghĩa:* Các transaction chạy đồng thời (concurrently) không được ảnh hưởng lẫn nhau. Kết quả của việc chạy nhiều transaction song song phải giống hệt như khi chạy chúng tuần tự (serially).

*Các mức độ cô lập (Isolation Levels):*
Việc cô lập hoàn toàn (Serializable) rất tốn kém về hiệu năng, nên DB cung cấp các mức thấp hơn:
1.  *Read Uncommitted:* Transaction A đọc được dữ liệu chưa commit của B (Dirty Read). -> Rất nguy hiểm.
2.  *Read Committed:* Chỉ đọc được dữ liệu đã commit. (Chống Dirty Read). -> Mặc định của PostgreSQL, SQL Server.
3.  *Repeatable Read:* Đảm bảo đọc một dòng 2 lần trong cùng 1 transaction thì kết quả y hệt. (Chống Non-repeatable Read). -> Mặc định của MySQL/InnoDB.
4.  *Serializable:* Cô lập tuyệt đối. Chạy tuần tự. (Chống Phantom Read).

==== Durability
*Định nghĩa:* Một khi transaction đã được Commit thành công, kết quả của nó phải được lưu trữ vĩnh viễn, ngay cả khi hệ thống bị mất điện ngay sau đó.

*Cơ chế thực hiện:*
Dữ liệu phải được ghi xuống bộ nhớ không bay hơi (Non-volatile storage - HDD/SSD). Để tối ưu hiệu năng, DB thường ghi vào transaction log (sequential write - nhanh) trước, rồi mới ghi vào data file (random write - chậm) sau (Checkpointing).

=== Distributed Transaction

==== Định nghĩa
Giao dịch phân tán là một transaction liên quan đến dữ liệu nằm trên hai hoặc nhiều node (cơ sở dữ liệu, message queue, file system) khác nhau, được kết nối qua mạng.

*Ví dụ trong Microservices:*
- Service `Order` (DB PostgreSQL) tạo đơn hàng.
- Service `Inventory` (DB MySQL) trừ kho.
- Service `Payment` (DB Oracle) trừ tiền.

Giao dịch này phải đảm bảo tính ACID trên cả 3 DB khác nhau.

==== Tại sao nó khó?
Trong môi trường phân tán, chúng ta đối mặt với *8 Fallacies of Distributed Computing*, đặc biệt là:
1.  *Network is unreliable:* Tin nhắn "Commit" gửi đi có thể bị mất. Node A không biết Node B đã commit hay chưa.
2.  *Latency:* Giao tiếp qua mạng rất chậm. Giữ lock (khóa) trong thời gian dài chờ mạng sẽ làm treo toàn bộ hệ thống.
3.  *Partial Failure:* Một node chết, node kia sống. Làm sao đồng bộ trạng thái?

==== CAP Theorem
Eric Brewer chứng minh rằng một hệ thống phân tán không thể đồng thời đảm bảo cả 3 yếu tố:
- *C (Consistency):* Nhất quán dữ liệu (mọi node thấy cùng data).
- *A (Availability):* Sẵn sàng (mọi request đều được phản hồi).
- *P (Partition Tolerance):* Chịu lỗi phân vùng mạng (hệ thống vẫn chạy khi đứt cáp).

Vì P là bắt buộc trong hệ thống mạng, ta chỉ được chọn *CP* (ngừng phục vụ để giữ đúng dữ liệu - Transaction truyền thống) hoặc *AP* (cứ phục vụ dù dữ liệu có thể sai lệch - NoSQL/Eventual Consistency).

Các giao thức như 2PC, 3PC cố gắng đạt được tính *ACID (CP)* trong môi trường phân tán, nhưng phải trả giá đắt về hiệu năng và độ sẵn sàng.