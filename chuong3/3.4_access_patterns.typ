== Caching Access Patterns <access_patterns>

Cách ứng dụng (Application) tương tác với Cache và Database (System of Record - SoR) xác định tính nhất quán và hiệu năng của hệ thống. Có 4 pattern chính:

=== Cache-Aside

==== Khái niệm
Trong mô hình này, *Ứng dụng (Code)* đóng vai trò trung tâm, chịu trách nhiệm điều phối việc đọc ghi giữa Cache và DB. Cache chỉ là một kho chứa dữ liệu thụ động (side storage).

==== Quy trình hoạt động
1.  *Đọc (Read):*
    - App kiểm tra Cache.
    - Nếu có (Hit) -> Trả về Client.
    - Nếu không (Miss) -> App query Database -> App lưu kết quả vào Cache -> Trả về Client.
2.  *Ghi/Cập nhật (Write):*
    - App cập nhật Database trước.
    - Sau đó App xóa (invalidate) hoặc cập nhật key tương ứng trong Cache.

==== Ưu điểm
- *Resilience:* Nếu Cache chết, App vẫn hoạt động bình thường (chỉ chậm hơn vì phải gọi DB).
- *Linh hoạt:* Logic cache nằm trong code, dễ tùy biến (ví dụ: chỉ cache user VIP).
- *Tiết kiệm:* Chỉ dữ liệu nào được "hỏi đến" mới được load vào cache (Lazy). Không lãng phí RAM cho dữ liệu không ai dùng.

==== Nhược điểm
- *Stale Data (Dữ liệu cũ):* Có một khoảng thời gian trễ giữa lúc update DB và update Cache. Nếu process chết giữa chừng sau khi update DB mà chưa xóa Cache -> Dữ liệu sai lệch.
- *Thundering Herd:* Khi key hết hạn, nhiều request cùng chọc vào DB để load lại.

==== Ví dụ (Pseudo-code)
```python
def get_user(user_id):
    user = cache.get(user_id)
    if user is None:
        user = db.query("SELECT * FROM users WHERE id = ?", user_id)
        cache.set(user_id, user, ttl=3600)
    return user

def update_user(user):
    db.update(user)
    cache.delete(user.id) # Invalidate
```

---

=== Read-Through Cache

==== Khái niệm
Ứng dụng coi Cache là *nguồn dữ liệu chính (Main Data Store)*. Ứng dụng không bao giờ gọi trực tiếp Database. Cache tự lo việc đồng bộ với DB.
Cache đóng vai trò là một "Proxy" thông minh.

==== Quy trình
- App gọi `cache.get(key)`.
- Nếu Hit -> Cache trả về.
- Nếu Miss -> *Cache tự động* kết nối DB, load dữ liệu, lưu lại, rồi trả về cho App.

==== Ưu điểm
- *Code gọn nhẹ:* App không cần quan tâm logic "check miss, load db". Code nghiệp vụ sạch sẽ.
- *Dễ dùng chung:* Nhiều ứng dụng cùng dùng chung logic caching được cài đặt sẵn trong Cache Provider.

==== Nhược điểm
- *Phức tạp:* Cần thư viện Cache hoặc plugin hỗ trợ (ví dụ: Redis Gears, JVM Cache Loader). Redis thuần túy không hỗ trợ cái này out-of-the-box.
- *Khó tùy biến query:* Cache thường chỉ load theo Primary Key. Nếu muốn query phức tạp `WHERE age > 18`, mô hình này khó đáp ứng.

---

=== Write-Through Cache

==== Khái niệm
Tương tự Read-Through, nhưng áp dụng cho việc GHI. Dữ liệu được ghi vào Cache và DB *đồng thời* và *tuần tự*.

==== Quy trình
- App gọi `cache.set(key, value)`.
- Cache ghi dữ liệu vào bộ nhớ của nó.
- *Ngay lập tức*, Cache (hoặc thread của App) ghi dữ liệu xuống DB một cách đồng bộ (Synchronous).
- Khi cả 2 nơi đều thành công, mới trả về "Success" cho Client.

==== Ưu điểm
- *Data Consistency Tuyệt đối:* Cache và DB luôn giống nhau (gần như 100%).
- *No Stale Data:* Không bao giờ đọc phải dữ liệu cũ.
- *Reliability:* Dữ liệu an toàn vì đã nằm trong DB.

==== Nhược điểm
- *Write Latency cao:* Thời gian ghi = Thời gian ghi Cache + Thời gian ghi DB. Chậm nhất trong các mô hình.
- *Cache Pollution:* Dữ liệu vừa ghi vào Cache chưa chắc đã được đọc lại ngay, gây lãng phí RAM (trái ngược với Cache-Aside).

---

=== Write-Back

==== Khái niệm
Tối ưu hóa tốc độ ghi đến mức cực đại. Ghi vào Cache trước, DB sau.

==== Quy trình
- App gọi `cache.set(key, value)`.
- Cache lưu dữ liệu, trả về "Success" *ngay lập tức* cho App.
- Sau đó (Asynchronously), Cache mới âm thầm đẩy dữ liệu xuống DB (sau vài giây hoặc khi đầy buffer).

==== Ưu điểm
- *Write Performance cực khủng:* App không phải chờ DB (vốn chậm chạp). Phù hợp cho các hệ thống ghi nhiều như Log, Tracking, IoT sensor.
- *Giảm tải DB:* Có thể gộp nhiều lần ghi vào Cache thành 1 lần ghi xuống DB (Batch Write). Ví dụ: Update biến đếm từ 1 lên 100 trong cache, chỉ cần ghi số 100 xuống DB 1 lần cuối cùng.

==== Nhược điểm
- *Risk of Data Loss (Mất dữ liệu):* Rủi ro cao nhất. Nếu Cache Server sập (mất điện) trước khi kịp sync xuống DB -> Dữ liệu bay màu vĩnh viễn.
- *Consistency:* DB luôn ở trạng thái cũ hơn Cache (Eventual Consistency).

---

=== Bảng so sánh tổng hợp

#table(
  columns: (1fr, 1fr, 1fr, 1fr, 1fr),
  inset: 5pt,
  align: horizon,
  table.header(
    [*Pattern*], [*Đọc*], [*Ghi*], [*Ưu điểm chính*], [*Nhược điểm chính*]
  ),
  [Cache-Aside], [Lazy (khi cần)], [Update DB -> Del Cache], [Robust, Linh hoạt], [Data Stale, Code lặp],
  [Read-Through], [Eager (tự động)], [N/A], [Code gọn, Transparent], [Cần Plugin hỗ trợ],
  [Write-Through], [N/A], [Sync (Cache + DB)], [Nhất quán cao], [Ghi chậm],
  [Write-Back], [N/A], [Async (Cache -> DB)], [Ghi cực nhanh], [Mất dữ liệu]
)

=== Kết luận
- *80% trường hợp:* Dùng *Cache-Aside* kết hợp với Redis. Đây là tiêu chuẩn ngành.
- *Hệ thống tài chính/Core Banking:* Có thể dùng *Write-Through* để đảm bảo an toàn.
- *Hệ thống Analytics/Counter:* Dùng *Write-Back* để chịu tải ghi lớn.