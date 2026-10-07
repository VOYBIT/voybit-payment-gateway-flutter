# Voybit checkout for Flutter

Your server creates the payment and returns `checkout_url`. This package does not take an API key.

```yaml
dependencies:
  voybit_payment_gateway:
    git:
      url: https://github.com/VOYBIT/voybit-payment-gateway-flutter.git
```

```dart
await openCheckout(checkoutUrl);

final status = await VoybitCheckout().status(publicId);
if (status.confirmed) {
  // paid or overpaid — refresh the screen only
}
```

`openCheckout` opens `https://voybit.com/pay/{id}` in the system browser. Fulfil the order from the webhook on your server. `status` calls `GET https://api.voybit.com/api/v1/checkout/{public_id}` and is only for the screen.

For iOS and Android. Not published to pub.dev.
