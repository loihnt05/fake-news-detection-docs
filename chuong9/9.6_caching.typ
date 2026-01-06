== Caching <caching>

Caching là chiến lược tối ưu hóa hiệu năng quan trọng nhất trong các hệ thống I/O-bound như Node.js.

=== Local Cache

Dữ liệu được lưu trực tiếp trong RAM của tiến trình Node.js.

- *Thư viện:* `lru-cache`, `node-cache`.
- *Cơ chế LRU:* Khi bộ nhớ đầy, cache sẽ tự động xóa các mục ít được truy cập nhất để nhường chỗ cho mục mới.
- *Ưu điểm:* Tốc độ truy xuất cực nhanh (không có độ trễ mạng).
- *Nhược điểm:*
    - Không chia sẻ được giữa các tiến trình (Nếu chạy PM2 cluster hoặc nhiều Pods k8s, mỗi process có cache riêng -> Dữ liệu không nhất quán).
    - Giới hạn bởi RAM của server. Lưu nhiều quá gây Crash ứng dụng (OOM).
- *Use case:* Cache cấu hình tĩnh, Token public key, danh sách tỉnh thành (dữ liệu ít thay đổi và kích thước nhỏ).

=== Distributed Cache: Redis

Dữ liệu được lưu trong một server Redis riêng biệt, chia sẻ chung cho toàn bộ các instances của ứng dụng.

- *Thư viện:* `ioredis` (khuyên dùng), `redis` (node-redis).
- *Đặc điểm:*
    - Lưu trữ Key-Value trong RAM.
    - Hỗ trợ TTL để tự động xóa dữ liệu cũ.
    - Hỗ trợ cấu trúc dữ liệu phức tạp: List, Set, Hash, Sorted Set (dùng cho Leaderboard).
- *Ưu điểm:* Nhất quán dữ liệu giữa các microservices. Bền bỉ (Persistence) hơn Local Cache.
- *Nhược điểm:* Tốn thêm 1 network hop (độ trễ ~1ms).

=== Reverse Proxy Cache

Cache ở tầng HTTP, đứng trước Web Server (Nginx, Varnish, CDN).
- Cache toàn bộ HTML page hoặc JSON response dựa trên URL.
- Giảm tải tuyệt đối cho Backend Server vì request không hề chạm tới Node.js.

=== Caching Patterns

==== Cache-aside
1.  Ứng dụng nhận request.
2.  Kiểm tra trong Redis xem có dữ liệu không.
3.  Nếu có (Hit) -> Trả về ngay.
4.  Nếu không (Miss) -> Query Database -> Lưu vào Redis (kèm TTL) -> Trả về.
- *Ưu:* Hệ thống vẫn chạy được nếu Redis chết (fallback về DB). Dữ liệu trong cache là dữ liệu "được dùng nhiều".
- *Nhược:* Lần đầu truy cập sẽ chậm (Cache miss). Dữ liệu có thể bị cũ (Stale) nếu DB đổi mà Cache chưa hết hạn.

==== Write-through
1.  Khi cập nhật dữ liệu, Ứng dụng ghi vào Cache trước.
2.  Sau đó ghi vào DB.
3.  Cả 2 thành công mới trả về Client.
- *Ưu:* Cache luôn tươi mới (Fresh).
- *Nhược:* Ghi chậm (phải ghi 2 nơi). Dữ liệu ít dùng cũng bị tống vào cache (lãng phí RAM).

==== Write-behind
1.  Ứng dụng ghi vào Cache và trả về Success ngay lập tức.
2.  Một tiến trình nền (Async) sẽ đồng bộ dữ liệu từ Cache xuống DB sau.
- *Ưu:* Tốc độ ghi cực nhanh. Giảm tải cho DB (gom nhiều write thành 1 batch).
- *Nhược:* Rủi ro mất dữ liệu nếu Cache Server sập trước khi kịp sync xuống DB.

=== Ví dụ triển khai
NestJS cung cấp `CacheModule` tích hợp sẵn.

```typescript
// app.module.ts
CacheModule.register({
  store: redisStore,
  host: 'localhost',
  port: 6379,
  ttl: 600, // 10 phút
});

// service.ts
constructor(@Inject(CACHE_MANAGER) private cacheManager: Cache) {}

async getUser(id: string) {
  const cachedUser = await this.cacheManager.get(id);
  if (cachedUser) return cachedUser;

  const user = await this.db.findUser(id);
  await this.cacheManager.set(id, user);
  return user;
}
```