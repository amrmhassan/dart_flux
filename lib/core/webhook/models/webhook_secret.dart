/// Configuration for webhook secret validation
class WebhookSecret {
  /// The secret key for validating webhook signatures
  final String secret;

  /// The header name where the signature is provided, defaults to 'x-hub-signature-256'
  final String headerName;

  /// Creates a new webhook secret configuration
  ///
  /// - [secret] is the secret key used to validate signatures
  /// - [headerName] is the name of the header containing the signature (default: 'x-hub-signature-256')
  const WebhookSecret({
    required this.secret,
    this.headerName = 'x-hub-signature-256',
  });
}
