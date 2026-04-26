import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/agent_provider.dart';
import '../../services/api_service.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final _nlpCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _nlpLoading = false;
  final List<Map<String, String>> _chatHistory = [];

  @override
  void dispose() {
    _nlpCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendNlp() async {
    final msg = _nlpCtrl.text.trim();
    if (msg.isEmpty || _nlpLoading) return;
    _nlpCtrl.clear();
    setState(() {
      _chatHistory.add({'role': 'user', 'content': msg});
      _nlpLoading = true;
    });
    _scrollDown();
    try {
      final data = await context.read<ApiService>().sendNlpChat(_nlpCtrl.text.trim()), userId: _userId);
      final reply = data['response'] as String? ?? data['message'] as String? ?? 'No response.';
      setState(() => _chatHistory.add({'role': 'assistant', 'content': reply}));
    } catch (e) {
      setState(() => _chatHistory.add({'role': 'assistant', 'content': 'Error: $e'}));
    } finally {
      setState(() => _nlpLoading = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _confirmKill() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_rounded, color: AppColors.danger),
          SizedBox(width: 8),
          Text('Kill Agent', style: TextStyle(color: AppColors.textPrimary)),
        ]),
        content: const Text(
          'This will immediately stop the autonomous agent and cancel all pending trades. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(80, 40),
            ),
            child: const Text('KILL', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AgentProvider>().killAgent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final agent = context.watch<AgentProvider>();
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text('Agent Control',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  if (agent.isActive) _ModeChip(mode: agent.mode),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // Mode selector
                  _ModeSelector(
                    current: agent.mode,
                    isLoading: agent.isLoading,
                    onSelect: (m) => context.read<AgentProvider>().setMode(m),
                  ),
                  const SizedBox(height: 16),

                  // Kill switch â€” visible when active
                  if (agent.isActive) ...[
                    _KillSwitch(
                      isKilling: agent.isKilling,
                      onKill: _confirmKill,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Semi-auto pending trades
                  if (agent.mode == AgentMode.semiAuto &&
                      agent.pendingTrades.isNotEmpty) ...[
                    _SemiAutoSection(trades: agent.pendingTrades),
                    const SizedBox(height: 16),
                  ],

                  // Full-auto active trades
                  if (agent.mode == AgentMode.fullAuto) ...[
                    _FullAutoSection(
                      trades: agent.activeTrades,
                      pnl: agent.totalPnl,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Risk settings
                  const _RiskPanel(),
                  const SizedBox(height: 16),

                  // NLP chat
                  _NlpChat(
                    history: _chatHistory,
                    isLoading: _nlpLoading,
                    controller: _nlpCtrl,
                    onSend: _sendNlp,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Mode Chip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ModeChip extends StatelessWidget {
  final AgentMode mode;
  const _ModeChip({required this.mode});

  @override
  Widget build(BuildContext context) {
    final color = mode == AgentMode.fullAuto ? AppColors.accent : AppColors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color, blurRadius: 6)]),
          ),
          const SizedBox(width: 6),
          Text(
            mode == AgentMode.fullAuto ? 'FULL-AUTO' : 'SEMI-AUTO',
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Mode Selector â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ModeSelector extends StatelessWidget {
  final AgentMode current;
  final bool isLoading;
  final ValueChanged<AgentMode> onSelect;

  const _ModeSelector({
    required this.current, required this.isLoading, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Trading Mode',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _ModeCard(
              mode: AgentMode.off, current: current,
              label: 'OFF', icon: Icons.power_settings_new,
              color: AppColors.textMuted,
              desc: 'No automation',
              isLoading: isLoading, onTap: () => onSelect(AgentMode.off),
            )),
            const SizedBox(width: 10),
            Expanded(child: _ModeCard(
              mode: AgentMode.semiAuto, current: current,
              label: 'SEMI', icon: Icons.tune,
              color: AppColors.gold,
              desc: 'Approve trades',
              isLoading: isLoading, onTap: () => onSelect(AgentMode.semiAuto),
            )),
            const SizedBox(width: 10),
            Expanded(child: _ModeCard(
              mode: AgentMode.fullAuto, current: current,
              label: 'FULL', icon: Icons.smart_toy,
              color: AppColors.accent,
              desc: 'Autonomous',
              isLoading: isLoading, onTap: () => onSelect(AgentMode.fullAuto),
            )),
          ],
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final AgentMode mode;
  final AgentMode current;
  final String label;
  final IconData icon;
  final Color color;
  final String desc;
  final bool isLoading;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode, required this.current, required this.label,
    required this.icon, required this.color, required this.desc,
    required this.isLoading, required this.onTap,
  });

  bool get _selected => mode == current;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: _selected ? color.withAlpha(20) : AppColors.bg1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selected ? color : AppColors.border,
            width: _selected ? 1.5 : 1,
          ),
          boxShadow: _selected
              ? [BoxShadow(color: color.withAlpha(60), blurRadius: 12)]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: _selected ? color : AppColors.textMuted, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: _selected ? color : AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(desc,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Kill Switch â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _KillSwitch extends StatelessWidget {
  final bool isKilling;
  final VoidCallback onKill;
  const _KillSwitch({required this.isKilling, required this.onKill});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isKilling ? null : onKill,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.danger.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger.withAlpha(80), width: 1.5),
          boxShadow: [BoxShadow(color: AppColors.danger.withAlpha(30), blurRadius: 12)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isKilling
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.danger))
                : const Icon(Icons.stop_circle_outlined, color: AppColors.danger, size: 22),
            const SizedBox(width: 10),
            Text(
              isKilling ? 'Killing Agent...' : 'âš   KILL SWITCH â€” Stop All Activity',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Semi-Auto Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SemiAutoSection extends StatelessWidget {
  final List<PendingTrade> trades;
  const _SemiAutoSection({required this.trades});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pending_actions, color: AppColors.gold, size: 16),
            const SizedBox(width: 6),
            Text('Pending Approval (${trades.length})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.gold)),
          ],
        ),
        const SizedBox(height: 10),
        ...trades.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PendingTradeCard(trade: t),
            )),
      ],
    );
  }
}

class _PendingTradeCard extends StatelessWidget {
  final PendingTrade trade;
  const _PendingTradeCard({required this.trade});

  @override
  Widget build(BuildContext context) {
    final isBuy = trade.direction == 'BUY';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glowCard(color: AppColors.gold, intensity: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(trade.pair,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isBuy ? AppColors.success : AppColors.danger).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(trade.direction,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: isBuy ? AppColors.success : AppColors.danger)),
              ),
              const Spacer(),
              Text('${(trade.confidence * 100).toStringAsFixed(0)}% conf.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          if (trade.reasoning.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(trade.reasoning,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.read<AgentProvider>().approveTrade(trade.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('Approve', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.read<AgentProvider>().rejectTrade(trade.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Full-Auto Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FullAutoSection extends StatelessWidget {
  final List<ActiveTrade> trades;
  final double pnl;
  const _FullAutoSection({required this.trades, required this.pnl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glowCard(color: AppColors.accent, intensity: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.accent, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.accent, blurRadius: 8)],
                  )),
              const SizedBox(width: 8),
              const Text('Autonomous Mode Active',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.accent)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total P&L',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  Text(
                    '${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: pnl >= 0 ? AppColors.success : AppColors.danger),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (trades.isEmpty)
            const Text('Scanning markets for opportunities...',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
          else ...[
            Text('${trades.length} Active Trade(s)',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            ...trades.map((t) => _ActiveTradeRow(trade: t)),
          ],
        ],
      ),
    );
  }
}

class _ActiveTradeRow extends StatelessWidget {
  final ActiveTrade trade;
  const _ActiveTradeRow({required this.trade});

  @override
  Widget build(BuildContext context) {
    final isBuy = trade.direction == 'BUY';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(trade.pair,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(width: 8),
          Text(trade.direction,
              style: TextStyle(
                  fontSize: 11, color: isBuy ? AppColors.success : AppColors.danger)),
          const Spacer(),
          Text(
            '${trade.pnl >= 0 ? '+' : ''}\$${trade.pnl.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: trade.pnl >= 0 ? AppColors.success : AppColors.danger),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Risk Panel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RiskPanel extends StatefulWidget {
  const _RiskPanel();

  @override
  State<_RiskPanel> createState() => _RiskPanelState();
}

class _RiskPanelState extends State<_RiskPanel> {
  bool _expanded = false;
  double _riskPct = 2.0;
  double _dailyLoss = 5.0;
  int _maxTrades = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 10),
                  const Text('Risk Settings',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SliderRow(
                    label: 'Risk per trade',
                    value: _riskPct, min: 0.5, max: 10, divisions: 19,
                    display: '${_riskPct.toStringAsFixed(1)}%',
                    color: AppColors.primary,
                    onChanged: (v) => setState(() => _riskPct = v),
                  ),
                  const SizedBox(height: 16),
                  _SliderRow(
                    label: 'Daily loss limit',
                    value: _dailyLoss, min: 1, max: 20, divisions: 19,
                    display: '${_dailyLoss.toStringAsFixed(0)}%',
                    color: AppColors.warning,
                    onChanged: (v) => setState(() => _dailyLoss = v),
                  ),
                  const SizedBox(height: 16),
                  _SliderRow(
                    label: 'Max open trades',
                    value: _maxTrades.toDouble(), min: 1, max: 10, divisions: 9,
                    display: '$_maxTrades',
                    color: AppColors.gold,
                    onChanged: (v) => setState(() => _maxTrades = v.round()),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await context.read<ApiService>().updateRiskSettings({
                        'risk_per_trade': _riskPct,
                        'daily_loss_limit': _dailyLoss,
                        'max_open_trades': _maxTrades,
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Risk settings saved.'),
                              backgroundColor: AppColors.success),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44)),
                    child: const Text('Save Risk Settings'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final Color color;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label, required this.value, required this.min, required this.max,
    required this.divisions, required this.display, required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            Text(display,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: AppColors.bg3,
            overlayColor: color.withAlpha(30),
            trackHeight: 3,
          ),
          child: Slider(
            value: value, min: min, max: max, divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// â”€â”€ NLP Chat â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _NlpChat extends StatelessWidget {
  final List<Map<String, String>> history;
  final bool isLoading;
  final TextEditingController controller;
  final VoidCallback onSend;

  const _NlpChat({
    required this.history, required this.isLoading,
    required this.controller, required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glowCard(color: AppColors.primary, intensity: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.chat_outlined, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                const Text('AI Command',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (history.isNotEmpty) ...[
            const Divider(color: AppColors.border, height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(12),
                itemCount: history.length + (isLoading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == history.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(width: 12, height: 12,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary)),
                          SizedBox(width: 8),
                          Text('Thinking...',
                              style: TextStyle(fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  final msg = history[i];
                  final isUser = msg['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.primary.withAlpha(30) : AppColors.bg3,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isUser ? AppColors.primary.withAlpha(60) : AppColors.border),
                      ),
                      child: Text(
                        msg['content'] ?? '',
                        style: TextStyle(
                          fontSize: 12, height: 1.4,
                          color: isUser ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. "What should I trade now?"',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      filled: true, fillColor: AppColors.bg3,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isLoading ? null : onSend,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isLoading ? AppColors.bg3 : AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isLoading
                        ? const Center(
                            child: SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.bg0)))
                        : const Icon(Icons.send, color: AppColors.bg0, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}





