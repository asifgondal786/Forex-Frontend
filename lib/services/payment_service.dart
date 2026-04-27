// lib/services/payment_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';       // flutter_stripe: ^10.x
import 'package:url_launcher/url_launcher.dart';           // for PayFast redirect

class PaymentService extends ChangeNotifier {

  // ── Stripe ─────────────────────────────────────────────────────────────────
  // 1. Your backend creates a PaymentIntent and returns clientSecret
  // 2. flutter_stripe presents the payment sheet
  // 3. On success, backend webhook sets userPlan = pro in Firestore
  Future<bool> initiateStripe({
    required String planId,
    required double amountUsd,
  }) async {
    try {
      // TODO: POST /api/v1/payments/stripe/create-intent
      // returns { clientSecret: '...' }
      const clientSecret = 'pi_xxx_secret_xxx'; // replace with API call

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Tajir',
          style: ThemeMode.dark,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return false;
      rethrow;
    }
  }

  // ── PayFast ────────────────────────────────────────────────────────────────
  // PayFast uses a redirect flow — you build a signed URL,
  // open it in a WebView or browser, listen for return_url callback
  Future<bool> initiatePayFast({
    required String planId,
    required double amountUsd,
  }) async {
    // TODO: POST /api/v1/payments/payfast/create-session
    // returns { redirectUrl: 'https://sandbox.payfast.co.za/eng/process?...' }
    const redirectUrl = 'https://sandbox.payfast.co.za/eng/process'; // replace

    final uri = Uri.parse(redirectUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // TODO: listen for deep-link callback to your return_url
      // e.g. tajir://payment/success → resolve future true
      return true;
    }
    return false;
  }
}