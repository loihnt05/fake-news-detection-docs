Chương 3: Caching
3.1. Tổng quan về caching

Khái niệm
Mục tiêu chính
Các chỉ số quan trọng
Trade-offs

3.2. Các pattern trong caching
3.2.1. Local cache

Mô tả
Khi dùng
Ưu điểm
Nhược điểm / rủi ro
Best practices

3.2.2. Distributed cache

Mô tả
Khi dùng
Ưu điểm
Nhược điểm / rủi ro
Triển khai & lưu ý

3.2.3. Reverse proxy cache

Mô tả
Khi dùng
Ưu/nhược
Kỹ thuật quan trọng

3.2.4. Sidecar cache

Mô tả
Khi dùng
Ưu/nhược
Triển khai

3.2.5. Reverse proxy sidecar cache

Mô tả
Khi dùng
Ưu/nhược
Best practices để phối hợp nhiều tầng

3.3. Làm trống cache (Cache eviction)

Tại sao phải evict?
Kịch bản kích hoạt eviction
Các thuật toán eviction phổ biến

LRU (Least Recently Used)
LFU (Least Frequently Used)
FIFO (First In First Out)
Random
TTL / Time-based eviction
ARC / SLRU / CLOCK
Cost-aware / Size-aware eviction


Cách thực thi eviction trong các hệ thống thực tế
Vấn đề thường gặp & countermeasures

Cache stampede
Cache avalanche
Hot key
Stale reads


Best practices tóm tắt cho eviction

3.4. Các pattern truy cập trong caching
3.4.1. Cache-aside

Khái niệm
Đặc điểm
Ưu điểm
Nhược điểm
Ví dụ

3.4.2. Read-through

Khái niệm
Đặc điểm
Ưu điểm
Nhược điểm
Ví dụ

3.4.3. Write-through

Khái niệm
Đặc điểm
Ưu điểm
Nhược điểm
Ví dụ

3.4.4. Write-back (Write-behind)

Khái niệm
Đặc điểm
Ưu điểm
Nhược điểm
Ví dụ
So sánh các pattern (bảng tổng hợp)