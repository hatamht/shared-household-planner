import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/settlement_log.dart';
import '../repositories/settlement_repository.dart';

/// Retrieves all settlement logs for a project or globally.
class GetSettlementLogsUseCase {
  final SettlementRepository repository;

  const GetSettlementLogsUseCase(this.repository);

  Future<Either<Failure, List<SettlementLog>>> call({String? projectId}) {
    return repository.getSettlementLogs(projectId: projectId);
  }
}

/// Creates and saves a new settlement log record.
class CreateSettlementLogUseCase {
  final SettlementRepository repository;

  const CreateSettlementLogUseCase(this.repository);

  Future<Either<Failure, SettlementLog>> call(SettlementLog log) {
    return repository.createSettlementLog(log);
  }
}

/// Updates an existing settlement log record.
class UpdateSettlementLogUseCase {
  final SettlementRepository repository;

  const UpdateSettlementLogUseCase(this.repository);

  Future<Either<Failure, SettlementLog>> call(SettlementLog log) {
    return repository.updateSettlementLog(log);
  }
}

/// Deletes a settlement record by its identifier.
class DeleteSettlementLogUseCase {
  final SettlementRepository repository;

  const DeleteSettlementLogUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteSettlementLog(id);
  }
}

/// Marks a settlement status as paid.
class MarkAsPaidUseCase {
  final SettlementRepository repository;

  const MarkAsPaidUseCase(this.repository);

  Future<Either<Failure, SettlementLog>> call(String id) {
    return repository.markAsPaid(id);
  }
}

/// Reverts a paid settlement back to pending (undo).
class UndoMarkAsPaidUseCase {
  final SettlementRepository repository;

  const UndoMarkAsPaidUseCase(this.repository);

  Future<Either<Failure, SettlementLog>> call(String id) {
    return repository.undoMarkAsPaid(id);
  }
}
