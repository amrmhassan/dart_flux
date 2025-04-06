import 'dart:io';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:mime/mime.dart';

class ResponseUtils {
  /// Sends a chunked file response to the client.
  /// This method allows for partial content transfer (e.g., for large files or resuming downloads).
  ///
  /// - If a "Range" header is provided, it sends only the requested byte range of the file.
  /// - If no range is provided, it sends the full file.
  void sendChunkedFile(FluxRequest req, File file) {
    if (!file.existsSync()) {
      file.createSync(recursive: true);
      // throw Exception('File $filePath doesn\'t exist'); // Uncomment if desired
    }

    // Get file name and MIME type
    String fileName = file.path.split('/').last;
    String? mime = lookupMimeType(file.path);

    // Set basic response headers
    req.response.statusCode = HttpStatus.ok;
    req.response.headers
      ..contentType = ContentType.parse(mime ?? 'application/octet-stream')
      ..add('Content-Disposition', 'attachment; filename=$fileName')
      ..add('Accept-Ranges', 'bytes');

    int fileLength = file.lengthSync();
    int start = 0;
    int end = fileLength - 1;

    // Handle "Range" header if present (supports partial content requests)
    String? range = req.headers.value('range');
    if (range != null) {
      List<String> parts = range.split('=');
      List<String> positions = parts[1].split('-');
      start = int.parse(positions[0]);
      end =
          positions.length < 2 || int.tryParse(positions[1]) == null
              ? fileLength - 1
              : int.parse(positions[1]);
      req.response.statusCode = HttpStatus.partialContent;
      req.response.headers
        ..contentLength = end - start + 1
        ..add('Content-Range', 'bytes $start-$end/$fileLength');
    } else {
      req.response.headers.contentLength = fileLength;
    }

    // Open file and send the appropriate chunk or full file
    RandomAccessFile raf = file.openSync();
    raf.setPositionSync(start);
    Stream<List<int>> fileStream = Stream.value(raf.readSync(end - start + 1));
    req.response.response
        .addStream(
          fileStream.handleError(
            (e) => throw Exception('Error reading file: $e'),
          ),
        )
        .then((_) async {
          raf.closeSync();
          await req.response.close();
        });
  }

  /// Streams a file to the response with support for range requests.
  /// This is a more modern approach to handling large files.
  ///
  /// - Supports partial content transfer if the "Range" header is present.
  /// - If no range is provided, it sends the entire file.
  Future<void> streamV2(HttpRequest req, File file) async {
    int length = file.lengthSync();
    String? mime = lookupMimeType(file.path);

    // Handle "Range" header if present
    String? rangeHeader = req.headers.value(HttpHeaders.rangeHeader);
    if (rangeHeader != null) {
      var rangeBytes = rangeHeader.replaceFirst('bytes=', '').split('-');
      int start = int.parse(rangeBytes[0]);
      int end = rangeBytes[1].isEmpty ? length - 1 : int.parse(rangeBytes[1]);

      req.response.statusCode = HttpStatus.partialContent;
      req.response.headers
        ..contentType = ContentType.parse(mime ?? 'audio/mpeg')
        ..add('Accept-Ranges', 'bytes')
        ..add('Content-Range', 'bytes $start-$end/$length')
        ..contentLength = end - start;

      var raf = file.openSync();
      await raf.setPosition(start);
      await file
          .openRead(start, end)
          .pipe(req.response); // Pipe the file stream to the response

      await raf.close();
    } else {
      // If no range, send the entire file
      req.response.headers
        ..contentType = ContentType.parse(mime ?? 'audio/mpeg')
        ..contentLength = length;
      await file.openRead().pipe(
        req.response,
      ); // Pipe the entire file to the response
    }

    await req.response.close();
  }
}
