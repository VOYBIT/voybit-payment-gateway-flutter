import 'dart:io';

import 'package:voybit_payment_gateway/src/checkout.dart';
import 'package:test/test.dart';

void main() {
  const id = 'nYVvXxsYGr5LZk8Dn7hU0Q';

  test('accepts a voybit checkout URL', () {
    expect(VoybitCheckout.publicId('https://voybit.com/pay/$id'), id);
    expect(() => VoybitCheckout.publicId('https://example.com/pay/$id'), throwsA(isA<CheckoutException>()));
  });

  test('reads the top-level status', () {
    const body = '{"deposit_instructions":{"status":"ready","address":"secret-address"},"status":"pending","public_id":"$id","checkout_url":"https://voybit.com/pay/$id"}';
    final status = VoybitCheckout.parseStatus(body, id);
    expect(status.status, 'pending');
    expect(status.confirmed, isFalse);
    expect(status.toString().contains('secret-address'), isFalse);
  });

  test('status request does not send an API key', () async {
    final server = await HttpServer.bind('127.0.0.1', 0);
    String? apiKey;
    server.listen((request) async {
      apiKey = request.headers.value('x-voybit-api-key');
      request.response.statusCode = 200;
      request.response.write('{"status":"paid","public_id":"$id","checkout_url":"https://voybit.com/pay/$id","deposit_instructions":{"address":"secret-address"}}');
      await request.response.close();
    });
    final client = HttpClient();
    final checkout = VoybitCheckout(apiOrigin: 'http://${server.address.host}:${server.port}', client: client);
    final status = await checkout.status(id);
    expect(status.confirmed, isTrue);
    expect(apiKey, isNull);
    client.close();
    await server.close();
  });
}
