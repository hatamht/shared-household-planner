import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/project.dart';
import '../../domain/usecases/create_project_usecase.dart';
import '../../domain/usecases/get_all_projects_usecase.dart';
import '../../domain/usecases/get_project_by_id_usecase.dart';
import '../../domain/usecases/update_project_usecase.dart';
import '../../domain/usecases/delete_project_usecase.dart';

part 'project_event.dart';
part 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final CreateProjectUseCase createProjectUseCase;
  final GetAllProjectsUseCase getAllProjectsUseCase;
  final GetProjectByIdUseCase? getProjectByIdUseCase;
  final UpdateProjectUseCase updateProjectUseCase;
  final DeleteProjectUseCase deleteProjectUseCase;

  ProjectBloc({
    required this.createProjectUseCase,
    required this.getAllProjectsUseCase,
    this.getProjectByIdUseCase,
    required this.updateProjectUseCase,
    required this.deleteProjectUseCase,
  }) : super(const ProjectInitial()) {
    on<GetAllProjects>(_onGetAllProjects);
    on<CreateProject>(_onCreateProject);
    on<UpdateProject>(_onUpdateProject);
    on<DeleteProject>(_onDeleteProject);
  }

  Future<void> _onGetAllProjects(
    GetAllProjects event,
    Emitter<ProjectState> emit,
  ) async {
    emit(const ProjectLoading());
    final result = await getAllProjectsUseCase(const NoParams());
    result.fold(
      (failure) => emit(ProjectError(failure.message)),
      (projects) => emit(ProjectLoaded(projects: projects)),
    );
  }

  Future<void> _onCreateProject(
    CreateProject event,
    Emitter<ProjectState> emit,
  ) async {
    emit(const ProjectLoading());
    final result = await createProjectUseCase(CreateProjectParams(project: event.project));
    await result.fold(
      (failure) async => emit(ProjectError(failure.message)),
      (_) async {
        final allResult = await getAllProjectsUseCase(const NoParams());
        allResult.fold(
          (failure) => emit(ProjectLoaded(projects: [event.project])),
          (projects) => emit(ProjectLoaded(projects: projects)),
        );
      },
    );
  }

  Future<void> _onUpdateProject(
    UpdateProject event,
    Emitter<ProjectState> emit,
  ) async {
    emit(const ProjectLoading());
    final result = await updateProjectUseCase(UpdateProjectParams(project: event.project));
    await result.fold(
      (failure) async => emit(ProjectError(failure.message)),
      (_) async {
        final allResult = await getAllProjectsUseCase(const NoParams());
        allResult.fold(
          (failure) => emit(ProjectError(failure.message)),
          (projects) => emit(ProjectLoaded(projects: projects)),
        );
      },
    );
  }

  Future<void> _onDeleteProject(
    DeleteProject event,
    Emitter<ProjectState> emit,
  ) async {
    emit(const ProjectLoading());
    final result = await deleteProjectUseCase(DeleteProjectParams(id: event.id));
    await result.fold(
      (failure) async => emit(ProjectError(failure.message)),
      (_) async {
        final allResult = await getAllProjectsUseCase(const NoParams());
        allResult.fold(
          (failure) => emit(ProjectError(failure.message)),
          (projects) => emit(ProjectLoaded(projects: projects)),
        );
      },
    );
  }
}
