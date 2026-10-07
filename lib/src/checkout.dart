import 'dart:convert';
import 'dart:io';

class CheckoutException implements Exception {
  CheckoutException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CheckoutStatus {
  CheckoutStatus({required this.publicId, required this.status, required this.checkoutUrl});

  final String publicId;
  final String status;
  final String checkoutUrl;
  bool get confirmed => status == 'paid' || status == 'overpaid';
}

class VoybitCheckout {
  VoybitCheckout({this.apiOrigin = defaultApiOrigin, HttpClient? client}) : _client = client ?? HttpClient();

  static const checkoutOrigin = 'https://voybit.com';
  static const defaultApiOrigin = 'https://api.voybit.com';
  static final _publicId = RegExp(r'^[A-Za-z0-9_-]{22}$');

  final String apiOrigin;
  final HttpClient _client;

  static String publicId(String checkoutUrl) {
    final uri = Uri.tryParse(checkoutUrl.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.toLowerCase() != 'voybit.com' || uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) {
      throw CheckoutException('checkout URL is invalid');
    }
    final path = uri.path.endsWith('/') ? uri.path.substring(0, uri.path.length - 1) : uri.path;
    const prefix = '/pay/';
    if (!path.startsWith(prefix)) throw CheckoutException('checkout URL is invalid');
    final id = path.substring(prefix.length);
    if (path != '$prefix$id' || !_publicId.hasMatch(id)) throw CheckoutException('checkout URL is invalid');
    return id;
  }

  static Uri checkoutUri(String publicId) {
    if (!_publicId.hasMatch(publicId)) throw CheckoutException('checkout URL is invalid');
    return Uri.parse('$checkoutOrigin/pay/$publicId');
  }

  Future<CheckoutStatus> status(String publicId) async {
    final id = VoybitCheckout.publicId(checkoutUri(publicId).toString());
    final request = await _client.getUrl(Uri.parse('$apiOrigin/api/v1/checkout/$id'));
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.userAgentHeader, 'voybit-payment-gateway-flutter/0.1.0');
    final response = await request.close().timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.drain<void>();
      throw CheckoutException('checkout status returned HTTP ${response.statusCode}');
    }
    final body = await utf8.decoder.bind(response).join();
    if (body.length > 1 << 20) throw CheckoutException('checkout status was too large');
    return parseStatus(body, id);
  }

  static CheckoutStatus parseStatus(String body, String publicId) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) throw CheckoutException('checkout status was not JSON');
    final status = decoded['status'];
    if (status is! String) throw CheckoutException('checkout status was not JSON');
    final id = decoded['public_id'] is String ? decoded['public_id'] as String : publicId;
    final checkoutUrl = decoded['checkout_url'] is String ? decoded['checkout_url'] as String : checkoutUri(id).toString();
    if (!_publicId.hasMatch(id)) throw CheckoutException('checkout status was not JSON');
    return CheckoutStatus(publicId: id, status: status, checkoutUrl: checkoutUrl);
  }

  void close() => _client.close();
}
