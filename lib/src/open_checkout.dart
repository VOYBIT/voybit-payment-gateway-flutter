import 'package:url_launcher/url_launcher.dart';
import 'package:voybit_payment_gateway/src/checkout.dart';

Future<void> openCheckout(String checkoutUrl) async {
  final uri = VoybitCheckout.checkoutUri(VoybitCheckout.publicId(checkoutUrl));
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) throw CheckoutException('checkout could not be opened');
}
