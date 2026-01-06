== Byzantine Fault <byzantine_fault>

=== Nguồn gốc: Bài toán các vị tướng Byzantine

Bài toán kinh điển này được Leslie Lamport mô tả năm 1982, là nền tảng của lý thuyết hệ thống phân tán hiện đại.

*Bối cảnh:*
- Một nhóm các vị tướng quân đội Byzantine đang bao vây một thành phố.
- Họ phải thống nhất một kế hoạch chung: Tấn công (Attack) hoặc Rút lui (Retreat).
- Nếu tất cả cùng tấn công -> Thắng.
- Nếu tất cả cùng rút lui -> An toàn.
- Nếu một nửa tấn công, một nửa rút lui -> Thua thảm hại (bị tiêu diệt từng phần).
- Các vị tướng ở xa nhau, chỉ liên lạc được qua người đưa tin (messengers).

*Vấn đề:*
- Trong số các tướng, có những kẻ phản bội (traitors).
- Kẻ phản bội sẽ cố gắng phá hoại sự đồng thuận bằng cách gửi tin nhắn sai lệch. Ví dụ: Nói với tướng A là "Tấn công", nói với tướng B là "Rút lui".
- Thậm chí người đưa tin cũng có thể bị bắt và thay đổi nội dung thư.

*Câu hỏi:* Làm thế nào để các vị tướng trung thành vẫn đạt được sự đồng thuận (cùng tấn công hoặc cùng rút lui) bất chấp sự phá hoại của kẻ phản bội?

=== Định nghĩa Byzantine Failure

Trong khoa học máy tính, một node bị coi là lỗi Byzantine nếu nó cư xử hoàn toàn tùy ý (arbitrary behavior), không tuân theo protocol quy định.
- *Crash Fault:* Node im lặng (không gửi tin). Dễ phát hiện.
- *Byzantine Fault:* Node vẫn gửi tin, nhưng là tin rác, tin giả, hoặc tin mâu thuẫn. Cực khó phát hiện vì nó trông giống như một node bình thường đang hoạt động.

*Nguyên nhân:*
1.  *Lỗi phần cứng/phần mềm ngẫu nhiên:* Bit-flip trong RAM làm thay đổi giá trị biến từ 0 thành 1. Bug logic hiếm gặp làm sai lệch kết quả tính toán.
2.  *Tác nhân độc hại (Malicious attacks):* Hacker chiếm quyền điều khiển server và chủ động gửi dữ liệu sai để phá hoại hệ thống (ví dụ: làm sai lệch sổ cái tài chính).

=== Điều kiện cần để chịu lỗi (BFT)

Lamport đã chứng minh rằng: Để hệ thống chịu được $f$ node bị lỗi Byzantine, tổng số node $N$ trong hệ thống phải thỏa mãn:

$ N >= 3f + 1 $

Nghĩa là:
- Nếu muốn chịu được 1 kẻ phản bội ($f=1$), cần ít nhất 4 tướng ($N=4$).
- Nếu chỉ có 3 tướng mà 1 kẻ phản bội, hệ thống BẤT LỰC. (Vì 2 người còn lại sẽ nhận được thông tin trái ngược và không có đa số để quyết định ai đúng ai sai).

So sánh với Crash Fault Tolerance (như Raft, Paxos): Chỉ cần $N >= 2f + 1$ (Quá bán - Simple Majority).
-> BFT tốn kém hơn nhiều về mặt tài nguyên (cần nhiều server hơn).

=== Thuật toán PBFT

Trước năm 1999, các giải pháp BFT chủ yếu là lý thuyết vì quá chậm. Miguel Castro và Barbara Liskov (MIT) đã giới thiệu PBFT, thuật toán thực tế đầu tiên có thể áp dụng được.

Cơ chế hoạt động của PBFT trải qua 3 pha (3-phase protocol) để đảm bảo mọi node trung thực đều nhận được cùng một thứ tự message:

1.  *Pre-Prepare:* Leader (Primary) nhận request từ client, gán số thứ tự (sequence number) và gửi cho các node khác (Backups).
2.  *Prepare:* Các node Backup nhận message, kiểm tra tính hợp lệ (chữ ký số), sau đó gửi tin nhắn "Prepare" cho TẤT CẢ các node khác (quảng bá chéo - multicast).
    - *Mục đích:* Để mọi người biết rằng "Tôi đã nhận được lệnh này từ Leader". Nếu Leader là kẻ phản bội gửi lệnh lung tung, các node sẽ phát hiện ra sự không nhất quán ở bước này.
3.  *Commit:* Khi một node nhận được đủ $2f+1$ tin nhắn Prepare giống nhau từ các node khác (đạt được quorum), nó tin rằng đa số đã đồng ý. Nó gửi tin nhắn "Commit" cho tất cả.
    - Khi nhận đủ $2f+1$ tin nhắn Commit -> Thực thi request và trả kết quả cho Client.

*Nhược điểm của PBFT:* Số lượng tin nhắn trao đổi tăng theo hàm mũ ($O(N^2)$). Khi số node tăng lên (ví dụ 100 nodes), mạng sẽ bị nghẽn vì quá nhiều tin nhắn. Do đó PBFT truyền thống khó scale cho mạng lớn.

=== Ứng dụng trong Blockchain

Byzantine Fault Tolerance chính là trái tim của công nghệ Blockchain. Vì trong mạng lưới Blockchain (đặc biệt là Public Blockchain), ta không thể tin tưởng bất kỳ ai. Ai cũng có thể là kẻ gian.

1.  *Bitcoin (Proof-of-Work):*
    - Nakamoto Consensus giải quyết bài toán Byzantine theo cách tiếp cận xác suất (Probabilistic).
    - Thay vì bắt tất cả node bỏ phiếu (quá chậm), nó bắt các node giải bài toán khó (đào). Ai giải xong trước thì có quyền đề xuất block mới.
    - Quy tắc "Chuỗi dài nhất" (Longest Chain Rule) giúp đạt được đồng thuận cuối cùng. Kẻ tấn công muốn sửa đổi lịch sử phải sở hữu >50% sức mạnh tính toán (51% attack).

2.  *Proof-of-Stake (PoS) & BFT variants:*
    - Các blockchain hiện đại (Cosmos, Algorand, Ethereum 2.0) sử dụng các biến thể của BFT (như Tendermint BFT) để đạt tốc độ cao hơn và không tốn năng lượng.
    - Tendermint có thể chịu được 1/3 validator gian lận. Nếu vượt quá 1/3, mạng sẽ ngừng hoạt động (Halt) để bảo vệ an toàn dữ liệu thay vì cho phép fork lung tung.

=== Kết luận

Byzantine Fault Tolerance là đỉnh cao của sự tin cậy trong môi trường không tin cậy.
- Trong hệ thống nội bộ doanh nghiệp (Private): Ít dùng BFT (vì tin tưởng nhân viên và firewall), thường dùng Crash Fault Tolerance (Raft/Paxos) cho nhanh.
- Trong hệ thống mở (Public Decentralized): BFT là bắt buộc.
Nó nhắc nhở chúng ta rằng: Một hệ thống an toàn không phải là hệ thống dựa trên niềm tin, mà là hệ thống dựa trên bằng chứng toán học và quy tắc đa số.