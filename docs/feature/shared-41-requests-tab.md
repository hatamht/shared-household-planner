# Shared-41: Requests Tab - Create Request Items Linked to Project

## Overview
Allows household members to create and track item purchase requests, chores, or procurement needs linked to specific projects. Each request belongs to exactly one project (1-to-many relationship: 1 project → many requests). Members can create requests via a modal/bottom sheet with project selector, view requests by project, update status (`pending`, `completed`, `cancelled`), delete requests, and observe the live request count directly on project cards in the home dashboard.

## Acceptance Criteria
1. **New tab 5: Requests (or integrate into existing tab structure)**:
   - Integrated into the existing navigation tab structure in Tab 1 ("Requests") with a clear Segmented/TabBar toggle between "Bills" and "Requests", preserving full backwards compatibility with existing 4-tab tests while offering direct access to requests.
   - Also available as a standalone screen `/requests` (`RequestListScreen`) and reachable from Project cards and Project details.
2. **Each request belongs to exactly one project**:
   - `projectId` is mandatory on every request.
   - Cascade delete: when a project is deleted, its requests are cleaned up.
3. **Request entity**:
   - `id`: unique identifier (UUID).
   - `projectId`: foreign key to project.
   - `title`: name/summary of the request.
   - `description`: optional details or notes.
   - `status`: enum `pending`, `completed`, `cancelled`.
   - `createdAt`: ISO 8601 timestamp.
   - `updatedAt`: optional ISO 8601 timestamp.
4. **Create request: modal/bottom sheet with project selector**:
   - Bottom sheet / dialog with fields for project selection dropdown, title input, description input.
   - Form validation ensuring title and project are specified.
5. **Request list screen: shows all requests for selected project**:
   - Filter requests by project (or view all project requests).
   - Filter by status tabs: All, Pending, Completed, Cancelled.
   - Shows empty states when no requests match.
6. **Mark request as completed/cancelled**:
   - Quick action buttons on request cards to mark a pending request as `completed` or `cancelled`, or revert back to `pending`.
7. **Delete request option**:
   - Delete action with confirmation dialog.
8. **Display request count on project card**:
   - Project cards on HomeScreen show the count of requests for that project (e.g., badge or chip with key `projectRequestBadge_<projectId>`).
9. **One-to-many relationship: 1 project → many requests**:
   - Enforced by domain entities and SQLite foreign key constraints.
10. **SQLite table: requests with foreign key to projects.id**:
    - Table definition:
      ```sql
      CREATE TABLE IF NOT EXISTS requests (
        id TEXT PRIMARY KEY,
        projectId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (projectId) REFERENCES projects(id) ON DELETE CASCADE
      )
      ```
11. **Tests: 80+ covering request CRUD, project linking, filtering**:
    - Comprehensive unit, repository, bloc, and widget tests covering all operations, edge cases, dark/light theme, and i18n.
