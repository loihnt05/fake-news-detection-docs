Chương 4: Microservices
4.1. Miêu tả microservice

Định nghĩa ngắn gọn
Đặc điểm chính
Lợi ích chính
Lưu ý khi áp dụng

4.2. Phương thức giao tiếp giữa các service
4.2.1. Giao tiếp đồng bộ (Synchronous)

HTTP/REST
gRPC / HTTP/2
GraphQL
Ưu / Nhược
Best practices

4.2.2. Giao tiếp không đồng bộ (Asynchronous)

Message Queue
Event Streaming
Pub/Sub
Mẫu sử dụng
Ưu / Nhược
Vấn đề cần chú ý

4.2.3. Patterns & Hybrid

Request–Reply over Message Bus
CQRS
SAGA pattern

Choreography
Orchestration


API Gateway / BFF

4.2.4. Các giải pháp hạ tầng hỗ trợ giao tiếp

Service Discovery
Sidecar / Service Mesh
Schema Registry
Queue / Stream Broker

4.2.5. Observability liên quan giao tiếp

Distributed tracing
Centralized logging
Metrics & alerting
Contract testing

4.3. Khuyết điểm của microservice
4.3.1. Complexity vận hành
4.3.2. Phân tán → mạng, latency, partial failures
4.3.3. Khó debug & test
4.3.4. Consistency và giao dịch phân tán
4.3.5. Overhead tài nguyên & chi phí
4.3.6. Phiên bản hóa API & backward compatibility
4.3.7. Yêu cầu tổ chức & kỹ năng
4.3.8. Bảo mật (attack surface lớn)
4.3.9. Duplicated logic & dữ liệu