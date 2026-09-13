import 'package:sqflite/sqflite.dart';
import '../models/bill_template_model.dart';

class BillTemplateDatabaseException implements Exception {
  final String message;
  BillTemplateDatabaseException(this.message);

  @override
  String toString() => 'BillTemplateDatabaseException: $message';
}

abstract class BillTemplateLocalDataSource {
  Future<BillTemplateModel> insertTemplate(BillTemplateModel template);
  Future<List<BillTemplateModel>> getTemplates({String? projectId});
  Future<BillTemplateModel> getTemplateById(String id);
  Future<BillTemplateModel> updateTemplate(BillTemplateModel template);
  Future<void> deleteTemplate(String id);
  Future<List<BillTemplateModel>> getFavoriteTemplates({String? projectId});
  Future<List<BillTemplateModel>> getSuggestedTemplates({String? projectId, int limit = 3});
  Future<void> recordTemplateUsage(String id);
  Future<BillTemplateModel> toggleFavorite(String id);
}

class BillTemplateLocalDataSourceImpl implements BillTemplateLocalDataSource {
  final Database database;

  BillTemplateLocalDataSourceImpl(this.database);

  @override
  Future<BillTemplateModel> insertTemplate(BillTemplateModel template) async {
    try {
      await database.insert(
        'bill_templates',
        template.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return template;
    } catch (e) {
      throw BillTemplateDatabaseException('Failed to insert template: $e');
    }
  }

  @override
  Future<List<BillTemplateModel>> getTemplates({String? projectId}) async {
    try {
      List<Map<String, dynamic>> maps;
      if (projectId != null && projectId.isNotEmpty) {
        maps = await database.query(
          'bill_templates',
          where: 'projectId = ? OR projectId IS NULL',
          whereArgs: [projectId],
          orderBy: 'isFavorite DESC, usageCount DESC, createdAt DESC',
        );
      } else {
        maps = await database.query(
          'bill_templates',
          orderBy: 'isFavorite DESC, usageCount DESC, createdAt DESC',
        );
      }
      return maps.map((m) => BillTemplateModel.fromJson(m)).toList();
    } catch (e) {
      throw BillTemplateDatabaseException('Failed to fetch templates: $e');
    }
  }

  @override
  Future<BillTemplateModel> getTemplateById(String id) async {
    try {
      final maps = await database.query(
        'bill_templates',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return BillTemplateModel.fromJson(maps.first);
      }
      throw BillTemplateDatabaseException('Template not found with ID: $id');
    } catch (e) {
      throw BillTemplateDatabaseException('Failed to get template: $e');
    }
  }

  @override
  Future<BillTemplateModel> updateTemplate(BillTemplateModel template) async {
    try {
      final count = await database.update(
        'bill_templates',
        template.toJson(),
        where: 'id = ?',
        whereArgs: [template.id],
      );
      if (count > 0) {
        return template;
      }
      throw BillTemplateDatabaseException('Template not found to update: ${template.id}');
    } catch (e) {
      throw BillTemplateDatabaseException('Failed to update template: $e');
    }
  }

  @override
  Future<void> deleteTemplate(String id) async {
    try {
      await database.delete(
        'bill_templates',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw BillTemplateDatabaseException('Failed to delete template: $e');
    }
  }

  @override
  Future<List<BillTemplateModel>> getFavoriteTemplates({String? projectId}) async {
    try {
      List<Map<String, dynamic>> maps;
      if (projectId != null && projectId.isNotEmpty) {
        maps = await database.query(
          'bill_templates',
          where: 'isFavorite = 1 AND (projectId = ? OR projectId IS NULL)',
          whereArgs: [projectId],
          orderBy: 'usageCount DESC, createdAt DESC',
        );
      } else {
        maps = await database.query(
          'bill_templates',
          where: 'isFavorite = 1',
          orderBy: 'usageCount DESC, createdAt DESC',
        );
      }
      return maps.map((m) => BillTemplateModel.fromJson(m)).toList();
    } catch (e) {
      throw BillTemplateDatabaseException('Failed to fetch favorite templates: $e');
    }
  }

  @override
  Future<List<BillTemplateModel>> getSuggestedTemplates({String? projectId, int limit = 3}) async {
    try {
      List<Map<String, dynamic>> maps;
      if (projectId != null && projectId.isNotEmpty) {
        maps = await database.query(
          'bill_templates',
          where: 'projectId = ? OR projectId IS NULL',
          whereArgs: [projectId],
          orderBy: 'usageCount DESC, lastUsedAt DESC, createdAt DESC',
          limit: limit,
        );
      } else {
        maps = await database.query(
          'bill_templates',
          orderBy: 'usageCount DESC, lastUsedAt DESC, createdAt DESC',
          limit: limit,
        );
      }
      return maps.map((m) => BillTemplateModel.fromJson(m)).toList();
    } catch (e) {
      throw BillTemplateDatabaseException('Failed to fetch suggested templates: $e');
    }
  }

  @override
  Future<void> recordTemplateUsage(String id) async {
    try {
      final template = await getTemplateById(id);
      final now = DateTime.now();
      final updated = template.copyWith(
        usageCount: template.usageCount + 1,
        lastUsedAt: now,
      );
      await updateTemplate(BillTemplateModel.fromEntity(updated));
    } catch (e) {
      throw BillTemplateDatabaseException('Failed to record template usage: $e');
    }
  }

  @override
  Future<BillTemplateModel> toggleFavorite(String id) async {
    try {
      final template = await getTemplateById(id);
      final updated = template.copyWith(isFavorite: !template.isFavorite);
      final model = BillTemplateModel.fromEntity(updated);
      await updateTemplate(model);
      return model;
    } catch (e) {
      throw BillTemplateDatabaseException('Failed to toggle favorite: $e');
    }
  }
}
