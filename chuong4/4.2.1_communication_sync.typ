== Giao tiếp đồng bộ <sync_communication>

Trong giao tiếp đồng bộ, Client gửi một yêu cầu (Request) đến Server và *chờ đợi* (block hoặc non-blocking wait) cho đến khi Server trả về phản hồi (Response). Nếu Server không trả lời hoặc quá thời gian (timeout), Client sẽ coi như lỗi.

Đây là phương thức tự nhiên nhất, giống như gọi hàm trong lập trình, nhưng tiềm ẩn rủi ro về hiệu năng (Blocking) và sự phụ thuộc dây chuyền (Tight Coupling).

=== HTTP/REST

REST không phải là một giao thức, mà là một phong cách kiến trúc (Architectural Style) dựa trên giao thức HTTP. Đây là chuẩn giao tiếp phổ biến nhất thế giới hiện nay.

==== Đặc điểm cốt lõi:
1.  *Stateless:* Server không lưu trạng thái của Client giữa các request. Mỗi request phải chứa đủ thông tin (Token, ID) để xử lý.
2.  *Resource-Based:* Mọi thứ là tài nguyên (Resource), được định danh bằng URI (Ví dụ: `/users/123`).
3.  *Standard Methods (Verbs):* Sử dụng đúng ngữ nghĩa của HTTP Verbs:
    - `GET`: Lấy dữ liệu (Idempotent - gọi nhiều lần kết quả như nhau, an toàn).
    - `POST`: Tạo mới tài nguyên.
    - `PUT`: Cập nhật toàn bộ (Idempotent).
    - `PATCH`: Cập nhật một phần.
    - `DELETE`: Xóa (Idempotent).
4.  *Status Codes:* Sử dụng mã lỗi chuẩn (200 OK, 201 Created, 400 Bad Request, 401 Unauthorized, 404 Not Found, 500 Internal Error).

==== Maturity Model
- *Level 0:* Dùng HTTP như một đường ống (The Swamp of POX). Chỉ dùng 1 URL duy nhất, 1 method (thường là POST) và gửi XML/JSON bên trong. (Kiểu SOAP cũ).
- *Level 1:* Resources. Có nhiều URL khác nhau cho các tài nguyên (`/users`, `/products`) nhưng vẫn dùng 1 method.
- *Level 2:* HTTP Verbs. Sử dụng đúng GET/POST/PUT/DELETE và Status Codes. (Đa số API hiện nay ở mức này).
- *Level 3:* Hypermedia Controls (HATEOAS). Response trả về kèm theo các link hướng dẫn Client làm gì tiếp theo.

==== Ưu điểm:
- *Phổ biến:* Mọi ngôn ngữ, mọi trình duyệt đều hỗ trợ. Dễ debug (dùng cURL, Postman).
- *Linh hoạt:* Payload có thể là JSON, XML, HTML, Binary.
- *Caching:* Tận dụng tốt hạ tầng Cache của HTTP (Browser, CDN, Proxy).

==== Nhược điểm:
- *Hiệu năng:* JSON là text-based, tốn băng thông và CPU để parse. HTTP/1.1 cũ bị vấn đề Head-of-line blocking.
- *Over-fetching/Under-fetching:* Client phải gọi nhiều API để lấy đủ dữ liệu hoặc lấy thừa dữ liệu không cần thiết.

=== gRPC

gRPC là một framework RPC hiệu năng cao, mã nguồn mở do Google phát triển. Nó khắc phục các điểm yếu của REST trong giao tiếp nội bộ (internal services).

==== Đặc điểm kỹ thuật:
1.  *Protocol Buffers (Protobuf):*
    - Sử dụng Binary format thay vì Text (JSON).
    - Kích thước gói tin nhỏ hơn 30-50% so với JSON.
    - Tốc độ Serialize/Deserialize nhanh hơn 5-10 lần.
    - Định nghĩa Schema chặt chẽ (`.proto file`). Đây là một dạng hợp đồng (Contract) bắt buộc.
2.  *HTTP/2 Transport:*
    - Chạy trên HTTP/2, hỗ trợ Multiplexing (gửi nhiều request song song trên 1 kết nối TCP).
    - *Streaming:* Hỗ trợ Streaming 2 chiều (Bi-directional streaming): Client stream, Server stream.
    - Header compression (HPACK).

==== Ví dụ file `.proto`:
```protobuf
service OrderService {
  rpc CreateOrder (OrderRequest) returns (OrderResponse);
}

message OrderRequest {
  string product_id = 1;
  int32 quantity = 2;
}
```

==== Ưu điểm:
- *Hiệu năng cực cao:* Lý tưởng cho giao tiếp giữa các microservices (East-West traffic).
- *Strict Typing:* Tránh lỗi kiểu dữ liệu nhờ Schema. Code generation tự động ra client/server stub cho nhiều ngôn ngữ.

==== Nhược điểm:
- *Khó debug:* Dữ liệu binary không đọc được bằng mắt thường. Cần tool chuyên dụng (gRPCcurl).
- *Browser Support:* Trình duyệt chưa hỗ trợ gRPC trực tiếp tốt (cần gRPC-Web proxy).
- *Coupling:* Thay đổi file `.proto` cần update và compile lại cả client và server.

=== GraphQL

GraphQL là ngôn ngữ truy vấn cho API, do Facebook phát triển. Nó trao quyền cho Client quyết định lấy dữ liệu gì.

==== Đặc điểm:
- *Client-driven:* Client gửi query mô tả chính xác structure dữ liệu mình cần.
- *Single Endpoint:* Chỉ có 1 URL duy nhất (thường là `/graphql`).
- *Schema & Type System:* Định nghĩa rõ ràng các Type, Query, Mutation.

==== Ví dụ Query:
```graphql
query {
  user(id: "1") {
    name
    email
    posts {
      title
    }
  }
}
```
*Kết quả trả về chỉ chứa name, email và list title bài viết. Không thừa, không thiếu.*

==== Ưu điểm:
- *Giải quyết Over-fetching/Under-fetching:* Tối ưu hóa băng thông cho Mobile App.
- *Aggegation:* Một request GraphQL có thể thay thế cho 5-10 request REST, tự động gom dữ liệu từ nhiều nguồn.

==== Nhược điểm:
- *Caching khó:* Vì chỉ dùng 1 URL và method POST, không tận dụng được HTTP Caching chuẩn. Phải cài đặt caching ở tầng ứng dụng (Application caching) phức tạp.
- *Complexity:* Phía Server phải viết Resolvers phức tạp để xử lý query lồng nhau (Nested queries).
- *Performance Risk:* Client có thể gửi một query quá sâu (`user -> posts -> comments -> author -> posts...`) làm treo server (N+1 problem).

=== Best Practices cho Giao tiếp Đồng bộ

1.  *Timeouts:* Luôn luôn, bắt buộc phải set timeout cho mọi request gọi đi. Không được để request treo vô hạn.
2.  *Circuit Breaker:* Nếu Service B lỗi liên tục, Service A nên tự ngắt kết nối (Open circuit) để tránh chờ đợi vô ích và làm sập chính mình.
3.  *Bulkhead:* Chia thread pool riêng cho từng service gọi đi. Service B chết không làm hết thread của Service C.
4.  *Dùng đúng chỗ:*
    - *REST:* Public API, Web Clients.
    - *gRPC:* Internal Services, High performance requirements.
    - *GraphQL:* Mobile Apps, Frontend cần linh hoạt, BFF (Backend For Frontend).