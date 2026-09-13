import 'package:intl/intl.dart';
import '../entities/export_options.dart';

/// Helper to generate standardized export filenames following:
/// `project-name-YYYY-MM-DD.csv` or `project-name-YYYY-MM-DD.pdf`.
class ExportFilenameBuilder {
  const ExportFilenameBuilder();

  /// Generates a sanitized filename based on project name, export date, and format.
  String build({
    String? projectName,
    DateTime? date,
    ExportFormat format = ExportFormat.csv,
  }) {
    final effectiveDate = date ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(effectiveDate);
    final slug = slugify(projectName);
    final ext = format == ExportFormat.csv ? 'csv' : 'pdf';
    return '$slug-$dateStr.$ext';
  }

  /// Converts a project name or arbitrary text into a URL/filesystem-safe slug.
  static String slugify(String? text) {
    if (text == null || text.trim().isEmpty || text.trim().toLowerCase() == 'all projects') {
      return 'all-projects';
    }

    var result = text.trim().toLowerCase();

    // Replace Vietnamese accents
    const withAccents = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const noAccents   = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], noAccents[i]);
    }

    // Replace any non-alphanumeric character with hyphen
    result = result.replaceAll(RegExp(r'[^a-z0-9]+'), '-');

    // Remove leading and trailing hyphens
    result = result.replaceAll(RegExp(r'^-+|-+$'), '');

    return result.isEmpty ? 'all-projects' : result;
  }
}
