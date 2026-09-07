part of 'project_bloc.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

class GetAllProjects extends ProjectEvent {
  const GetAllProjects();
}
typedef GetAllProjectsEvent = GetAllProjects;

class CreateProject extends ProjectEvent {
  final Project project;

  const CreateProject(this.project);

  @override
  List<Object?> get props => [project];
}
typedef CreateProjectEvent = CreateProject;

class UpdateProject extends ProjectEvent {
  final Project project;

  const UpdateProject(this.project);

  @override
  List<Object?> get props => [project];
}
typedef UpdateProjectEvent = UpdateProject;

class DeleteProject extends ProjectEvent {
  final String id;

  const DeleteProject(this.id);

  @override
  List<Object?> get props => [id];
}
typedef DeleteProjectEvent = DeleteProject;
