# Voybit checkout for Flutter

## Get an API key

The API key is created in the dashboard and used only on your server. This library opens the `checkout_url` that server returns.

1. Create an account at [dashboard.voybit.com](https://dashboard.voybit.com).
2. Open **Gateways** and create a payment gateway. Keep it enabled.
3. Open **API keys**, choose **Create secret key**, and bind it to that gateway. Copy the full `vb_live_…` value once. Your server sends it as `X-Voybit-Api-Key` when it creates the payment.

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
