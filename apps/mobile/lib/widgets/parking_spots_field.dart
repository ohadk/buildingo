import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Multi-spot parking editor (apartments can have more than one space).
class ParkingSpotsField extends StatefulWidget {
  final List<String> initialSpots;
  final ValueChanged<List<String>> onChanged;
  final int maxSpots;

  const ParkingSpotsField({
    super.key,
    this.initialSpots = const [],
    required this.onChanged,
    this.maxSpots = 5,
  });

  @override
  State<ParkingSpotsField> createState() => _ParkingSpotsFieldState();
}

class _ParkingSpotsFieldState extends State<ParkingSpotsField> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSpots.where((s) => s.trim().isNotEmpty);
    _controllers = [
      for (final s in initial) TextEditingController(text: s),
      if (initial.isEmpty) TextEditingController(),
    ];
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _spots => [
        for (final c in _controllers)
          if (c.text.trim().isNotEmpty) c.text.trim(),
      ];

  void _emit() => widget.onChanged(_spots);

  void _add() {
    if (_controllers.length >= widget.maxSpots) return;
    setState(() => _controllers.add(TextEditingController()));
  }

  void _remove(int index) {
    if (_controllers.length <= 1) {
      _controllers.first.clear();
      _emit();
      setState(() {});
      return;
    }
    setState(() {
      _controllers.removeAt(index).dispose();
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.parkingSpotsLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DiraColors.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < _controllers.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controllers[i],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _emit(),
                  decoration: InputDecoration(
                    hintText: l10n.parkingSpotHint,
                  ),
                ),
              ),
              if (_controllers.length > 1 ||
                  _controllers[i].text.trim().isNotEmpty) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _remove(i),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: DiraColors.inkSoft,
                  tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                ),
              ],
            ],
          ),
        ],
        if (_controllers.length < widget.maxSpots) ...[
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.addParkingSpot),
              style: TextButton.styleFrom(
                foregroundColor: DiraColors.brick,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
