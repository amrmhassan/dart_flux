import 'dart:io';
import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/errors/types/not_found_error.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:mime/mime.dart';

class ResponseUtils {
  /// Sends a chunked file response to the client.
  /// This method allows for partial content transfer (e.g., for large files or resuming downloads).
  ///
  /// - If a "Range" header is provided, it sends only the requested byte range of the file.
  /// - If no range is provided, it sends the full file.
  Future<void> sendChunkedFile(FluxRequest req, File file) async {
    if (!file.existsSync()) {
      throw NotFoundError('file not found');
    }

    String fileName = file.path.split('/').last;
    String? mime = lookupMimeType(file.path) ?? 'application/octet-stream';

    int fileLength = file.lengthSync();
    int start = 0;
    int end = fileLength - 1;

    String? range = req.headers.value('range');
    if (range != null) {
      final parts = range.split('=');
      final positions = parts[1].split('-');
      start = int.parse(positions[0]);
      end =
          (positions.length < 2 || positions[1].isEmpty)
              ? fileLength - 1
              : int.parse(positions[1]);

      req.response.statusCode = HttpStatus.partialContent;
      req.response.headers
        ..contentType = ContentType.parse(mime)
        ..add('Content-Disposition', 'attachment; filename=$fileName')
        ..add('Accept-Ranges', 'bytes')
        ..add('Content-Range', 'bytes $start-$end/$fileLength')
        ..contentLength = end - start + 1;
    } else {
      req.response.statusCode = HttpStatus.ok;
      req.response.headers
        ..contentType = ContentType.parse(mime)
        ..add('Content-Disposition', 'attachment; filename=$fileName')
        ..add('Accept-Ranges', 'bytes')
        ..contentLength = fileLength;
    }

    try {
      final raf = await file.open();
      await raf.setPosition(start);
      final chunk = await raf.read(end - start + 1);
      await raf.close();
      await req.response.response.addStream(Stream.value(chunk));
    } catch (e) {
      // You can log the error here if needed
      throw ServerError.fromCatch(msg: 'Error while sending file', e: e);
    } finally {
      // await req.response.close();
    }
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
