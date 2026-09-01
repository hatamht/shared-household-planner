# Member Workflow Guide

## API Endpoint untuk nộp bài

**Endpoint:** `PATCH /api/tasks/{task-id}`

**Header:**
```
X-Role: member:shared
Content-Type: application/json
```

## Quy trình nộp bài

### 1. Khi bắt đầu làm task (todo → doing)
```bash
curl -X PATCH http://localhost:4300/api/tasks/{task-id} \
 -H 'X-Role: member:shared' \
 -H 'Content-Type: application/json' \
 -d '{"col": "doing"}'
```

### 2. Khi hoàn thành (doing → review)
```bash
curl -X PATCH http://localhost:4300/api/tasks/{task-id} \
 -H 'X-Role: member:shared' \
 -H 'Content-Type: application/json' \
 -d '{"col": "review", "result": "Commits: {hash} | Link: {github-link}"}'
```

## Task List

| Task | Task ID | Status | Commit(s) | Link |
|------|---------|--------|-----------|------|
| Split Bills Domain Layer | t3 | done | 306763b | https://github.com/hatamht/shared-household-planner/commit/306763b |
| Split Bills Data Layer | t4 | done | 273fd74 | https://github.com/hatamht/shared-household-planner/commit/273fd74 |

## Database Status Mapping

- `pending` = Task chưa nhận
- `in_progress` = Task đang làm (col: "doing")
- `done` = Member làm xong, nộp bài (col: "review")
- PM sẽ duyệt + move col: "done" trên board

## Remember
✅ Luôn chuyển status DB → API submission
✅ Ghi rõ commit hash + GitHub link
✅ Chờ PM duyệt trên board (cột "review")
