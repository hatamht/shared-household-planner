# Shared-29: Project Sharing via Invite Code/Link & Member Expense Permissions

## Overview

Phase 5 of **Multi-Device Sync & Group Project Sharing** for `shared-household-planner` (HomeSplit).
This task implements project sharing with simple 6-character Invite Codes and Share Links, allowing users to invite travel companions or housemates to collaborate on a project and add shared expenses together.

## Key Requirements & User Flows

### 1. Generating Invite Code & Share Link (Owner Flow)
- Inside Project Detail / Project Settings, Owner taps **"Chia sẻ dự án"** (Share Project).
- App displays a Share Sheet / Dialog containing:
  - **Mã mời 6 ký tự** nổi bật, dễ đọc (VD: `DL-8899`, `HN-2026`).
  - Nút **"Sao chép mã"** và **"Chia sẻ link"** (qua Zalo, Telegram, Tin nhắn, Messenger).
  - Tùy chọn QR Code để quét trực tiếp từ máy đối diện.
- Mã mời được lưu trong Firestore `share_invites/{code}` liên kết với `projectId`.

### 2. Joining a Shared Project (Member Flow)
- On Home screen or Project List, user taps **"Tham gia bằng mã"** (Join with Code).
- User enters the 6-character code (or clicks deep link `homesplit.app/join?code=DL-8899`).
- App fetches project details (Name, Currency, Owner name), prompts confirmation:
  - *"Bạn có muốn tham gia dự án 'Đi du lịch Phú Quốc' do 'Hoàng' tạo không?"*
- Tapping **"Tham gia"** adds the user's `uid` to `project.memberIds`, downloads all existing bills into local SQLite, and opens the project.

### 3. Member Permissions & Expense Collaboration
- **Permissions**:
  - **Owner**: Quản lý toàn bộ dự án, tạo mã mời, gỡ thành viên, sửa/xóa mọi chi tiêu hoặc xóa dự án.
  - **Member**: Xem toàn bộ chi tiêu, thêm chi tiêu mới, sửa/xóa chi tiêu do chính mình tạo ra.
- **Member Management UI**:
  - Tab / Section **"Thành viên"** trong chi tiết dự án hiển thị danh sách người tham gia kèm avatar và vai trò.
  - Thành viên có nút **"Rời dự án"**.
  - Chủ dự án có nút **"Gỡ khỏi dự án"**.

### 4. Testing & Verification
- Unit & Widget tests covering:
  - Invite code generation, validation, expiration logic.
  - Join project flow with valid and invalid/expired codes.
  - Role-based permissions checking for adding, editing, and deleting bills.
  - Member management UI (list, kick, leave).
- ≥100 unit & widget tests.

## Acceptance Criteria

1. Project Owner can generate a 6-character invite code, share link, and QR code.
2. Invited members can enter invite code or open deep link to join the project.
3. Joined members can add expenses and edit expenses they created in the shared project.
4. Member list displayed in project settings with role badges (Owner vs Member).
5. Permission guards prevent unauthorized bill deletion or project destruction by non-owners.
6. Comprehensive test suite (≥100 tests) validating sharing flows and permission rules.
