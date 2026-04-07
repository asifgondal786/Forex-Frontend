import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/beginner_mode_provider.dart';
import '../../providers/automation_provider.dart';
import '../../providers/notification_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SettingsScreen
// Combines:
//   • Tajir design system (dark surface, card sections, _ToggleTile, _NavTile)
//   • Notification channels panel (in-app, email, SMS, WhatsApp, Telegram,
//     Discord, X, webhook) with debounced server sync
//   • Autonomous mode toggle, safety profile selector, min-confidence slider
//   • BeginnerModeProvider integration (daily loss cap, leverage guard)
//   • AutomationProvider integration (mode label display)
//   • Theme selector (light / dark / system) wired to ThemeController
//   • Profile editing stub (name / email)
//   • Security Center nav tile
//   • Sign-out + Delete account dialogs
// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Profile ──────────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController(text: 'Demo User');
  final _emailCtrl = TextEditingController(text: 'demo@tajir.app');
  bool _isEditingProfile = false;
  bool _savingProfile = false;

  // ── Theme ────────────────────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.dark;

  // ── Notification channels ────────────────────────────────────────────────
  bool _loadingChannels = false;
  bool _savingChannels = false;
  String? _channelError;
  Timer? _saveDebounce;

  Map<String, bool> _channels = {
    'in_app': true,
    'email': true,
    'sms': false,
    'whatsapp': false,
    'telegram': false,
    'discord': false,
    'x': false,
    'webhook': false,
  };

  // Channel detail controllers
  final _emailRecipientCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappNumCtrl = TextEditingController();
  final _telegramChatIdCtrl = TextEditingController();
  final _discordWebhookCtrl = TextEditingController();
  final _xWebhookCtrl = TextEditingController();
  final _genericWebhookCtrl = TextEditingController();
  final _smsWebhookCtrl = TextEditingController();
  final _whatsappWebhookCtrl = TextEditingController();

  // ── Autonomous mode ───────────────────────────────────────────────────────
  bool _autonomousEnabled = true;
  String _autonomousProfile = 'balanced'; // 'conservative' | 'balanced' | 'aggressive'
  double _minConfidence = 0.62;
  final _testPairCtrl = TextEditingController(text: 'EUR/USD');
  bool _sendingTest = false;

  // ── Alert type toggles ────────────────────────────────────────────────────
  bool _tradeAlerts = true;
  bool _riskAlerts = true;
  bool _marketAlerts = false;
  bool _aiAlerts = true;

  @override
  void initState() {
    super.initState();
    _emailRecipientCtrl.text = _emailCtrl.text;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChannels());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _emailRecipientCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappNumCtrl.dispose();
    _telegramChatIdCtrl.dispose();
    _discordWebhookCtrl.dispose();
    _xWebhookCtrl.dispose();
    _genericWebhookCtrl.dispose();
    _smsWebhookCtrl.dispose();
    _whatsappWebhookCtrl.dispose();
    _testPairCtrl.dispose();
    _saveDebounce?.cancel();
    super.dispose();
  }

  // ── Channel load / save ───────────────────────────────────────────────────

  Future<void> _loadChannels() async {
    if (!mounted) return;
    setState(() {
      _loadingChannels = true;
      _channelError = null;
    });
    try {
      // TODO: replace with real GET /api/notification-preferences
      await Future.delayed(const Duration(milliseconds: 500));
      // mock: leave defaults in place
    } catch (_) {
      if (mounted) setState(() => _channelError = 'Could not load channel settings.');
    } finally {
      if (mounted) setState(() => _loadingChannels = false);
    }
  }

  void _onChannelToggled(String key, bool value) {
    setState(() {
      _channels[key] = value;
      _channelError = null;
    });
    _scheduleChannelSave();
  }

  void _scheduleChannelSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _saveChannels(showSnack: false),
    );
  }

  Future<void> _saveChannels({bool showSnack = true}) async {
    if (!mounted) return;
    setState(() {
      _savingChannels = true;
      _channelError = null;
    });
    try {
      // TODO: replace with real PATCH /api/notification-preferences
      await Future.delayed(const Duration(milliseconds: 350));
      if (showSnack && mounted) {
        _showSnack('Notification settings saved', success: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _channelError = 'Failed to save. Please try again.');
        _showSnack('Failed to save notification settings', success: false);
      }
    } finally {
      if (mounted) setState(() => _savingChannels = false);
    }
  }

  // ── Autonomous mode ───────────────────────────────────────────────────────

  void _onAutonomousToggled(bool value) {
    setState(() {
      _autonomousEnabled = value;
      _channelError = null;
    });
    _scheduleChannelSave();
  }

  void _onProfileChanged(String? profile) {
    if (profile == null) return;
    setState(() => _autonomousProfile = profile);
    _scheduleChannelSave();
  }

  void _onConfidenceChanged(double value) {
    setState(() => _minConfidence = value.clamp(0.4, 0.95));
    _scheduleChannelSave();
  }

  Future<void> _sendTestAlert() async {
    final pair = _testPairCtrl.text.trim().toUpperCase();
    if (pair.isEmpty || !pair.contains('/')) {
      setState(() => _channelError = 'Enter a valid pair like EUR/USD.');
      return;
    }
    setState(() {
      _sendingTest = true;
      _channelError = null;
    });
    try {
      // TODO: replace with real POST /api/autonomous/test-alert
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _showSnack('Test alert sent for $pair', success: true);
    } catch (_) {
      if (mounted) _showSnack('Failed to send test alert', success: false);
    } finally {
      if (mounted) setState(() => _sendingTest = false);
    }
  }

  // ── Profile save ──────────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    try {
      // TODO: replace with real PATCH /api/profile
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _isEditingProfile = false);
        _showSnack('Profile updated', success: true);
      }
    } catch (_) {
      if (mounted) _showSnack('Failed to update profile', success: false);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  // ── Sign out / Delete ─────────────────────────────────────────────────────

  Future<void> _confirmSignOut() async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      // TODO: call AuthProvider.signOut() then navigate to login
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      // TODO: call API to delete account
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  bool get _busy => _loadingChannels || _savingChannels || _sendingTest;

  String _normalizeProfile(String v) {
    final n = v.trim().toLowerCase();
    if (n == 'conservative' || n == 'aggressive') return n;
    return 'balanced';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // ── Profile ────────────────────────────────────────────────────
          _Section(
            title: 'Profile',
            scheme: scheme,
            children: [_buildProfileTile(scheme)],
          ),
          const SizedBox(height: 16),

          // ── Appearance ─────────────────────────────────────────────────
          _Section(
            title: 'Appearance',
            scheme: scheme,
            children: [
              _ThemeSelector(
                mode: _themeMode,
                onChanged: (m) => setState(() => _themeMode = m),
                scheme: scheme,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Notification Channels ──────────────────────────────────────
          _Section(
            title: 'Notification Channels',
            scheme: scheme,
            trailing: _loadingChannels
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.refresh_rounded,
                        size: 18, color: scheme.onSurface.withOpacity(0.5)),
                    onPressed: _busy ? null : _loadChannels,
                    tooltip: 'Refresh',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
            children: [
              _buildAutonomousPanel(scheme),
              _Divider(scheme),
              ..._buildChannelToggles(scheme),
              _Divider(scheme),
              _buildChannelFields(scheme),
              if (_savingChannels)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: scheme.primary),
                      ),
                      const SizedBox(width: 8),
                      Text('Saving…',
                          style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurface.withOpacity(0.5))),
                    ],
                  ),
                ),
              if (_channelError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    _channelError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _saveChannels(showSnack: true),
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Save Channel Settings'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Alert Types ────────────────────────────────────────────────
          _Section(
            title: 'Alert Types',
            scheme: scheme,
            children: [
              _ToggleTile(
                icon: Icons.trending_up_rounded,
                iconColor: Colors.green,
                title: 'Trade Signals',
                subtitle: 'New AI trade opportunities',
                value: _tradeAlerts,
                onChanged: (v) => setState(() => _tradeAlerts = v),
                scheme: scheme,
              ),
              _Divider(scheme),
              _ToggleTile(
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.red,
                title: 'Risk Alerts',
                subtitle: 'Drawdown and loss cap warnings',
                value: _riskAlerts,
                onChanged: (v) => setState(() => _riskAlerts = v),
                scheme: scheme,
              ),
              _Divider(scheme),
              _ToggleTile(
                icon: Icons.candlestick_chart_rounded,
                iconColor: Colors.purple,
                title: 'Market Events',
                subtitle: 'Major price movements & news',
                value: _marketAlerts,
                onChanged: (v) => setState(() => _marketAlerts = v),
                scheme: scheme,
              ),
              _Divider(scheme),
              _ToggleTile(
                icon: Icons.auto_awesome_rounded,
                iconColor: Colors.teal,
                title: 'AI Insights',
                subtitle: 'Weekly performance reports',
                value: _aiAlerts,
                onChanged: (v) => setState(() => _aiAlerts = v),
                scheme: scheme,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Safety ─────────────────────────────────────────────────────
          _Section(
            title: 'Safety',
            scheme: scheme,
            children: [
              Consumer<BeginnerModeProvider>(
                builder: (_, bm, __) => _ToggleTile(
                  icon: Icons.school_rounded,
                  iconColor: Colors.amber,
                  title: 'Beginner Protection',
                  subtitle: 'Daily loss cap, leverage warnings, guided tooltips',
                  value: bm.isEnabled,
                  onChanged: bm.setEnabled,
                  scheme: scheme,
                ),
              ),
              Consumer<BeginnerModeProvider>(
                builder: (_, bm, __) {
                  if (!bm.isEnabled) return const SizedBox.shrink();
                  return Column(
                    children: [
                      _Divider(scheme),
                      _BeginnerDetailsPanel(bm: bm, scheme: scheme),
                    ],
                  );
                },
              ),
              _Divider(scheme),
              Consumer<AutomationProvider>(
                builder: (_, auto, __) => _InfoTile(
                  icon: Icons.smart_toy_rounded,
                  iconColor: Colors.blue,
                  title: 'Automation Mode',
                  value: auto.modeLabel,
                  scheme: scheme,
                  onTap: () {
                    // Navigate to automation screen tab
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Account ────────────────────────────────────────────────────
          _Section(
            title: 'Account',
            scheme: scheme,
            children: [
              _NavTile(
                icon: Icons.security_rounded,
                iconColor: Colors.blue,
                title: 'Security Center',
                subtitle: 'Two-factor auth, active sessions, API keys',
                onTap: () {
                  // TODO: Navigator.pushNamed(context, AppRoutes.security);
                },
                scheme: scheme,
              ),
              _Divider(scheme),
              _NavTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: Colors.indigo,
                title: 'Privacy Policy',
                subtitle: 'View our privacy policy',
                onTap: () {},
                scheme: scheme,
              ),
              _Divider(scheme),
              _NavTile(
                icon: Icons.description_outlined,
                iconColor: Colors.indigo,
                title: 'Terms of Service',
                subtitle: 'View terms of service',
                onTap: () {},
                scheme: scheme,
              ),
              _Divider(scheme),
              _NavTile(
                icon: Icons.logout_rounded,
                iconColor: Colors.red,
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                onTap: _confirmSignOut,
                scheme: scheme,
                destructive: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Danger Zone ────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'DANGER ZONE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Colors.red.withOpacity(0.8),
                    ),
                  ),
                ),
                _NavTile(
                  icon: Icons.delete_forever_rounded,
                  iconColor: Colors.red,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account and all data',
                  onTap: _confirmDeleteAccount,
                  scheme: scheme,
                  destructive: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Version ────────────────────────────────────────────────────
          Center(
            child: Text(
              'Tajir v1.0.0 • Phase 12',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Profile tile
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildProfileTile(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar row
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: scheme.primary.withOpacity(0.2),
                child: Text(
                  _nameCtrl.text.isNotEmpty
                      ? _nameCtrl.text[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameCtrl.text,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      _emailCtrl.text,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _isEditingProfile = !_isEditingProfile;
                  if (!_isEditingProfile) {
                    // Cancel: restore
                    _nameCtrl.text = 'Demo User';
                    _emailCtrl.text = 'demo@tajir.app';
                  }
                }),
                child: Text(
                  _isEditingProfile ? 'Cancel' : 'Edit',
                  style: TextStyle(fontSize: 13, color: scheme.primary),
                ),
              ),
            ],
          ),
          if (_isEditingProfile) ...[
            const SizedBox(height: 16),
            _Field(
              ctrl: _nameCtrl,
              label: 'Name',
              icon: Icons.person_outline_rounded,
              scheme: scheme,
            ),
            const SizedBox(height: 10),
            _Field(
              ctrl: _emailCtrl,
              label: 'Email',
              icon: Icons.email_outlined,
              scheme: scheme,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingProfile ? null : _saveProfile,
                child: _savingProfile
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Profile'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Autonomous mode panel
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAutonomousPanel(ColorScheme scheme) {
    final confidencePct = (_minConfidence * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.primary.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.smart_toy_rounded,
                      color: Colors.purple, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Autonomous Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        _autonomousEnabled
                            ? 'Deep-study safety gates are active'
                            : 'Autonomous safety gates disabled',
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _autonomousEnabled,
                  onChanged: _busy ? null : _onAutonomousToggled,
                  activeColor: scheme.primary,
                ),
              ],
            ),

            if (_autonomousEnabled) ...[
              const SizedBox(height: 14),

              // Safety Profile dropdown
              Text(
                'SAFETY PROFILE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: scheme.onSurface.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 6),
              _ProfileSelector(
                value: _autonomousProfile,
                onChanged: _busy ? null : _onProfileChanged,
                scheme: scheme,
              ),
              const SizedBox(height: 14),

              // Min confidence slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Min AI Confidence',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: scheme.onSurface,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$confidencePct%',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _minConfidence,
                min: 0.4,
                max: 0.95,
                divisions: 11,
                label: '$confidencePct%',
                onChanged: _busy ? null : _onConfidenceChanged,
              ),

              // Test alert
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _CompactField(
                      ctrl: _testPairCtrl,
                      hint: 'EUR/USD',
                      label: 'Test Pair',
                      icon: Icons.show_chart_rounded,
                      enabled: !_busy,
                      scheme: scheme,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 40,
                    child: TextButton.icon(
                      onPressed: _busy ? null : _sendTestAlert,
                      icon: _sendingTest
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined, size: 16),
                      label: Text(_sendingTest ? 'Sending…' : 'Test'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Channel toggles
  // ─────────────────────────────────────────────────────────────────────────

  static const _channelMeta = <String, (IconData, Color, String, String)>{
    'in_app': (Icons.phone_iphone_rounded, Colors.blue, 'In-App', 'Alerts inside the app'),
    'email': (Icons.email_outlined, Colors.orange, 'Email', 'Deep-study alerts via email'),
    'sms': (Icons.sms_outlined, Colors.green, 'SMS', 'Urgent alerts to phone SMS'),
    'whatsapp': (Icons.chat_bubble_outline_rounded, Color(0xFF25D366), 'WhatsApp', 'Concise alerts to WhatsApp'),
    'telegram': (Icons.telegram_rounded, Color(0xFF229ED9), 'Telegram', 'Alerts to Telegram bot'),
    'discord': (Icons.forum_outlined, Color(0xFF5865F2), 'Discord', 'Alerts to Discord webhook'),
    'x': (Icons.alternate_email_rounded, Colors.black87, 'X (Twitter)', 'Alerts via X integration'),
    'webhook': (Icons.link_rounded, Colors.grey, 'Webhook', 'Full payload to your automation'),
  };

  List<Widget> _buildChannelToggles(ColorScheme scheme) {
    final entries = _channelMeta.entries.toList();
    final widgets = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      final key = entries[i].key;
      final (icon, color, title, sub) = entries[i].value;
      if (i > 0) widgets.add(_Divider(scheme));
      widgets.add(_ToggleTile(
        icon: icon,
        iconColor: color,
        title: title,
        subtitle: sub,
        value: _channels[key] ?? false,
        onChanged: _busy ? (_) {} : (v) => _onChannelToggled(key, v),
        scheme: scheme,
      ));
    }
    return widgets;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Channel detail fields
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildChannelFields(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHANNEL DETAILS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: scheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 10),
          if (_channels['email'] == true)
            _CompactField(
              ctrl: _emailRecipientCtrl,
              label: 'Email Recipient',
              hint: 'yourname@gmail.com',
              icon: Icons.email_outlined,
              enabled: !_busy,
              scheme: scheme,
            ),
          if (_channels['sms'] == true)
            _CompactField(
              ctrl: _phoneCtrl,
              label: 'SMS Phone Number',
              hint: '+1234567890',
              icon: Icons.sms_outlined,
              enabled: !_busy,
              scheme: scheme,
            ),
          if (_channels['whatsapp'] == true) ...[
            _CompactField(
              ctrl: _whatsappNumCtrl,
              label: 'WhatsApp Number',
              hint: '+1234567890',
              icon: Icons.chat_bubble_outline_rounded,
              enabled: !_busy,
              scheme: scheme,
            ),
            _CompactField(
              ctrl: _whatsappWebhookCtrl,
              label: 'WhatsApp Gateway URL',
              hint: 'https://your-gateway.example.com/send',
              icon: Icons.link_rounded,
              enabled: !_busy,
              scheme: scheme,
            ),
          ],
          if (_channels['telegram'] == true)
            _CompactField(
              ctrl: _telegramChatIdCtrl,
              label: 'Telegram Chat ID',
              hint: 'e.g. 123456789',
              icon: Icons.telegram_rounded,
              enabled: !_busy,
              scheme: scheme,
            ),
          if (_channels['discord'] == true)
            _CompactField(
              ctrl: _discordWebhookCtrl,
              label: 'Discord Webhook URL',
              hint: 'https://discord.com/api/webhooks/...',
              icon: Icons.forum_outlined,
              enabled: !_busy,
              scheme: scheme,
            ),
          if (_channels['x'] == true)
            _CompactField(
              ctrl: _xWebhookCtrl,
              label: 'X Integration Webhook URL',
              hint: 'https://your-x-service.example.com/post',
              icon: Icons.alternate_email_rounded,
              enabled: !_busy,
              scheme: scheme,
            ),
          if (_channels['webhook'] == true)
            _CompactField(
              ctrl: _genericWebhookCtrl,
              label: 'Generic Webhook URL',
              hint: 'https://your-webhook.example.com/notify',
              icon: Icons.link_rounded,
              enabled: !_busy,
              scheme: scheme,
            ),
          if (_channels['sms'] == true)
            _CompactField(
              ctrl: _smsWebhookCtrl,
              label: 'SMS Gateway Webhook URL',
              hint: 'https://your-sms-gateway.example.com/send',
              icon: Icons.sms_outlined,
              enabled: !_busy,
              scheme: scheme,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Beginner details panel
// ─────────────────────────────────────────────────────────────────────────────

class _BeginnerDetailsPanel extends StatelessWidget {
  final BeginnerModeProvider bm;
  final ColorScheme scheme;

  const _BeginnerDetailsPanel({required this.bm, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final progress = bm.dailyCapProgress;
    final progressColor = progress >= 0.9
        ? Colors.red
        : progress >= 0.7
            ? Colors.orange
            : Colors.green;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily loss cap progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Loss Cap',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  '\$${bm.dailyLossUsed.toStringAsFixed(0)} / \$${bm.dailyLossCap.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: scheme.onSurface.withOpacity(0.1),
                color: progressColor,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),

            // Cap slider
            Text(
              'Adjust Cap',
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
            Slider(
              value: bm.dailyLossCap.clamp(10, 1000),
              min: 10,
              max: 1000,
              divisions: 99,
              label: '\$${bm.dailyLossCap.toStringAsFixed(0)}',
              onChanged: bm.setDailyLossCap,
            ),

            const SizedBox(height: 4),

            // Max leverage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Max Leverage',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: scheme.onSurface,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '1:${bm.maxLeverage.toInt()}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: bm.maxLeverage.clamp(1, 100),
              min: 1,
              max: 100,
              divisions: 99,
              label: '1:${bm.maxLeverage.toInt()}',
              onChanged: bm.setMaxLeverage,
            ),

            if (bm.isDailyLossCapReached)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block_rounded, color: Colors.red, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Daily loss cap reached — new trades are blocked until tomorrow.',
                        style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile selector (conservative / balanced / aggressive)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String?>? onChanged;
  final ColorScheme scheme;

  const _ProfileSelector({
    required this.value,
    required this.onChanged,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      ('conservative', Icons.shield_rounded, Colors.green, 'Conservative'),
      ('balanced', Icons.balance_rounded, Colors.blue, 'Balanced'),
      ('aggressive', Icons.bolt_rounded, Colors.orange, 'Aggressive'),
    ];

    return Row(
      children: options.map((opt) {
        final (key, icon, color, label) = opt;
        final selected = value == key;
        return Expanded(
          child: GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.15) : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon,
                      size: 16,
                      color: selected ? color : scheme.onSurface.withOpacity(0.4)),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? color : scheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme selector
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeSelector extends StatelessWidget {
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;
  final ColorScheme scheme;

  const _ThemeSelector({
    required this.mode,
    required this.onChanged,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final opts = [
      (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
      (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
      (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.palette_outlined,
                    color: Colors.indigo, size: 18),
              ),
              const SizedBox(width: 14),
              Text(
                'Theme',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: opts.map((opt) {
              final (themeMode, icon, label) = opt;
              final selected = mode == themeMode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(themeMode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: selected
                              ? scheme.onPrimary
                              : scheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? scheme.onPrimary
                                : scheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable layout primitives
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final ColorScheme scheme;
  final Widget? trailing;

  const _Section({
    required this.title,
    required this.children,
    required this.scheme,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: scheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ColorScheme scheme;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: scheme.onSurface,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: scheme.primary,
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final ColorScheme scheme;
  final bool destructive;

  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.scheme,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: destructive ? Colors.red : scheme.onSurface,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withOpacity(0.5),
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: scheme.onSurface.withOpacity(0.3),
        size: 20,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final ColorScheme scheme;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.scheme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: scheme.onSurface,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final ColorScheme scheme;
  const _Divider(this.scheme);

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: scheme.outline.withOpacity(0.1),
      indent: 66,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text field components
// ─────────────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final ColorScheme scheme;
  final TextInputType keyboardType;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
    required this.scheme,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(color: scheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: scheme.onSurface.withOpacity(0.5)),
      ),
    );
  }
}

class _CompactField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final ColorScheme scheme;

  const _CompactField({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    required this.enabled,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        style: TextStyle(color: scheme.onSurface, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon,
              size: 16, color: scheme.onSurface.withOpacity(0.4)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}
