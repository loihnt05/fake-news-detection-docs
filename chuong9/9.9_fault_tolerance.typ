== Fault tolerance, Circuit Breaker, Retry <fault_tolerance>

"Everything fails all the time" (Werner Vogels - CTO Amazon). Hệ thống phân tán phải được thiết kế để chịu lỗi.

=== Retry Patterns

Khi gọi API bị lỗi (mạng chập chờn, server busy), hành động đơn giản nhất là thử lại.

- *Naive Retry:* Thử lại ngay lập tức. Rủi ro: Nếu server đang chết, việc spam request liên tục sẽ làm nó chết hẳn (Retry Storm).
- *Exponential Backoff:*
    - Lần 1: Chờ 1s -> Retry.
    - Lần 2: Chờ 2s -> Retry.
    - Lần 3: Chờ 4s -> Retry.
    - Lần 4: Chờ 8s -> Retry.
- *Jitter:* Thêm một khoảng random vào thời gian chờ để tránh việc hàng nghìn client cùng retry vào đúng một thời điểm.

=== Circuit Breaker

Bảo vệ hệ thống khỏi việc chờ đợi vô vọng vào một service đã chết.

- *Thư viện Node.js:* `opossum`, `cockatiel`.
- *Trạng thái:*
    1.  *Closed:* Mọi thứ bình thường. Request đi qua.
    2.  *Open:* Khi tỉ lệ lỗi vượt ngưỡng (ví dụ 50%), cầu dao bật mở. Mọi request đến sau đó sẽ bị chặn ngay lập tức (Fail Fast), không gọi sang service lỗi nữa.
    3.  *Half-Open:* Sau một khoảng thời gian (Reset Timeout), cho phép vài request đi qua để "thăm dò". Nếu thành công -> Đóng cầu dao. Nếu lỗi -> Mở lại.

*Ví dụ Opossum:*
```javascript
const CircuitBreaker = require('opossum');

const options = {
  timeout: 3000, // Nếu quá 3s thì tính là lỗi
  errorThresholdPercentage: 50, // Lỗi > 50% thì mở cầu dao
  resetTimeout: 30000 // Sau 30s thì thử lại (Half-Open)
};

const breaker = new CircuitBreaker(myAsyncFunction, options);
breaker.fire(params)
  .then(console.log)
  .catch(console.error); // Nếu Open, sẽ catch lỗi ngay lập tức
```

=== Bulkhead & Timeout Patterns

- *Timeout:* Không bao giờ để request treo vô hạn. Luôn đặt timeout cho mọi cuộc gọi ra ngoài (Database, API). Node.js default timeout HTTP rất lớn, cần set lại (ví dụ 5s).
- *Bulkhead:* Chia tài nguyên (Connection Pool) thành các phần riêng biệt.
    - If Service A calls Service B and is slow, it only consumes the connection pool for B.
    - Connection pool for Service C remains free.
    - -> Service C is not affected by Service B's failure.
    - Prevents cascading failure.