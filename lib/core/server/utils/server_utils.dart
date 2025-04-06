import 'dart:io';

class ServerUtils {
  static String serverLink(HttpServer server) {
    String ip = server.address.address;
    if (ip == '0.0.0.0') ip = '127.0.0.1';
    return 'http://$ip:${server.port}';
  }
}
