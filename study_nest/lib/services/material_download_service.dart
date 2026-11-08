import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_material.dart';

class MaterialDownloadService {
  static const String _idsKey = 'downloaded_material_ids';
  static const String _materialPrefix = 'offline_material_';

  /// Check whether a material is downloaded and available offline
  static Future<bool> isDownloaded(String materialId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_idsKey) ?? [];
    return ids.contains(materialId);
  }

  /// Download and persist a material to device SharedPreferences
  static Future<void> downloadMaterial(StudyMaterial material) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_idsKey) ?? [];
    if (!ids.contains(material.id)) {
      ids.add(material.id);
      await prefs.setStringList(_idsKey, ids);
    }
    await prefs.setString(
      '$_materialPrefix${material.id}',
      jsonEncode(material.toJson()),
    );
  }

  /// Remove a downloaded material from device storage
  static Future<void> removeDownloadedMaterial(String materialId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_idsKey) ?? [];
    ids.remove(materialId);
    await prefs.setStringList(_idsKey, ids);
    await prefs.remove('$_materialPrefix$materialId');
  }

  /// Retrieve the locally stored copy of a downloaded material
  static Future<StudyMaterial?> getDownloadedMaterial(String materialId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_materialPrefix$materialId');
    if (data == null) return null;
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return StudyMaterial.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Get list of all downloaded material IDs
  static Future<List<String>> getDownloadedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_idsKey) ?? [];
  }

  /// Clear all offline materials (useful for tests and resets)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_idsKey) ?? [];
    for (final id in ids) {
      await prefs.remove('$_materialPrefix$id');
    }
    await prefs.remove(_idsKey);
  }
}
