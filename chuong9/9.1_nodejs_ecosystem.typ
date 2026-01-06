== Node.js & Hệ sinh thái <nodejs_ecosystem>

=== Tổng quan Node.js

Node.js v23 đánh dấu một bước trưởng thành quan trọng của nền tảng này, tập trung vào hiệu suất, tính tương thích tiêu chuẩn web (Web Standards) và trải nghiệm lập trình viên (Developer Experience).

#figure(image("../images/pic16.jpg"), caption: [Node.js Backend Architecture Diagram])

==== Key Features

1.  *Hỗ trợ ESM mặc định:*
    - Node.js v23 tiếp tục hoàn thiện khả năng hỗ trợ ESM. Việc sử dụng `import` và `export` giờ đây hoạt động mượt mà, giảm thiểu các lỗi "Dual Package Hazard" khi làm việc với các thư viện lai (CJS/ESM).
    - Hỗ trợ `import.meta.dirname` và `import.meta.filename` giúp thay thế hoàn toàn `__dirname` và `__filename` của CommonJS.
    - Top-level `await`: Cho phép sử dụng `await` ngay ngoài cùng của file module mà không cần bọc trong `async function`.

2.  *Cập nhật V8 Engine:*
    - Node.js v23 tích hợp phiên bản mới nhất của V8 JavaScript Engine từ Google.
    - *Maglev Compiler:* Một trình biên dịch tầm trung (mid-tier compiler) mới, giúp tăng tốc độ khởi động ứng dụng và tối ưu hóa code nhanh hơn so với TurboFan trong các tác vụ ngắn hạn.
    - Hỗ trợ các tính năng JS mới nhất: `Set` methods (intersection, union, difference), `Array.fromAsync`, và tối ưu hóa Regex.

3.  *Built-in APIs mới:*
    - *`node:sqlite`:* Module tích hợp sẵn để làm việc với SQLite database. Không cần cài `sqlite3` hay `better-sqlite3` native modules (tránh lỗi build `node-gyp`).
    - *`node:test` (Test Runner):* Framework kiểm thử tích hợp sẵn, hỗ trợ mocking, code coverage (`--experimental-test-coverage`), thay thế dần Jest/Mocha cho các dự án nhỏ và vừa.
    - *`node:websocket`:* Client WebSocket tích hợp (experimental), tuân thủ chuẩn Web API.
    - *`env` file support:* Node.js giờ đây có thể tự load file `.env` thông qua cờ `--env-file=.env`, loại bỏ nhu cầu cài đặt thư viện `dotenv`.

4.  *Hỗ trợ TypeScript:*
    - Node.js v23 có thể chạy trực tiếp file `.ts` (với cú pháp TypeScript cơ bản, không cần `tsc` cho các enum/decorators phức tạp) thông qua `--experimental-strip-types`. Nó hoạt động bằng cách xóa bỏ các type annotation trước khi chạy, giúp tăng tốc quy trình dev (fast feedback loop).

==== Kiến trúc đơn luồng & Event Loop
- Node.js vẫn giữ kiến trúc *Single-Threaded Event Loop*.
- Sử dụng *libuv* để xử lý các tác vụ bất đồng bộ (Async I/O) như File System, Network DNS.
- *Worker Threads:* Cho phép chạy các tác vụ CPU-bound song song, nhưng không chia sẻ bộ nhớ (share memory) như Multithreading của Java/C++, mà giao tiếp qua Message Passing.

=== Khi nào chọn Node.js cho Backend?

Việc lựa chọn công nghệ phụ thuộc vào đặc thù bài toán (Workload).

==== I/O-Bound Applications
Đây là "sân nhà" của Node.js.
- *Đặc điểm:* Ứng dụng dành phần lớn thời gian để chờ Database trả về kết quả, chờ gọi API bên thứ 3, hoặc đọc ghi file.
- *Tại sao Node tốt?* Kiến trúc Non-blocking I/O cho phép một thread duy nhất xử lý hàng chục nghìn kết nối đồng thời (Concurrent Connections) trong khi chúng đang "chờ". Bộ nhớ tiêu thụ (Memory footprint) rất thấp so với mô hình Thread-per-request của Java/Tomcat cũ.
- *Ví dụ:* API Gateway, Web Server phục vụ static files, Ứng dụng CRUD thông thường, Real-time Chat.

==== Microservices & Serverless
- *Khởi động nhanh:* Node.js khởi động trong vài chục mili-giây, rất phù hợp cho Serverless (AWS Lambda) để giảm thiểu Cold Start latency.
- *Hệ sinh thái NPM:* Kho thư viện khổng lồ giúp phát triển nhanh (Rapid Prototyping). JSON là công dân hạng nhất (First-class citizen), giúp việc giao tiếp giữa các service (thường dùng JSON REST/Message) cực kỳ tự nhiên.

==== Real-time Applications
- WebSocket (Socket.io, uWebSockets.js) hoạt động cực tốt trên Node.js.
- Dễ dàng duy trì hàng ngàn kết nối dài hạn (Long-polling/Streaming) cho các ứng dụng chứng khoán, game online, dashboard thời gian thực.

==== Khi nào KHÔNG nên dùng Node.js?
- *CPU-Bound Tasks:* Mã hóa video (Video Encoding), xử lý ảnh phức tạp, tính toán ma trận, AI/ML Training.
- *Lý do:* Event Loop bị chặn (block) bởi các tác vụ tính toán nặng. Một request tính toán lâu sẽ làm treo toàn bộ server, khiến các request khác không được xử lý.
- *Giải pháp:* If still wanting to use Node, push these tasks to *Worker Threads* or separate into a microservice written in Go/Rust/Python.

=== Tương lai và Xu hướng
- *Deno & Bun:* Node.js đang chịu sức ép cạnh tranh từ Bun (tốc độ cực nhanh) và Deno (bảo mật mặc định). Điều này thúc đẩy Node.js cải tiến hiệu năng mạnh mẽ trong các phiên bản v22/v23.
- *Wasm:* Tích hợp Wasm vào Node.js để chạy các module hiệu năng cao (Rust/C++) một cách an toàn.