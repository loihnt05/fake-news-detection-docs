Chương 5: Service discovery & API Gateway
5.1. Phân loại Service Discovery

Giới thiệu chung

5.1.1. Client-side Discovery

Mô tả
Ví dụ
Ưu điểm
Nhược điểm

5.1.2. Server-side Discovery

Mô tả
Ví dụ
Ưu điểm
Nhược điểm

5.2. Phân loại hình thức register
5.2.1. Self-registration

Mô tả
Ví dụ
Ưu điểm
Nhược điểm

5.2.2. Third-party registration

Mô tả
Ví dụ
Ưu điểm
Nhược điểm

5.3. Sử dụng service
5.3.1. Direct

Mô tả
Ví dụ
Ưu điểm
Nhược điểm

5.3.2. Composite UI

Mô tả
Cách implement

Server-side composition
Client-side composition


Ưu điểm
Nhược điểm

5.3.3. API Gateway

Mô tả
Chức năng

Request routing
API composition


Lựa chọn implement trong Node.js
Ưu điểm
Nhược điểm

5.4. Envoy
5.4.1. Giới thiệu

Tổng quan
Điểm khác biệt
Điểm mạnh

5.4.2. Kiến trúc

Listeners
Filter chains

Listener filters
Network filters
HTTP filters


HTTP Connection Manager
Routes
Clusters
Endpoints
Thread model
xDS APIs
Integration với Node.js