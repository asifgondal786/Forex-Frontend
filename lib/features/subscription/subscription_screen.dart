// lib/features/subscription/subscription_screen.dart
//
// Tajir — Subscription screen
// - No free plan. 10-day trial auto-assigned on signup (handled by backend).
// - Single paid plan: Pro $10/mo
// - Payment: Stripe (international) | PayFast (Pakistan — Easypaisa, JazzCash, cards)
// - Soft lock after trial: read-only, signals/agent disabled

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/payment_service.dart'; // wire Stripe + PayFast here

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBg     = Color(0xFF0A0E1A);
const _kCard   = Color(0xFF161D2E);
const _kBorder = Color(0xFF1E2A3D);
const _kGold   = Color(0xFFD4A853);
const _kGreen  = Color(0xFF00C896);
const _kRed    = Color(0xFFFF4560);
const _kText   = Color(0xFFE2E8F0);
const _kSub    = Color(0xFF64748B);

// ── Single Pro plan ───────────────────────────────────────────────────────────
const _kPlanPrice    = 10.0;
const _kPlanFeatures = [
  'All 8 currency pairs',
  'Advanced AI signals',
  'Semi-auto agent mode',
  'Full chart analysis',
  'Risk Guardian limits',
  'Push notifications',
  'Claude + DeepSeek NLP',
  'Priority support',
];

// ── Gateway model ─────────────────────────────────────────────────────────────
enum _Gateway { stripe, payfast }

class _GatewayOption {
  final _Gateway id;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _GatewayOption({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const _gateways = [
  _GatewayOption(
    id: _Gateway.payfast,
    name: 'PayFast',
    subtitle: 'Easypaisa · JazzCash · Pakistani cards',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF00A86B),
  ),
  _GatewayOption(
    id: _Gateway.stripe,
    name: 'Stripe',
    subtitle: 'Visa · Mastercard · Apple Pay · Google Pay',
    icon: Icons.credit_card_rounded,
    color: Color(0xFF635BFF),
  ),
];

// ═════════════════════════════════════════════════════════════════════════════
// Entry points
// ═════════════════════════════════════════════════════════════════════════════

/// Call this when trial expires — replaces the current route with paywall.
class SubscriptionScreen extends StatefulWidget {
  /// [isTrialExpired] true = user hit soft lock, show expired messaging.
  /// false = user navigating voluntarily (e.g. from settings).
  final bool isTrialExpired;

  const SubscriptionScreen({super.key, this.isTrialExpired = false});

  static Future<void> show(BuildContext context, {bool isTrialExpired = false}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubscriptionScreen(isTrialExpired: isTrialExpired),
      ),
    );
  }

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

// ═════════════════════════════════════════════════════════════════════════════
// State
// ═════════════════════════════════════════════════════════════════════════════
class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int      _step       = 0;   // 0 = plan overview, 1 = gateway select, 2 = success
  int      _gatewayIdx = 0;
  bool     _processing = false;

  _GatewayOption get _gateway => _gateways[_gatewayIdx];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back navigation when trial has expired (soft lock)
      canPop: !widget.isTrialExpired || _step == 2,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: switch (_step) {
            0 => _buildPlanOverview(),
            1 => _buildGatewaySelect(),
            _ => _buildSuccess(),
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _kBg,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: (_step == 1)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: _kText),
              onPressed: () => setState(() => _step = 0),
            )
          : (!widget.isTrialExpired && _step != 2)
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: _kText),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
      title: Text(
        switch (_step) {
          0 => widget.isTrialExpired ? 'Trial Ended' : 'Subscribe',
          1 => 'Payment',
          _ => 'You\'re all set!',
        },
        style: const TextStyle(
          color: _kText, fontSize: 17, fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
    );
  }

  // ── Step 0: Plan overview ──────────────────────────────────────────────────
  Widget _buildPlanOverview() {
    return SingleChildScrollView(
      key: const ValueKey('plan'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trial expired banner (shown only when soft-locked)
          if (widget.isTrialExpired) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kRed.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Your 10-day trial has ended',
                    style: TextStyle(
                      color: _kRed,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'The app is in read-only mode. Signals and the '
                    'agent are paused until you subscribe.',
                    style: TextStyle(color: _kSub, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Plan card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kGold.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'TAJIR PRO',
                        style: TextStyle(
                          color: _kGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      '\$10',
                      style: TextStyle(
                        color: _kGold,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      ' / mo',
                      style: TextStyle(color: _kSub, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cancel anytime · billed monthly',
                  style: TextStyle(color: _kSub, fontSize: 11),
                ),
                const SizedBox(height: 18),
                const Divider(color: _kBorder),
                const SizedBox(height: 14),
                ..._kPlanFeatures.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: _kGold, size: 16),
                        const SizedBox(width: 10),
                        Text(f,
                            style: const TextStyle(
                                color: _kText, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // CTA
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () => setState(() => _step = 1),
              style: FilledButton.styleFrom(
                backgroundColor: _kGold,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Subscribe — \$10 / month',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '256-bit SSL · Cancel anytime · No hidden fees',
              style: TextStyle(color: _kSub, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Gateway selection ──────────────────────────────────────────────
  Widget _buildGatewaySelect() {
    return SingleChildScrollView(
      key: const ValueKey('gateway'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order summary chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGold.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: _kGold, size: 16),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tajir Pro — monthly',
                    style: TextStyle(color: _kText, fontSize: 13),
                  ),
                ),
                const Text(
                  '\$10.00 USD',
                  style: TextStyle(
                      color: _kGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'PAYMENT METHOD',
            style: TextStyle(
                color: _kSub,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1),
          ),
          const SizedBox(height: 10),

          // Gateway tiles
          ..._gateways.asMap().entries.map(
            (e) => _GatewayTile(
              option:   e.value,
              selected: e.key == _gatewayIdx,
              onTap:    () => setState(() => _gatewayIdx = e.key),
            ),
          ),

          const SizedBox(height: 20),

          // Gateway-specific info
          _buildGatewayInfo(),

          const SizedBox(height: 24),

          // Security row
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, color: _kSub, size: 12),
              SizedBox(width: 6),
              Text(
                '256-bit SSL encrypted · Cancel anytime',
                style: TextStyle(color: _kSub, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pay button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _processing ? null : _initiatePayment,
              style: FilledButton.styleFrom(
                backgroundColor: _kGold,
                disabledBackgroundColor: _kGold.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _processing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Text(
                      'Pay \$10.00',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGatewayInfo() {
    if (_gateway.id == _Gateway.payfast) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF00A86B).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF00A86B).withValues(alpha: 0.2)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ll be redirected to PayFast\'s secure checkout. '
              'Pay via Easypaisa, JazzCash, or any Pakistani debit/credit card.',
              style: TextStyle(color: _kText, fontSize: 13, height: 1.5),
            ),
            SizedBox(height: 8),
            Text(
              'Amount charged in PKR at current exchange rate.',
              style: TextStyle(color: _kSub, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF635BFF).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF635BFF).withValues(alpha: 0.2)),
      ),
      child: const Text(
        'You\'ll be redirected to Stripe\'s secure checkout. '
        'Pay with any Visa, Mastercard, Apple Pay, or Google Pay.',
        style: TextStyle(color: _kText, fontSize: 13, height: 1.5),
      ),
    );
  }

  // ── Step 2: Success ────────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return Center(
      key: const ValueKey('success'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: _kGreen, size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'Subscription Active!',
              style: TextStyle(
                  color: _kText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'Welcome to Tajir Pro.\nAll features are now unlocked.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kSub, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 32),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What\'s unlocked',
                    style: TextStyle(
                        color: _kText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  ..._kPlanFeatures.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check_rounded,
                              color: _kGold, size: 15),
                          const SizedBox(width: 8),
                          Text(f,
                              style: const TextStyle(
                                  color: _kSub, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style: FilledButton.styleFrom(
                  backgroundColor: _kGold,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Go to Dashboard',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Payment initiation ─────────────────────────────────────────────────────
  Future<void> _initiatePayment() async {
    setState(() => _processing = true);
    try {
      final paymentService = context.read<PaymentService>();

      final success = await switch (_gateway.id) {
        _Gateway.stripe  => paymentService.initiateStripe(
            planId: 'pro_monthly',
            amountUsd: _kPlanPrice,
          ),
        _Gateway.payfast => paymentService.initiatePayFast(
            planId: 'pro_monthly',
            amountUsd: _kPlanPrice,
          ),
      };

      if (!mounted) return;
      if (success) {
        setState(() => _step = 2);
        // Update user plan in provider — triggers Firestore listener
        // which propagates soft-lock removal across the app
        // Temporary — remove once refreshUserPlan is added to AuthProvider
        debugPrint('TODO: refresh user plan after payment');
      } else {
        _showError('Payment was not completed. Please try again.');
      }
    } catch (e) {
      _showError('Something went wrong: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _kRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Gateway tile widget ───────────────────────────────────────────────────────
class _GatewayTile extends StatelessWidget {
  final _GatewayOption option;
  final bool selected;
  final VoidCallback onTap;

  const _GatewayTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? option.color.withValues(alpha: 0.08) : _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? option.color : _kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(option.icon, color: option.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.name,
                      style: const TextStyle(
                          color: _kText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(option.subtitle,
                      style: const TextStyle(color: _kSub, fontSize: 11)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? option.color : Colors.transparent,
                border: Border.all(
                  color: selected ? option.color : _kSub,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 11)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}