# Quy tắc tự động thực hiện Task (Workflow Rules)

## 1. Lệnh tắt kích hoạt (Trigger Commands)
Khi người dùng nhập bất kỳ lệnh ngắn nào sau đây:
- `!next`
- `!task`
- `lam`
- `nhặt task`
- `làm task`

Agent sẽ hiểu là lệnh: **"Tự động nhặt task tiếp theo từ Task Board và thực hiện trọn gói theo đúng quy trình SimSoft Studio"**.

---

## 2. Quy trình thực hiện trọn gói (Standard Member Workflow)

1. **Quét & Chọn task:**
   - Gọi `GET http://localhost:4300/api/data`
   - Tìm task thuộc `projectId: "shared"` ở cột `todo` (ưu tiên task có `next: true` hoặc task có ID nhỏ nhất, ví dụ `t31`).
2. **Nhận việc (`todo` ➔ `doing`):**
   - Gọi `PATCH http://localhost:4300/api/tasks/<id>` với header `X-Role: member:shared` và body:
     ```json
     {"col": "doing", "comment": "Member nhận task <id> - <title>"}
     ```
3. **Đọc kỹ đề bài:**
   - Đọc danh sách `acceptance` và `spec` của task.
4. **Lập trình & Hoàn thiện:**
   - Code theo kiến trúc Clean Architecture của dự án.
   - Hỗ trợ đầy đủ dark/light theme.
   - Thêm đầy đủ nhãn ngôn ngữ vào `en.json` và `vi.json`.
   - Giữ tương thích ngược với các widget/navigation/keys cũ.
5. **Kiểm thử (Tests):**
   - Viết bộ test đầy đủ (100+ tests nếu acceptance criteria yêu cầu).
   - Chạy `flutter test` đảm bảo 100% tests trong dự án đều pass (0 failure).
6. **Git Commit & Push:**
   - Commit với message chuẩn convention: `feat(...)` / `fix(...)` kèm ID task.
   - Push lên branch `hatamht-member-task-execution`.
7. **Nộp bài nghiệm thu (`doing` ➔ `review`):**
   - Gọi `PATCH http://localhost:4300/api/tasks/<id>` với header `X-Role: member:shared` và body:
     ```json
     {
       "col": "review",
       "result": {
         "branch": "hatamht-member-task-execution",
         "commits": ["<commit_hash>"],
         "note": "<tóm tắt kết quả>"
       },
       "comment": "<tóm tắt hoàn thành>"
     }
     ```
8. **Báo cáo người dùng:**
   - Phản hồi ngắn gọn, rõ ràng bằng tiếng Việt.
