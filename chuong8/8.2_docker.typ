== Docker <docker>

Docker đã tạo ra cuộc cách mạng trong việc triển khai phần mềm, giải quyết triệt để câu nói kinh điển của lập trình viên: *"Code chạy ngon trên máy tôi, sao lên server lại lỗi?"*.

=== Mô tả và Kiến trúc

Docker là một nền tảng mở cho phép phát triển, vận chuyển và chạy các ứng dụng trong các môi trường cô lập gọi là *Container*.

==== Kiến trúc Client-Server
- *Docker Daemon (`dockerd`):* Là process chạy ngầm trên Host OS. Nó chịu trách nhiệm nặng nề: quản lý images, containers, networks, volumes. Nó giao tiếp với Linux Kernel (Namespaces, Cgroups) để tạo container.
- *Docker Client (`docker` CLI):* Là công cụ dòng lệnh để người dùng gõ lệnh (`docker build`, `docker run`). Client gửi lệnh đến Daemon qua REST API (Unix Socket hoặc TCP).
- *Docker Registry (Docker Hub):* Kho lưu trữ tập trung các Docker Images.

=== Các khái niệm cốt lõi

==== Docker Image
- Là một template chỉ đọc (read-only template).
- Chứa mọi thứ cần thiết để chạy ứng dụng: Code, Runtime (JDK, Node), Libraries, Environment Variables, Config files.
- *Layered File System (UnionFS):* Image được xây dựng từ nhiều lớp chồng lên nhau.
    - Lớp 1: Ubuntu Base OS.
    - Lớp 2: Cài thêm Java.
    - Lớp 3: Copy file `.jar` vào.
    - Khi thay đổi code (Lớp 3), Docker chỉ cần build lại lớp 3, giữ nguyên Lớp 1 và 2. -> Tiết kiệm băng thông và thời gian build.

==== Docker Container
- Là một instance đang chạy (runnable instance) của Image.
- Khi khởi động Container, Docker thêm một lớp *Writable Layer* (Lớp ghi) lên trên cùng của các lớp Image Read-only. Mọi thay đổi dữ liệu trong lúc chạy đều nằm ở lớp Writable này. Khi xóa container, lớp này mất đi.

==== Dockerfile
Là file text chứa các chỉ dẫn (instructions) để build ra Image.

*Ví dụ Dockerfile chuẩn cho Node.js:*
```dockerfile
# 1. Base Image: Chọn môi trường nền (nhẹ nhất có thể)
FROM node:18-alpine

# 2. Workdir: Tạo thư mục làm việc
WORKDIR /app

# 3. Copy package.json trước để tận dụng Layer Caching
COPY package*.json ./

# 4. Install dependencies
RUN npm install --production

# 5. Copy source code (Đây là lớp hay thay đổi nhất)
COPY . .

# 6. Expose port
EXPOSE 3000

# 7. Command chạy app
CMD ["node", "server.js"]
```

=== Ưu điểm vượt trội

1.  *Tính nhất quán (Consistency):* Môi trường Dev, Test, Prod giống hệt nhau từng byte (vì cùng chạy từ 1 Image). Loại bỏ lỗi cấu hình môi trường.
2.  *Tốc độ:* Khởi động container chỉ tốn vài giây (so với VM tốn vài phút).
3.  *Mật độ cao (Density):* Trên cùng một phần cứng, có thể chạy hàng trăm container (so với chỉ vài chục VM).
4.  *Hỗ trợ CI/CD:* Dễ dàng tích hợp vào quy trình Jenkins/GitLab CI để build và test tự động.

=== Best Practices

==== Tối ưu Layer Caching
Thứ tự lệnh trong Dockerfile cực kỳ quan trọng.
- *Sai:* `COPY . .` rồi mới `RUN npm install`. -> Mỗi lần sửa 1 dòng code, Docker phải cài lại toàn bộ thư viện (lâu).
- *Đúng:* `COPY package.json` -> `RUN npm install` -> `COPY . .`. -> Sửa code không làm mất cache của lớp `npm install`.

==== Multi-stage Builds
Giúp giảm kích thước Image cuối cùng bằng cách loại bỏ các công cụ build (Compiler, Maven, source code C++).

*Ví dụ với Go:*
```dockerfile
# Stage 1: Build (Cần Go Compiler nặng nề)
FROM golang:1.20 AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp main.go

# Stage 2: Runtime (Chỉ cần file binary, dùng Alpine siêu nhẹ)
FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/myapp .
CMD ["./myapp"]
```
-> Kết quả: Image giảm từ 800MB (Golang) xuống còn 10MB (Alpine + Binary).

==== Không chạy với quyền Root
Mặc định container chạy với user `root`. Điều này rủi ro bảo mật (nếu hacker thoát khỏi container, họ có quyền root trên host).
-> Luôn tạo user thường và dùng lệnh `USER myuser` trong Dockerfile.

==== Handle PID 1
Process đầu tiên trong container có PID 1. Linux Kernel đối xử đặc biệt với PID 1 (không nhận tín hiệu SIGTERM mặc định).
-> Nếu app không xử lý SIGTERM, `docker stop` sẽ chờ 10s rồi kill mạnh (`SIGKILL`), gây lỗi dữ liệu.
-> Nên dùng `tini` làm init process (`ENTRYPOINT ["/sbin/tini", "--"]`) hoặc đảm bảo app xử lý Graceful Shutdown.