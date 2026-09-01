# CLAUDE.md — Shared Household Planner (vai Member)

Đứng ở thư mục này là **vai Member**. Repo chính SimSoftStudio là vai PM.

## V1.0 Scope
- **Single-user office mode**: chỉ 1 người xem được (không multi-user/auth)
- Features: chia tiền chuyến đi, lịch chung, danh sách mua sắm
- Tránh phức tạp online sync → dễ phát hành nhanh

## Quy trình làm việc

### Bước 1: Nhặt việc từ board

```bash
# Chạy lệnh tự động (tôi sẽ viết sau)
/member-thuc-hien

# Hoặc tự chọn từ board
# http://localhost:4300 → cột `todo` → chọn task
```

### Bước 2: Làm việc

- Đọc `spec`: đường dẫn tài liệu PM viết (vd: `docs/feature/split-bills.md`)
- Đảm bảo **TOÀN BỘ `acceptance`** đều pass (phải check được đúng/sai)
- Commit + push

### Bước 3: Nộp bài

```bash
git log -1 --oneline  # Lấy commit hash
# Báo PM commit + link đó để PM duyệt
```

## Đặc biệt cho dự án này

- **Không multi-user**: V1.0 chỉ có 1 người dùng → tránh lẫn login/permission logic
- **Không real-time sync**: Có thể lưu local hoặc file-based → đơn giản
- **Focus**: Chỉ làm tốt 1-2 feature, sau đó ship → lấy feedback

---

Phần còn lại (kiểm tra, merge, release) → PM + CEO.
