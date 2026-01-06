Chương 9: Xây dựng hệ thống với Node.js v23.7.0
9.1. Node.js v23.7.0 & Hệ sinh thái
9.1.1. Tổng quan Node.js v23 — Đặc điểm

Hỗ trợ ESM
Cập nhật Engine (V8)
Hiệu suất và API Mới
Hỗ trợ TypeScript

9.1.2. Khi nào chọn Node.js cho Backend

I/O-Bound
Microservices
Real-time

9.2. Framework & kiến trúc ứng dụng
9.2.1. NestJS — Framework hướng module

Đặc điểm
DI & Clean Architecture

9.2.1.1. Module, Controller, Provider (Service)

Module
Controller
Provider (Service)

9.2.1.2. Interceptors, Pipes, Guards

Pipes
Guards
Interceptors

9.2.1.3. Integration

gRPC
Websockets
GraphQL
Microservices transport

9.2.2. Express / Fastify — Lightweight Frameworks

Express
Fastify
Bảng so sánh

9.2.3. Khi dùng Monolith vs Modular Monolith vs Microservices

Bảng so sánh

9.3. Services & Dependency Injection / Middlewares
9.3.1. Dependency Injection (DI)

NestJS Built-in DI
Express với DI

9.3.2. Middleware Pattern

Định nghĩa
Ứng dụng

Logging
Request Validation
Error Handling
Rate Limiting



9.3.3. Global vs Per-route Middleware, Ordering, Best Practices

Global Middleware
Per-route Middleware
Ordering
Best Practices

9.4. ORM / Database access
9.4.1. Prisma

Đặc điểm
Migrations

9.4.2. TypeORM

Đặc điểm
API

9.4.3. Sequelize / Objection / Drizzle

Sequelize
Objection.js
Drizzle ORM

9.4.4. So sánh (Prisma vs TypeORM vs Sequelize)

Bảng so sánh

9.5. Clean Architecture / Project layout (Node.js)
9.5.1. Layers

API (Controllers)
Use Cases (Services/Interactors)
Domain (Entities/Models)
Infrastructure (DB, Queue, Cache)

9.5.2. Ví dụ Cấu trúc Thư mục (NestJS + TypeScript)
9.5.3. Unit test, e2e test patterns, Mocking

Unit Test
E2E Test
Mocking External Deps

9.6. Caching
9.6.1. Local Cache (In-memory LRU)
9.6.2. Distributed Cache: Redis
9.6.3. Reverse Proxy Cache
9.6.4. Patterns

Cache-aside
Read-through
Write-through
Write-behind

9.7. Messaging / Event-driven
9.7.1. RabbitMQ

Thư viện
Patterns

9.7.2. Kafka

Thư viện
So sánh

9.7.3. Task Queues: BullMQ
9.7.4. Saga / Distributed Transaction

Choreography
Orchestration

9.8. Service Discovery, API Gateway & Service Mesh
9.8.1. Service Discovery

Consul / etcd

9.8.2. API Gateway

Công cụ
Chức năng

9.8.3. Envoy + Sidecar Patterns

Envoy
xDS

9.8.4. Service Mesh

Istio / Linkerd
Chức năng

9.9. Fault tolerance, Circuit Breaker, Retry
9.9.1. Retry Patterns

Retry
Exponential Backoff

9.9.2. Circuit Breaker

Opossum
Mục đích

9.9.3. Bulkhead & Timeout Patterns

Timeout
Bulkhead

9.10. Security & Auth (API security)
9.10.1. JWT, OAuth2 Flows

JWT
OAuth2 Flows

9.10.2. Libraries

passport + strategies
Identity Provider

9.10.3. Hardening

Rate Limiting
Input Validation
helmet
CORS hardening

9.11. Observability, Metrics & Logging
9.11.1. Metrics

prom-client
Types

9.11.2. Tracing

OpenTelemetry Node.js SDK
Backend

9.11.3. Logging

Structured logging
Logger libraries
Shipping

9.11.4. Dashboards

Prometheus + Grafana
Alerts

9.12. Search & Analytics
9.12.1. Elasticsearch client

Client
Chức năng

9.12.2. Integration Patterns

Sync (CDC)
Async (Events)

9.13. Containerization & Deployment
9.13.1. Dockerfile Best Practices for Node.js v23

Multistage Build
Small Base Images
Non-root User
Caching

9.13.2. Kubernetes Deployment Patterns

Deployment
StatefulSet
HPA

9.13.3. Helm Charts
9.13.4. Serverless Options (FaaS)

AWS Lambda
Trade-offs

9.14. CI/CD & Release strategies
9.14.1. Pipelines

Build
Test
Image
Push
Deploy

9.14.2. Kubernetes Release strategies

Rolling Updates
Blue/Green
Canary

9.14.3. DB Migrations

Prisma Migrate
Flyway / Liquibase

9.15. Admin / Management
9.15.1. Health Endpoints, Readiness & Liveness Probes

/health
Liveness Probe
Readiness Probe

9.15.2. Admin UIs

Prometheus + Grafana
Elastic Stack (Kibana)
Admin Tools

9.16. Enterprise features & integrations

Bảng tổng hợp các tính năng

9.17. Ví dụ minh họa — Kiến trúc thực thi (sample)
9.17.1. Use Case: E-commerce Order Flow

Kiến trúc tổng quan

9.17.2. Flow Mô tả Saga (Choreography)

Các bước trong flow
Compensation Events

9.18. Best Practices & Checklist triển khai
9.18.1. Observability
9.18.2. Resilience
9.18.3. Security
9.18.4. Performance
9.18.5. DevDX (Developer Experience)