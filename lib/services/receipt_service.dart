import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stores receipt images inside the app's documents directory so they survive
/// cache clears and remain available offline.
class ReceiptService {
  ReceiptService._();

  static final ReceiptService instance = ReceiptService._();

  final ImagePicker _picker = ImagePicker();

  Future<String?> pick({bool fromCamera = false}) async {
    final file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 82,
    );
    if (file == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final receipts = Directory(p.join(dir.path, 'receipts'));
    if (!await receipts.exists()) {
      await receipts.create(recursive: true);
    }
    final target = p.join(
      receipts.path,
      'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}',
    );
    await File(file.path).copy(target);
    return target;
  }

  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
