import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/bill_template.dart';
import '../../domain/usecases/create_template_usecase.dart';
import '../../domain/usecases/delete_template_usecase.dart';
import '../../domain/usecases/get_suggested_templates_usecase.dart';
import '../../domain/usecases/get_templates_usecase.dart';
import '../../domain/usecases/record_template_usage_usecase.dart';
import '../../domain/usecases/toggle_favorite_template_usecase.dart';
import '../../domain/usecases/update_template_usecase.dart';

// Events
abstract class BillTemplatesEvent extends Equatable {
  const BillTemplatesEvent();

  @override
  List<Object?> get props => [];
}

class LoadTemplatesEvent extends BillTemplatesEvent {
  final String? projectId;

  const LoadTemplatesEvent({this.projectId});

  @override
  List<Object?> get props => [projectId];
}

class CreateTemplateEvent extends BillTemplatesEvent {
  final BillTemplate template;

  const CreateTemplateEvent(this.template);

  @override
  List<Object?> get props => [template];
}

class UpdateTemplateEvent extends BillTemplatesEvent {
  final BillTemplate template;

  const UpdateTemplateEvent(this.template);

  @override
  List<Object?> get props => [template];
}

class DeleteTemplateEvent extends BillTemplatesEvent {
  final String id;

  const DeleteTemplateEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class ToggleFavoriteTemplateEvent extends BillTemplatesEvent {
  final String id;

  const ToggleFavoriteTemplateEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class RecordTemplateUsageEvent extends BillTemplatesEvent {
  final String id;

  const RecordTemplateUsageEvent(this.id);

  @override
  List<Object?> get props => [id];
}

// States
abstract class BillTemplatesState extends Equatable {
  const BillTemplatesState();

  @override
  List<Object?> get props => [];
}

class BillTemplatesInitial extends BillTemplatesState {}

class BillTemplatesLoading extends BillTemplatesState {}

class BillTemplatesLoaded extends BillTemplatesState {
  final List<BillTemplate> templates;
  final List<BillTemplate> suggested;

  const BillTemplatesLoaded({
    required this.templates,
    required this.suggested,
  });

  List<BillTemplate> get favorites => templates.where((t) => t.isFavorite).toList();

  @override
  List<Object?> get props => [templates, suggested];
}

class BillTemplatesError extends BillTemplatesState {
  final String message;

  const BillTemplatesError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class BillTemplatesBloc extends Bloc<BillTemplatesEvent, BillTemplatesState> {
  final GetTemplatesUseCase getTemplatesUseCase;
  final CreateTemplateUseCase createTemplateUseCase;
  final UpdateTemplateUseCase updateTemplateUseCase;
  final DeleteTemplateUseCase deleteTemplateUseCase;
  final ToggleFavoriteTemplateUseCase toggleFavoriteTemplateUseCase;
  final RecordTemplateUsageUseCase recordTemplateUsageUseCase;
  final GetSuggestedTemplatesUseCase getSuggestedTemplatesUseCase;

  String? _currentProjectId;

  BillTemplatesBloc({
    required this.getTemplatesUseCase,
    required this.createTemplateUseCase,
    required this.updateTemplateUseCase,
    required this.deleteTemplateUseCase,
    required this.toggleFavoriteTemplateUseCase,
    required this.recordTemplateUsageUseCase,
    required this.getSuggestedTemplatesUseCase,
  }) : super(BillTemplatesInitial()) {
    on<LoadTemplatesEvent>(_onLoadTemplates);
    on<CreateTemplateEvent>(_onCreateTemplate);
    on<UpdateTemplateEvent>(_onUpdateTemplate);
    on<DeleteTemplateEvent>(_onDeleteTemplate);
    on<ToggleFavoriteTemplateEvent>(_onToggleFavorite);
    on<RecordTemplateUsageEvent>(_onRecordUsage);
  }

  Future<void> _onLoadTemplates(
    LoadTemplatesEvent event,
    Emitter<BillTemplatesState> emit,
  ) async {
    _currentProjectId = event.projectId;
    emit(BillTemplatesLoading());

    final templatesResult = await getTemplatesUseCase(projectId: event.projectId);
    final suggestedResult = await getSuggestedTemplatesUseCase(projectId: event.projectId);

    templatesResult.fold(
      (failure) => emit(BillTemplatesError(failure.message)),
      (templates) {
        final suggested = suggestedResult.fold(
          (_) => <BillTemplate>[],
          (sug) => sug,
        );
        emit(BillTemplatesLoaded(templates: templates, suggested: suggested));
      },
    );
  }

  Future<void> _onCreateTemplate(
    CreateTemplateEvent event,
    Emitter<BillTemplatesState> emit,
  ) async {
    final result = await createTemplateUseCase(event.template);
    result.fold(
      (failure) => emit(BillTemplatesError(failure.message)),
      (_) => add(LoadTemplatesEvent(projectId: _currentProjectId)),
    );
  }

  Future<void> _onUpdateTemplate(
    UpdateTemplateEvent event,
    Emitter<BillTemplatesState> emit,
  ) async {
    final result = await updateTemplateUseCase(event.template);
    result.fold(
      (failure) => emit(BillTemplatesError(failure.message)),
      (_) => add(LoadTemplatesEvent(projectId: _currentProjectId)),
    );
  }

  Future<void> _onDeleteTemplate(
    DeleteTemplateEvent event,
    Emitter<BillTemplatesState> emit,
  ) async {
    final result = await deleteTemplateUseCase(event.id);
    result.fold(
      (failure) => emit(BillTemplatesError(failure.message)),
      (_) => add(LoadTemplatesEvent(projectId: _currentProjectId)),
    );
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteTemplateEvent event,
    Emitter<BillTemplatesState> emit,
  ) async {
    final result = await toggleFavoriteTemplateUseCase(event.id);
    result.fold(
      (failure) => emit(BillTemplatesError(failure.message)),
      (_) => add(LoadTemplatesEvent(projectId: _currentProjectId)),
    );
  }

  Future<void> _onRecordUsage(
    RecordTemplateUsageEvent event,
    Emitter<BillTemplatesState> emit,
  ) async {
    await recordTemplateUsageUseCase(event.id);
    add(LoadTemplatesEvent(projectId: _currentProjectId));
  }
}
