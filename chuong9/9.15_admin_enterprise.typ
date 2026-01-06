== Admin / Management <admin_management>

=== Health Endpoints

Để Kubernetes biết app còn sống hay không.

- *`/health`:* Trả về 200 OK kèm thông tin cơ bản (uptime, version).
- *Liveness Probe:* K8s hỏi "Mày còn sống không?". Nếu chết -> K8s restart Pod.
- *Readiness Probe:* K8s hỏi "Mày sẵn sàng nhận traffic chưa?". Nếu chưa (đang load DB, cache) -> K8s không gửi request vào.

=== Admin UIs

- *Prometheus + Grafana:* Dashboard giám sát kỹ thuật.
- *Elastic Stack (Kibana):* Tra cứu log tập trung.
- *Admin Tools:* Các framework như `AdminJS`, `NestJS Admin` giúp tạo trang quản trị CRUD nhanh chóng dựa trên DB Schema.

== Enterprise features & integrations <enterprise_features>

Tổng hợp các tính năng doanh nghiệp cần có:
- *SSO (Single Sign-On):* Tích hợp SAML/OIDC.
- *Audit Logging:* Ghi lại ai làm gì, lúc nào (quan trọng cho Compliance).
- *Feature Flags:* Bật tắt tính năng mà không cần redeploy code (LaunchDarkly, Unleash).
- *Tenancy:* Multi-tenant support (SaaS).