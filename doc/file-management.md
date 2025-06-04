# File Management

This guide covers the file management capabilities in Dart Flux for handling file uploads, downloads, serving static files, and managing storage.

> 📖 **Related Documentation:**
> - [Getting Started](getting-started.md) - Basic file handling setup
> - [Routing Examples](routing_examples.md) - File handling in routes
> - [Best Practices & Security](best-practices-security.md) - Secure file handling
> - [Integration Guides](integration-guides.md) - Cloud storage integrations

## Overview

Dart Flux provides a comprehensive file system API that allows you to:

- Process file uploads from clients
- Serve static files and folders
- Download and stream files
- Manage storage entities

## Handling File Uploads

### Basic File Upload

```dart
Router router = Router()
  .post('upload', (req, res, pathArgs) async {
    if (!req.hasFormData) {
      return res.status(400).json({
        'error': 'No form data provided',
      });
    }
    
    final formData = await req.formData;
    final fileField = formData.file('document');
    
    if (fileField == null) {
      return res.status(400).json({
        'error': 'No file provided in the document field',
      });
    }
    
    // Access file details
    final fileName = fileField.filename;
    final contentType = fileField.contentType;
    final fileSize = fileField.size;
    
    // Save file to disk
    final path = 'storage/uploads/$fileName';
    await fileField.save(path);
    
    return res.json({
      'message': 'File uploaded successfully',
      'filename': fileName,
      'size': fileSize,
      'type': contentType,
      'path': path
    });
  });
```

### Multiple File Upload

```dart
Router router = Router()
  .post('upload-multiple', (req, res, pathArgs) async {
    if (!req.hasFormData) {
      return res.status(400).json({
        'error': 'No form data provided',
      });
    }
    
    final formData = await req.formData;
    final fileFields = formData.files('documents');
    
    if (fileFields.isEmpty) {
      return res.status(400).json({
        'error': 'No files provided in the documents field',
      });
    }
    
    final uploadedFiles = [];
    
    for (final fileField in fileFields) {
      final fileName = fileField.filename;
      final path = 'storage/uploads/$fileName';
      await fileField.save(path);
      
      uploadedFiles.add({
        'filename': fileName,
        'size': fileField.size,
        'type': fileField.contentType,
        'path': path
      });
    }
    
    return res.json({
      'message': 'Files uploaded successfully',
      'files': uploadedFiles,
    });
  });
```

### File Upload with Additional Form Fields

```dart
Router router = Router()
  .post('upload-with-metadata', (req, res, pathArgs) async {
    if (!req.hasFormData) {
      return res.status(400).json({
        'error': 'No form data provided',
      });
    }
    
    final formData = await req.formData;
    final fileField = formData.file('document');
    
    if (fileField == null) {
      return res.status(400).json({
        'error': 'No file provided in the document field',
      });
    }
    
    // Get additional form fields
    final description = formData.text('description')?.value ?? '';
    final category = formData.text('category')?.value ?? 'uncategorized';
    final isPublic = formData.text('isPublic')?.value == 'true';
    
    // Save file
    final fileName = fileField.filename;
    final path = 'storage/uploads/$category/$fileName';
    await fileField.save(path);
    
    // Store metadata (in a real app, you would save this to a database)
    final metadata = {
      'filename': fileName,
      'description': description,
      'category': category,
      'isPublic': isPublic,
      'size': fileField.size,
      'type': fileField.contentType,
      'path': path,
      'uploadedAt': DateTime.now().toIso8601String(),
    };
    
    return res.json({
      'message': 'File uploaded successfully',
      'metadata': metadata,
    });
  });
```

## Serving Static Files

### Serving a Single File

```dart
Router router = Router()
  .get('download/:filename', (req, res, pathArgs) async {
    final filename = pathArgs['filename'];
    final path = 'storage/files/$filename';
    
    // Check if file exists
    final file = File(path);
    if (!await file.exists()) {
      return res.status(404).json({
        'error': 'File not found',
      });
    }
    
    // Set content type based on file extension
    final extension = filename.split('.').last.toLowerCase();
    final contentType = getContentTypeFromExtension(extension);
    
    // Serve the file
    return res.streamFile(file, contentType: contentType);
  });

String getContentTypeFromExtension(String extension) {
  switch (extension) {
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'txt':
      return 'text/plain';
    case 'html':
      return 'text/html';
    case 'json':
      return 'application/json';
    default:
      return 'application/octet-stream';
  }
}
```

### Serving a Folder of Static Files

```dart
import 'package:dart_flux/core/server/parser/models/folder_server.dart';

void main() async {
  // Create a folder server for static assets
  final publicFolder = FolderServer(
    rootPath: 'public',
    prefix: 'assets',
  );
  
  // Create a router that serves static files
  final router = Router()
    .get('assets/*', (req, res, pathArgs) async {
      final relativePath = pathArgs['*'];
      return publicFolder.serveFile(relativePath, res);
    });
  
  // Create the server
  final server = Server(InternetAddress.anyIPv4, 3000, router);
  await server.run();
}
```

This sets up a router that serves files from the `public` folder under the `/assets` URL path. For example, a file at `public/images/logo.png` would be accessible at `http://localhost:3000/assets/images/logo.png`.

### Serving an Index.html for SPAs

```dart
Router router = Router()
  .get('*', (req, res, pathArgs) async {
    final path = pathArgs['*'];
    
    // Check if the path is for an API route
    if (path.startsWith('api/')) {
      return res.status(404).json({
        'error': 'API endpoint not found',
      });
    }
    
    // Try to serve static file from public directory
    final filePath = 'public/$path';
    final file = File(filePath);
    
    if (await file.exists()) {
      final extension = path.split('.').last.toLowerCase();
      final contentType = getContentTypeFromExtension(extension);
      return res.streamFile(file, contentType: contentType);
    }
    
    // If file not found, serve index.html for SPA routing
    final indexFile = File('public/index.html');
    if (await indexFile.exists()) {
      return res.streamFile(indexFile, contentType: 'text/html');
    }
    
    // If all else fails, return 404
    return res.status(404).json({
      'error': 'Resource not found',
    });
  });
```

## File Storage Management

### Creating a Storage Entity

```dart
import 'package:dart_flux/core/server/parser/models/file_entity.dart';
import 'package:dart_flux/core/server/parser/models/folder_entity.dart';

// Create a storage directory
final storageFolder = FolderEntity('storage');

// Create a subfolder
final uploadsFolder = storageFolder.getFolder('uploads');
await uploadsFolder.create(); // Creates the directory if it doesn't exist

// Create a file in the uploads folder
final logFile = uploadsFolder.getFile('upload-log.txt');
await logFile.writeText('Upload log initialized at ${DateTime.now()}\n');

// Append to the file
await logFile.appendText('New upload at ${DateTime.now()}\n');

// Read file contents
final logContents = await logFile.readText();
print(logContents);
```

### File Operations

```dart
// Check if a file exists
final file = FileEntity('storage/documents/report.pdf');
final exists = await file.exists();

if (exists) {
  // Get file size
  final size = await file.size();
  print('File size: $size bytes');
  
  // Get last modified time
  final lastModified = await file.lastModified();
  print('Last modified: $lastModified');
  
  // Copy file
  final backupFile = FileEntity('storage/backups/report-backup.pdf');
  await file.copyTo(backupFile.path);
  
  // Move/rename file
  await file.moveTo('storage/archives/report-2023.pdf');
  
  // Delete file
  await backupFile.delete();
}
```

### Folder Operations

```dart
// Check if folder exists
final folder = FolderEntity('storage/images');
final exists = await folder.exists();

if (!exists) {
  // Create folder
  await folder.create();
}

// List files in a folder
final files = await folder.listFiles();
for (final file in files) {
  print('File: ${file.name}');
}

// List subfolders
final subfolders = await folder.listFolders();
for (final subfolder in subfolders) {
  print('Subfolder: ${subfolder.name}');
}

// Copy folder and its contents
final backupFolder = FolderEntity('storage/backups/images');
await folder.copyTo(backupFolder.path);

// Delete folder (recursive)
await backupFolder.delete(recursive: true);
```

## Streaming Large Files

For large files, streaming is more efficient than loading the entire file into memory:

```dart
Router router = Router()
  .get('stream-video/:filename', (req, res, pathArgs) async {
    final filename = pathArgs['filename'];
    final path = 'storage/videos/$filename';
    
    final file = File(path);
    if (!await file.exists()) {
      return res.status(404).json({
        'error': 'Video not found',
      });
    }
    
    // Get file size
    final size = await file.length();
    
    // Handle range requests for video streaming
    final rangeHeader = req.headers.value('range');
    if (rangeHeader != null) {
      // Parse range header
      final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(rangeHeader);
      if (match != null) {
        final start = int.parse(match.group(1)!);
        final end = match.group(2)!.isNotEmpty ? 
            int.parse(match.group(2)!) : size - 1;
        
        // Validate range
        if (start >= 0 && start < size && end < size && start <= end) {
          final length = end - start + 1;
          
          // Set appropriate headers
          res.headers.set('Content-Range', 'bytes $start-$end/$size');
          res.headers.set('Accept-Ranges', 'bytes');
          res.headers.set('Content-Length', '$length');
          res.headers.set('Content-Type', 'video/mp4');
          
          // Stream the range
          res.status(206); // Partial Content
          final stream = file.openRead(start, end + 1);
          return res.stream(stream);
        }
      }
    }
    
    // If no range requested or invalid range, stream the entire file
    res.headers.set('Content-Length', '$size');
    res.headers.set('Content-Type', 'video/mp4');
    res.headers.set('Accept-Ranges', 'bytes');
    
    final stream = file.openRead();
    return res.stream(stream);
  });
```

## File Validation

Implement file validation to ensure uploaded files meet your requirements:

```dart
bool validateFile(FileFormField file, {
  List<String>? allowedExtensions,
  int? maxSizeBytes,
}) {
  // Check file extension
  if (allowedExtensions != null) {
    final extension = file.filename.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return false;
    }
  }
  
  // Check file size
  if (maxSizeBytes != null && file.size > maxSizeBytes) {
    return false;
  }
  
  return true;
}

Router router = Router()
  .post('upload-image', (req, res, pathArgs) async {
    if (!req.hasFormData) {
      return res.status(400).json({
        'error': 'No form data provided',
      });
    }
    
    final formData = await req.formData;
    final imageFile = formData.file('image');
    
    if (imageFile == null) {
      return res.status(400).json({
        'error': 'No image provided',
      });
    }
    
    // Validate image file
    if (!validateFile(
      imageFile,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
      maxSizeBytes: 5 * 1024 * 1024, // 5MB
    )) {
      return res.status(400).json({
        'error': 'Invalid file. Only JPG, JPEG, PNG, and GIF up to 5MB are allowed.',
      });
    }
    
    // Process the valid image
    final path = 'storage/images/${imageFile.filename}';
    await imageFile.save(path);
    
    return res.json({
      'message': 'Image uploaded successfully',
      'path': path,
    });
  });
```

## Security Considerations

1. **Validate File Types**: Always check file extensions and MIME types.

2. **Limit File Sizes**: Set a maximum size for uploads to prevent DoS attacks.

3. **Store Files Outside Web Root**: Keep uploaded files in a directory that's not directly accessible.

4. **Generate Random Filenames**: Rename uploaded files to prevent filename-based attacks.

5. **Implement Access Control**: Check user permissions before serving files.

6. **Scan for Malware**: For critical applications, consider scanning uploaded files.

7. **Rate Limiting**: Implement rate limiting for file uploads to prevent abuse.

---

## 📚 Documentation Navigation

### Implementation Examples
- **[← Routing Examples](routing_examples.md)** - File handling in practice
- **[Authentication →](authentication.md)** - Secure file access control
- **[Advanced Patterns →](advanced-usage-patterns.md)** - Complex file processing

### Security & Best Practices
- **[Best Practices & Security](best-practices-security.md)** - File security guidelines
- **[Integration Guides](integration-guides.md)** - Cloud storage services (AWS S3, Google Cloud)
- **[Database Operations](database.md)** - File metadata storage

### Reference & Support
- **[API Reference](api-reference.md)** - File management APIs
- **[Troubleshooting](troubleshooting-guide.md#file-upload-issues)** - File handling issues
- **[Server Setup](server-setup.md)** - Production file storage

### Architecture
- **[Architecture Overview](architecture-overview.md)** - File processing pipeline

---

📖 **[Back to Documentation Index](README.md)**
