import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

class FileHelper {
  late String _fileName;
  final int _fileSize; // Size in bytes

  FileHelper({String? fileName, int fileSize = 1024}) : _fileSize = fileSize {
    _fileName = fileName ?? Random().nextInt(10000).toString();
  }

  // Method to create a random file with random bytes
  Future<File> create() async {
    // Generate random bytes
    final randomBytes = _generateRandomBytes(_fileSize);

    // Create the file
    final file = File(_fileName);
    if (file.existsSync()) {
      await file.delete(); // Delete the file if it already exists
    }

    // Write the random bytes to the file
    await file.writeAsBytes(randomBytes);
    return file;
  }

  // Method to delete the file
  Future<void> delete() async {
    final file = File(_fileName);

    // Check if the file exists
    if (await file.exists()) {
      await file.delete();
    } else {
      print('File $_fileName does not exist');
    }
  }

  // Helper method to generate random bytes
  Uint8List _generateRandomBytes(int size) {
    final random = Random();
    final bytes = Uint8List(size);

    for (int i = 0; i < size; i++) {
      bytes[i] = random.nextInt(256); // Generate a random byte (0-255)
    }

    return bytes;
  }
}
