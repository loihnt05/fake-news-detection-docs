Chương 6: Distributed Transactions
6.1. Tổng quan về Transaction

Định nghĩa
Thuộc tính ACID

Atomicity
Consistency
Isolation
Durability


Giao dịch phân tán

6.2. Two-Phase Commit (2PC)

Mô tả
Giai đoạn 1: Chuẩn bị
Giai đoạn 2: Cam kết
Nhược điểm

6.3. Three-Phase Commit (3PC)

Mô tả
Giai đoạn 1: CanCommit
Giai đoạn 2: PreCommit
Giai đoạn 3: DoCommit
Nhược điểm

6.4. Saga

Mô tả
Các phương pháp triển khai

Choreography
Orchestration


Giao dịch bù trừ

6.5. So sánh Two-phase commit/Three-phase commit và Saga

Bảng so sánh