== Clean Architecture <clean_architecture>

Một dự án phần mềm không chết vì công nghệ cũ, mà chết vì code quá rối rắm (Spaghetti code) khiến không ai dám sửa. Clean Architecture (của Uncle Bob) là liều thuốc giải.

=== Các tầng kiến trúc

Mục tiêu: Tách biệt mối quan tâm (Separation of Concerns). Tầng bên trong không được phụ thuộc vào tầng bên ngoài.

#figure(image("../images/pic18.png"), caption: [Clean Architecture Diagram])

==== Domain Layer
- *Vị trí:* Trong cùng.
- *Nội dung:* Chứa các *Entities* (Quy tắc nghiệp vụ cốt lõi doanh nghiệp) và *Interfaces* (Repository Ports).
- *Đặc điểm:* Không phụ thuộc vào bất kỳ framework nào (Không có NestJS, không có TypeORM, không có Express). Chỉ là thuần TypeScript class/interface.
- *Ví dụ:* Class `Order` có hàm `calculateTotal()` (Logic tính tiền không bao giờ thay đổi dù dùng DB nào).

==== Use Cases / Application Layer
- *Vị trí:* Bao quanh Domain.
- *Nội dung:* Chứa các *Application Services* (Logic nghiệp vụ ứng dụng). Thực hiện các kịch bản sử dụng (Use Cases).
- *Đặc điểm:* Điều phối luồng dữ liệu. Lấy data từ Repository -> Gọi Domain Entity xử lý -> Lưu lại.
- *Ví dụ:* `CreateOrderService`.

==== Interface Adapters
- *Vị trí:* Lớp vỏ bên ngoài.
- *Controllers (Presentation):* Nhận HTTP request, gọi Use Case.
- *Repositories (Infrastructure):* Triển khai các Interface của Domain Layer bằng công nghệ cụ thể (TypeORM, Prisma).
- *External Services:* Gọi API bên thứ 3 (Stripe, SendGrid).

=== Ví dụ cấu trúc thư mục

```text
src/
├── domain/                  # Lớp Domain (KHÔNG phụ thuộc framework)
│   ├── models/              # Entities (e.g., User.ts)
│   ├── repositories/        # Interfaces (e.g., IUserRepository.ts)
│   └── exceptions/          # Domain Exceptions
├── application/             # Lớp Ứng dụng
│   ├── use-cases/           # (e.g., CreateUserUseCase.ts)
│   └── dtos/                # Data Transfer Objects
├── infrastructure/          # Lớp Hạ tầng (Phụ thuộc framework/lib)
│   ├── database/            # Prisma/TypeORM setup
│   ├── repositories/        # UserRepositoryImpl.ts (Implements IUserRepository)
│   ├── services/            # EmailService (SendGrid)
│   └── controllers/         # UserController.ts (NestJS Controllers)
└── main.ts                  # Entry point
```

=== Testing Strategies

Code không có test là code nợ (Legacy Code).

==== Unit Test
- *Đối tượng:* Test từng hàm/class riêng lẻ (chủ yếu là Domain & Use Cases).
- *Nguyên tắc:* Cô lập hoàn toàn (Isolated). Không gọi DB thật, không gọi API thật.
- *Mocking:* Sử dụng Mock Object để giả lập các dependencies.
    - *Ví dụ:* Khi test `CreateOrderService`, ta mock `IOrderRepository`. Khi gọi `repo.save()`, ta giả vờ nó thành công mà không cần chạy DB.
- *Tốc độ:* Cực nhanh (mili-giây). Chạy hàng nghìn test mỗi lần commit.

==== E2E Test
- *Đối tượng:* Test toàn bộ luồng từ ngoài vào trong (Từ HTTP Request -> Controller -> Service -> DB -> Response).
- *Nguyên tắc:* Dùng môi trường thật (hoặc gần thật nhất).
    - Sử dụng *Docker Containers* (Testcontainers) để dựng một DB Postgres sạch cho mỗi lần test.
- *Độ tin cậy:* Cao nhất, nhưng chạy chậm.

==== Test Pyramid
- *Unit Tests:* Nhiều nhất (70%). Rẻ, nhanh, cover logic chi tiết.
- *Integration Tests:* Trung bình (20%). Test sự kết hợp giữa Service và DB.
- *E2E Tests:* Ít nhất (10%). Test các luồng chính (Critical Path) để đảm bảo hệ thống chạy đúng.

==== Công cụ
- *Jest:* Framework test mặc định của NestJS. Mạnh mẽ, "batteries-included" (có sẵn runner, assertion, mocking).
- *Vitest:* Nhanh hơn Jest, tương thích tốt với Vite.
- *Supertest:* Dùng để gửi HTTP Request giả lập trong E2E test.