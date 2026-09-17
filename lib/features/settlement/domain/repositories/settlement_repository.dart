import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/settlement_log.dart';

/// Repository interface managing persistence and retrieval of settlement records.
abstract class SettlementRepository {
  /// Retrieves all settlement logs, optionally filtered by [projectId].
  Future<Either<Failure, List<SettlementLog>>> getSettlementLogs({String? projectId});

  /// Retrieves a specific settlement log by [id].
  Future<Either<Failure, SettlementLog>> getSettlementLogById(String id);

  /// Saves a new settlement record.
  Future<Either<Failure, SettlementLog>> createSettlementLog(SettlementLog log);

  /// Updates an existing settlement record.
  Future<Either<Failure, SettlementLog>> updateSettlementLog(SettlementLog log);

  /// Deletes a settlement record by [id].
  Future<Either<Failure, void>> deleteSettlementLog(String id);

  /// Marks a settlement as paid.
  Future<Either<Failure, SettlementLog>> markAsPaid(String id);

  /// Reverts a paid settlement back to pending (undo mark-as-paid).
  Future<Either<Failure, SettlementLog>> undoMarkAsPaid(String id);
}
