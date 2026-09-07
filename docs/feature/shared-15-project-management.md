# Shared-15: Project Management (Create/Edit/Delete Projects)

**Layer:** Full Stack (Domain, Data, Presentation, UI)  
**Feature:** Projects Foundation for Household / Trip Bill Splitting

---

## Acceptance Criteria

1. ✅ **Create Project entity / ProjectModel in domain/entities:**
   - `id`, `name`, `description`, `members` (`List<String>`), `createdAt`, `updatedAt`
2. ✅ **Create ProjectRepository abstract class with methods:**
   - `create(Project project)`
   - `getAll()`
   - `getById(String id)`
   - `update(Project project)`
   - `delete(String id)`
3. ✅ **Implement ProjectRepositoryImpl in data layer with SQLite support**
4. ✅ **Create projects table:**
   - `id TEXT PRIMARY KEY`
   - `name TEXT NOT NULL`
   - `description TEXT`
   - `members TEXT NOT NULL` (JSON string)
   - `createdAt TEXT NOT NULL`
   - `updatedAt TEXT NOT NULL`
5. ✅ **Create ProjectLocalDataSource & ProjectLocalDataSourceImpl:**
   - `addProject(ProjectModel project)`
   - `getAllProjects()`
   - `getProjectById(String id)`
   - `updateProject(ProjectModel project)`
   - `deleteProject(String id)`
6. ✅ **Create UseCases:**
   - `CreateProjectUseCase`
   - `GetAllProjectsUseCase`
   - `GetProjectByIdUseCase`
   - `UpdateProjectUseCase`
   - `DeleteProjectUseCase`
7. ✅ **Create ProjectBloc with events:**
   - `CreateProject`
   - `GetAllProjects`
   - `UpdateProject`
   - `DeleteProject`
   - States: `ProjectInitial`, `ProjectLoading`, `ProjectLoaded`, `ProjectOperationSuccess`, `ProjectError`
8. ✅ **Create ProjectScreen (list projects) with button to create new project**
9. ✅ **Create CreateProjectScreen (form):**
   - Form fields: name, description, members (add/remove member names)
   - Validation for required fields (name, at least 1 member)
   - Support both Create and Edit modes
10. ✅ **Navigation:**
    - `HomeScreen` → "Dự án / Projects" button → `ProjectScreen` → Create / Edit / Delete
11. ✅ **Verify SQLite queries work:**
    - Insert, select, update, delete projects
12. ✅ **All 65+ tests passing, no compilation errors**
