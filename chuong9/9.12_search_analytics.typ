== Search & Analytics <search_analytics>

Khi ứng dụng cần tìm kiếm Full-text (tìm gần đúng, tìm theo từ đồng nghĩa) hoặc thống kê dữ liệu lớn, SQL Database không còn phù hợp.

=== Elasticsearch

- *Thư viện:* `@elastic/elasticsearch`.
- *Chức năng:*
    - Full-text Search: Tìm kiếm sản phẩm, bài viết cực nhanh.
    - Faceted Search: Bộ lọc nhiều tiêu chí (Màu sắc, Kích thước, Giá tiền) như Shopee/Lazada.
    - Analytics: Tính toán Aggregation (Sum, Avg, Histogram) trên hàng tỷ bản ghi.

=== Integration Patterns

Làm sao để dữ liệu trong SQL (MySQL/PostgreSQL) đồng bộ sang Elasticsearch?

==== Synchronous
- App ghi vào DB -> Thành công -> App ghi tiếp vào ES.
- *Nhược:* Chậm. Dễ bị sai lệch dữ liệu nếu bước 2 lỗi.

==== Asynchronous
- App ghi vào DB -> Bắn event `ProductCreated` vào Kafka/RabbitMQ.
- Một Worker riêng (Consumer) đọc event và ghi vào ES.
- *Ưu:* Decoupling. Retries dễ dàng.

==== CDC
- Sử dụng công cụ (Debezium) lắng nghe Binlog của MySQL.
- Bất kỳ thay đổi nào trong DB sẽ tự động được stream sang Kafka -> ES.
- *Ưu:* Không cần sửa code App. Độ tin cậy cao nhất.