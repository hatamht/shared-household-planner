import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/settlement_log.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../datasources/settlement_local_datasource.dart';
import '../models/settlement_log_model.dart';

class SettlementRepositoryImpl implements SettlementRepository {
  final SettlementLocalDataSource localDataSource;

  const SettlementRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<SettlementLog>>> getSettlementLogs({String? projectId}) async {
    try {
      final logs = await localDataSource.getSettlementLogs(projectId: projectId);
      return Right(logs);
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SettlementLog>> getSettlementLogById(String id) async {
    try {
      final log = await localDataSource.getSettlementLogById(id);
      return Right(log);
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SettlementLog>> createSettlementLog(SettlementLog log) async {
    try {
      final model = SettlementLogModel.fromEntity(log);
      final created = await localDataSource.createSettlementLog(model);
      return Right(created);
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SettlementLog>> updateSettlementLog(SettlementLog log) async {
    try {
      final model = SettlementLogModel.fromEntity(log);
      final updated = await localDataSource.updateSettlementLog(model);
      return Right(updated);
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSettlementLog(String id) async {
    try {
      await localDataSource.deleteSettlementLog(id);
      return const Right(null);
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SettlementLog>> markAsPaid(String id) async {
    try {
      final existing = await localDataSource.getSettlementLogById(id);
      final updated = existing.copyWith(status: SettlementStatus.paid);
      final saved = await localDataSource.updateSettlementLog(
        SettlementLogModel.fromEntity(updated),
      );
      return Right(saved);
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SettlementLog>> undoMarkAsPaid(String id) async {
    try {
      final existing = await localDataSource.getSettlementLogById(id);
      final updated = existing.copyWith(status: SettlementStatus.pending);
      final saved = await localDataSource.updateSettlementLog(
        SettlementLogModel.fromEntity(updated),
      );
      return Right(saved);
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }
}
