== Services & Dependency Injection / Middlewares <services_di>

Để xây dựng ứng dụng Node.js có khả năng bảo trì (maintainable) và mở rộng (scalable), việc quản lý sự phụ thuộc (dependencies) và luồng xử lý request (pipeline) là tối quan trọng.

=== Dependency Injection

Dependency Injection là một kỹ thuật thiết kế (Design Pattern) thực hiện nguyên lý Inversion of Control (IoC). Thay vì các class tự khởi tạo các đối tượng phụ thuộc (`new Service()`), chúng sẽ nhận các đối tượng này từ bên ngoài (thường là qua constructor).

==== NestJS Built-in DI Container
NestJS cung cấp một IoC Container cực kỳ mạnh mẽ.

*Cơ chế hoạt động:*
1.  *Registration:* Bạn khai báo class với Decorator `@Injectable()` và đăng ký nó vào mảng `providers` của Module.
2.  *Resolution:* Khi NestJS khởi tạo một Controller, nó quét Constructor xem Controller cần những Service nào.
3.  *Injection:* NestJS tự động tìm (hoặc tạo mới) instance của Service đó và đưa vào Controller.

*Các loại Scope:*
- *Singleton (Default):* Chỉ có 1 instance duy nhất của Service được tạo ra và dùng chung cho toàn bộ ứng dụng. Tối ưu bộ nhớ và hiệu năng. (Khuyên dùng 95% trường hợp).
- *Request:* Một instance mới được tạo ra cho mỗi HTTP Request. Sau khi request xong, instance bị hủy. Dùng khi cần lưu trữ thông tin riêng của request (ví dụ: request-id, user-context) bên trong service. *Lưu ý: Ảnh hưởng hiệu năng do GC.*
- *Transient:* Một instance mới được tạo ra mỗi lần nó được inject (dù trong cùng 1 request). Ít dùng.

==== DI trong Express/Fastify
Express không có DI Container tích hợp sẵn.
- *Cách thủ công:* Truyền service qua arguments khi khởi tạo Controller.
- *Thư viện ngoài:* Sử dụng `InversifyJS`, `Awilix` hoặc `Tsyringe` để đạt được tính năng tương tự NestJS.
- *Tại sao cần DI?* Để dễ dàng Mocking khi viết Unit Test. Nếu bạn `import database from './db'`, bạn không thể thay thế DB thật bằng DB giả khi test.

=== Middleware Pattern

Middleware là các hàm được thực thi ở giữa quá trình nhận Request và gửi Response. Nó giống như một dây chuyền sản xuất (Pipeline). Request đi qua từng chốt chặn, nếu qua được hết thì mới đến Controller xử lý chính.

==== Định nghĩa và Ứng dụng
Middleware có quyền truy cập vào `Request` object, `Response` object và hàm `next()`.

*Các ứng dụng phổ biến:*
1.  *Logging:* Ghi lại thông tin request (Method, URL, IP, Time). Thư viện phổ biến: `morgan` (Express), `pino-http` (Fastify).
2.  *Authentication:* Kiểm tra xem request có token hay không. Nếu không -> Trả lỗi 401 ngay lập tức, không cho đi tiếp.
3.  *Body Parsing:* Đọc luồng dữ liệu (stream) từ request, parse thành JSON và gắn vào `req.body`.
4.  *Error Handling:* Middleware bắt lỗi toàn cục (Global Exception Filter). Nơi duy nhất tập trung xử lý `try-catch` cho toàn bộ app.

==== Global vs Per-route Middleware

- *Global Middleware:* Áp dụng cho TẤT CẢ request. Ví dụ: `Helmet` (bảo mật header), `Cors` (cho phép tên miền khác gọi API), `RateLimiter` (chống DDOS).
- *Per-route Middleware:* Chỉ áp dụng cho một vài endpoint cụ thể. Ví dụ: Middleware `UploadFile` chỉ dùng cho API `/upload`.

==== Thứ tự quan trọng
Thứ tự khai báo middleware quyết định logic chương trình.
- *Sai lầm thường gặp:* Đặt Error Handler Middleware lên đầu. -> Nó sẽ không bắt được lỗi vì request chưa chạy qua logic nào cả.
- *Best Practice:*
    1.  Security Middlewares (Helmet, CORS).
    2.  Parser Middlewares (Body Parser).
    3.  Logging Middlewares.
    4.  Auth Middlewares (nếu global).
    5.  Routes / Controllers.
    6.  *Error Handling Middleware (Luôn nằm cuối cùng).*

=== Best Practices cho Service Layer

Service Layer là nơi chứa "Business Logic" thuần túy. Nó *không nên biết* về HTTP (không nhận `req`, `res`).

- *Input:* DTO (Data Transfer Object) hoặc tham số thường.
- *Output:* Entity, Model hoặc Value Object.
- *Lợi ích:* Service này có thể được tái sử dụng bởi Controller (HTTP), Gateway (WebSocket), hoặc Cron Job (Scheduler) mà không cần sửa đổi logic.
- *Fat Service, Skinny Controller:* Controller chỉ nên làm nhiệm vụ validate input và gọi Service. Đừng viết logic `if-else` phức tạp trong Controller.