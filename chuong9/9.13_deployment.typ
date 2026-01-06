== Containerization & Deployment <deployment>

=== Dockerfile Best Practices

Tạo Docker Image nhỏ gọn, an toàn và build nhanh.

==== Multistage Build
```dockerfile
# Stage 1: Build
FROM node:23-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:23-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER node
CMD ["node", "dist/main.js"]
```

==== Small Base Images
- Dùng `alpine` (nhẹ nhất) hoặc `distroless` (an toàn nhất, không có shell).

==== Non-root User
- Mặc định container chạy quyền root. Rất nguy hiểm.
- Luôn dùng `USER node` (user có sẵn trong image node).

==== Caching
- Copy `package.json` và chạy `npm install` trước khi copy source code.
- Giúp tận dụng Docker Layer Cache khi chỉ sửa code mà không sửa dependency.

=== Kubernetes Deployment Patterns

- *Deployment:* Quản lý Stateless Apps (API). Đảm bảo số lượng Pod (Replicas).
- *StatefulSet:* Quản lý Stateful Apps (DB, Redis). Đảm bảo thứ tự và Volume bền vững.
- *HPA (Horizontal Pod Autoscaler):* Tự động tăng số lượng Pod khi CPU/RAM vượt ngưỡng.

=== Helm Charts
- Đóng gói toàn bộ file YAML k8s (Deployment, Service, Ingress, ConfigMap) thành một gói cài đặt.
- Dễ dàng quản lý cấu hình cho các môi trường (Dev/Staging/Prod) thông qua `values.yaml`.

=== Serverless Options

- *AWS Lambda:* Chạy code Node.js theo sự kiện (HTTP, S3, SQS).
- *Ưu:* Không tốn tiền khi không chạy (Scale to Zero). Không cần quản lý server.
- *Trade-offs:* Cold Start (chậm ở request đầu tiên). Giới hạn thời gian chạy (15 phút). Khó kết nối DB quan hệ (cần dùng RDS Proxy).