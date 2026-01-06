== CI/CD & Release strategies <cicd>

Tự động hóa quy trình từ lúc commit code đến lúc chạy trên Production.

=== Pipelines

Một pipeline tiêu chuẩn gồm các bước:
1.  *Build:* Compile TypeScript, bundle code.
2.  *Test:* Chạy Unit Test, Linting. Nếu fail -> Dừng ngay.
3.  *Image:* Build Docker Image.
4.  *Push:* Đẩy Image lên Registry (Docker Hub, ECR).
5.  *Deploy:* Cập nhật K8s Deployment để dùng Image mới.

#figure(image("../images/pic20.png"), caption: [CI/CD Pipeline Diagram])

=== Kubernetes Release Strategies

==== Rolling Updates
- K8s thay thế lần lượt từng Pod cũ bằng Pod mới.
- *Ưu:* Zero Downtime.
- *Nhược:* Khó rollback tức thì.

==== Blue/Green Deployment
- Dựng một môi trường mới (Green) song song với cũ (Blue).
- Switch traffic 100% sang Green sau khi test xong.
- *Ưu:* Rollback tức thì (chỉ cần switch lại).
- *Nhược:* Tốn gấp đôi tài nguyên.

==== Canary Deployment
- Chuyển một phần nhỏ traffic (ví dụ 5%) sang phiên bản mới.
- Theo dõi lỗi. Nếu ổn định thì tăng dần lên 100%.
- *Ưu:* An toàn nhất. Giảm thiểu rủi ro cho user thật.

=== DB Migrations

Chạy migration lúc nào?
- *Cách 1:* Job InitContainer trong K8s Pod (Chạy trước khi app start).
- *Cách 2:* Một bước riêng trong CI/CD Pipeline (Trước khi deploy app).
- *Lưu ý:* Migration phải *Backward Compatible* (Tương thích ngược). Ví dụ: Không được rename column mà code cũ vẫn đang query column đó. Hãy thêm column mới -> Deploy Code -> Copy data -> Xóa column cũ.