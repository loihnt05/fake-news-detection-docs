== Security & Auth <security_auth>

Bảo mật là ưu tiên hàng đầu. Trong Node.js, chúng ta cần bảo vệ cả tầng ứng dụng và tầng mạng.

=== JWT & OAuth2

==== JWT
- *Stateless Auth:* Server không lưu Session. Mọi thông tin (UserId, Role) nằm trong Token.
- *Cấu trúc:* Header.Payload.Signature.
- *Lưu ý:*
    - Không lưu thông tin nhạy cảm (Password) trong Payload.
    - Token cần có thời hạn ngắn (Access Token: 15p).
    - Dùng Refresh Token (thời hạn dài, lưu DB) để lấy Access Token mới.

==== OAuth2 Flows
- *Authorization Code Flow:* Chuẩn nhất cho Web App Server-side.
- *PKCE (Proof Key for Code Exchange):* Bắt buộc cho Mobile App và SPA (Single Page App) để chống chặn Code.
- *Client Credentials:* Dùng cho giao tiếp Machine-to-Machine (Service gọi Service).

=== Libraries

- *Passport.js:* Thư viện Auth phổ biến nhất. Hỗ trợ hàng trăm Strategy (Local, Google, Facebook, JWT).
- *Identity Provider (IdP):* Thay vì tự code Auth, nên dùng giải pháp có sẵn như *Keycloak*, *Auth0*, *Firebase Auth*. Chúng lo việc quản lý User, Reset Password, MFA, Social Login an toàn hơn tự làm.

=== Hardening

==== Rate Limiting
- Chống Brute Force password và DDOS.
- Thư viện: `express-rate-limit`, `nestjs-throttler`.
- Cấu hình: 100 request / 15 phút cho mỗi IP.

==== Input Validation
- "Never trust user input".
- Sử dụng `class-validator` (NestJS) hoặc `zod`, `joi`.
- Sanitize dữ liệu để chống XSS và NoSQL Injection.

==== Helmet & CORS
- *Helmet:* Middleware tự động set các HTTP Headers bảo mật (ẩn `X-Powered-By: Express`, bật HSTS, chống Clickjacking).
- *CORS (Cross-Origin Resource Sharing):* Chỉ cho phép các domain tin cậy (Frontend của mình) gọi API. Không dùng `Access-Control-Allow-Origin: *`.