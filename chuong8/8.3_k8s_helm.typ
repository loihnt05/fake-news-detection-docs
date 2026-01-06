== Kubernetes và Helm <k8s_helm>

Nếu Docker là những viên gạch, thì Kubernetes là kiến trúc sư và công nhân xây dựng để tạo nên tòa nhà chọc trời.

=== Kubernetes

Kubernetes (K8s) là một hệ thống mã nguồn mở dùng để tự động hóa việc triển khai, mở rộng và quản lý các ứng dụng container hóa. Được Google phát triển dựa trên 15 năm kinh nghiệm chạy hệ thống Borg.

==== Kiến trúc tổng quan
1.  *Control Plane (Master Node):* Bộ nào điều khiển.
    - *API Server:* Cổng giao tiếp duy nhất (REST API). Mọi lệnh `kubectl` đều gửi vào đây.
    - *Etcd:* Database key-value lưu trữ toàn bộ trạng thái của cluster (như số lượng pod, config).
    - *Scheduler:* Quyết định xem Pod mới sẽ được đặt lên Node nào (dựa trên RAM/CPU còn trống).
    - *Controller Manager:* Vòng lặp điều khiển (Control Loop) để đảm bảo trạng thái thực tế khớp với trạng thái mong muốn (Desired State).

2.  *Worker Nodes:* Nơi các ứng dụng thực sự chạy.
    - *Kubelet:* Agent chạy trên mỗi node, nhận lệnh từ API Server và điều khiển Docker (hoặc Containerd) để chạy container.
    - *Kube-proxy:* Quản lý quy tắc mạng (iptables), giúp các Pod giao tiếp được với nhau.
    - *Container Runtime:* Phần mềm chạy container (Docker, Containerd, CRI-O).

#figure(image("../images/pic15.jpg"), caption: [Kubernetes Architecture Diagram])

==== Các đối tượng chính

1.  *Pod:*
    - Đơn vị nhỏ nhất trong K8s.
    - Một Pod chứa 1 hoặc nhiều container (thường là 1 container chính + sidecar).
    - Các container trong cùng 1 Pod chia sẻ chung Network IP và Storage Volume.
    - *Lưu ý:* Pod là *mortal* (dễ chết). Nếu Node chết, Pod chết theo và không tự sống lại.

2.  *Deployment:*
    - Quản lý Pod. Giúp Pod "bất tử".
    - Bạn khai báo: "Tôi muốn luôn có 3 bản sao (replicas) của Nginx".
    - Deployment sẽ tạo ra *ReplicaSet*. ReplicaSet sẽ tạo ra 3 Pods.
    - Nếu 1 Pod chết, Deployment tự động tạo Pod mới thay thế (Self-healing).
    - Hỗ trợ *Rolling Update*: Update code mới từ từ (mỗi lần 1 pod) để không gây downtime.

3.  *Service:*
    - Vì IP của Pod thay đổi liên tục, Service tạo ra một địa chỉ IP ảo (ClusterIP) cố định để truy cập vào nhóm Pod.
    - *ClusterIP:* Chỉ truy cập nội bộ cluster.
    - *NodePort:* Mở port trên tất cả Worker Node (ví dụ port 30001).
    - *LoadBalancer:* Yêu cầu Cloud Provider (AWS/GCP) cấp một LB vật lý trỏ vào Service.

4.  *ConfigMap & Secret:*
    - Tách biệt cấu hình khỏi Code (12-Factor App).
    - *ConfigMap:* Lưu cấu hình dạng text (file `.env`, `nginx.conf`).
    - *Secret:* Lưu dữ liệu nhạy cảm (Password DB, Certificate) dạng Base64 encoded (có thể mã hóa thêm).
    - Pod có thể đọc chúng dưới dạng Biến môi trường (ENV) hoặc Mount thành File.

=== Helm

Quản lý hàng trăm file YAML của K8s (`deployment.yaml`, `service.yaml`, `ingress.yaml`) rất cực khổ và dễ sai sót. Helm sinh ra để giải quyết việc này.

==== Mô tả
Helm giống như `apt` hay `yum` hay `npm` nhưng dành cho Kubernetes. Nó đóng gói tất cả tài nguyên K8s cần thiết cho 1 ứng dụng vào một gói duy nhất gọi là *Chart*.

#figure(image("../images/pic23.png"), caption: [Helm Chart Architecture])

==== Cấu trúc Helm Chart
```text
mychart/
  Chart.yaml          # Thông tin về chart (tên, version)
  values.yaml         # Các giá trị cấu hình mặc định
  templates/          # Chứa các file YAML mẫu (dùng Go Template)
    deployment.yaml
    service.yaml
```

*Cơ chế Template:*
Trong `deployment.yaml` của Helm, thay vì hardcode `image: nginx:1.14`, ta viết:
`image: {{ .Values.image.repository }}:{{ .Values.image.tag }}`

Khi cài đặt, Helm sẽ lấy giá trị từ `values.yaml` điền vào chỗ trống -> Sinh ra file YAML chuẩn -> Gửi cho K8s.

==== Ưu điểm của Helm
1.  *Tái sử dụng (Reusability):* Viết Chart 1 lần, dùng cho Dev, Staging, Prod (chỉ cần thay file `values.yaml` khác nhau).
2.  *Quản lý phiên bản (Versioning):* Helm quản lý lịch sử các lần deploy (Release).
    - `helm install myapp ./mychart` -> Version 1.
    - `helm upgrade myapp ./mychart` -> Version 2.
    - *Rollback:* Nếu Version 2 bị lỗi, chỉ cần `helm rollback myapp 1` là hệ thống tự động quay về trạng thái cũ trong tích tắc.
3.  *Cộng đồng:* Có sẵn hàng ngàn Chart chuẩn (Redis, MySQL, Prometheus, Jenkins) trên Artifact Hub. Chỉ cần `helm install` là có ngay, không cần viết YAML từ đầu.