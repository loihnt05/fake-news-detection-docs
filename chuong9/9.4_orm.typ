== ORM / Database access <orm_database>

Việc tương tác với cơ sở dữ liệu là phần cốt lõi của mọi ứng dụng Backend. Trong Node.js, chúng ta có nhiều lựa chọn từ Query Builder thô sơ đến các ORM (Object-Relational Mapping) hiện đại.

=== Các thư viện phổ biến

==== Prisma
Prisma hiện đang là "ngôi sao sáng" trong cộng đồng Node.js/TypeScript.
- *Đặc điểm:* Không dùng Class/Decorator như TypeORM. Prisma sử dụng một file `schema.prisma` riêng để định nghĩa Database Schema. Sau đó, nó dùng `prisma generate` để sinh ra một Client (SDK) có Type-safe tuyệt đối dựa trên schema đó.
- *Ưu điểm:*
    - *Type-safety:* Tự động gợi ý code (Intellisense) cực xịn. Biết chính xác trường nào null, quan hệ nào được include.
    - *DX:* Cực tốt. Query API trực quan (`findMany`, `create`, `update`).
    - *Performance:* Sử dụng Rust binary engine bên dưới để xử lý query, khá nhanh.
- *Nhược điểm:* Khó tùy biến query SQL thô phức tạp. Cold start hơi chậm trong Serverless (đã cải thiện).

==== TypeORM
Lựa chọn mặc định của NestJS trong nhiều năm qua.
- *Đặc điểm:* Lấy cảm hứng từ Hibernate (Java). Sử dụng Class và Decorator (`@Entity`, `@Column`) để ánh xạ bảng DB.
- *Pattern:* Hỗ trợ cả *Active Record* (Entity tự có hàm `save()`) và *Data Mapper* (Dùng Repository để lưu Entity).
- *Ưu điểm:* Quen thuộc với dân Java/C\#. Hỗ trợ nhiều DB.
- *Nhược điểm:* Maintainer chậm update. Hệ thống type của TypeScript đôi khi không cover hết được các quan hệ phức tạp, dễ gây lỗi runtime.

==== Sequelize / Objection / Drizzle
- *Sequelize:* ORM già cỗi nhất. Dùng Promise-based. Hỗ trợ tốt nhưng cú pháp hơi rườm rà, TypeScript support kém hơn Prisma/TypeORM.
- *Objection.js:* Được xây dựng trên nền *Knex.js* (Query Builder). Nó không hẳn là ORM full-fledged mà là một lớp Model Wrapper. Cực kỳ mạnh mẽ và linh hoạt, ít "magic" hơn TypeORM.
- *Drizzle ORM:* "Ngôi sao mới nổi". Tập trung vào triết lý: "If you know SQL, you know Drizzle".
    - Siêu nhẹ (Zero dependency).
    - Không sinh ra code runtime nặng nề.
    - Type-safe chuẩn chỉ.
    - Khởi động tức thì -> Vua của Serverless.

=== So sánh chi tiết

#table(
  columns: (1fr, 1fr, 1fr, 1fr),
  inset: 5pt,
  align: horizon,
  table.header(
    [*Tiêu chí*], [*Prisma*], [*TypeORM*], [*Drizzle*]
  ),
  [Cách tiếp cận], [Schema-first (DSL)], [Code-first (Decorators)], [Code-first (SQL-like)],
  [Type Safety], [Tuyệt đối (Generated)], [Tốt (Generic)], [Tuyệt đối (Inference)],
  [SQL Control], [Thấp (Abstraction cao)], [Trung bình], [Cao (Gần với SQL)],
  [Migrations], [Prisma Migrate (Tốt)], [TypeORM CLI (Khá)], [Drizzle Kit (Tốt)],
  [Performance], [Khá (Rust Engine)], [Trung bình], [Rất cao (Lightweight)]
)

=== Database Migrations

Code thay đổi -> DB Schema cũng phải thay đổi (thêm cột, xóa bảng). Migration là công cụ để versioning DB Schema.

- *Prisma Migrate:*
    1. Sửa file `schema.prisma`.
    2. Chạy `prisma migrate dev --name add_user_table`.
    3. Prisma sinh ra file SQL migration và tự động chạy vào DB.
- *TypeORM Migration:*
    1. Sửa Entity Class.
    2. Chạy lệnh generate migration. TypeORM so sánh Entity hiện tại với DB thực tế để sinh ra file migration (đôi khi không chính xác 100%, cần review kỹ).

*Best Practice:*
- Không bao giờ sửa trực tiếp vào DB Production.
- Luôn chạy migration trong CI/CD pipeline trước khi deploy code mới.
- Backup dữ liệu trước khi chạy migration có tính chất phá hủy (DROP TABLE, ALTER COLUMN).