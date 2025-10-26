import 'package:flutter/material.dart';

class PackageSelector extends StatefulWidget {
  final int min;
  final int max;
  final int? initial;
  final void Function(int value)? onChanged;
  final EdgeInsets? padding;
  final double height;

  const PackageSelector({
    super.key,
    required this.min,
    required this.max,
    this.initial,
    this.onChanged,
    this.padding,
    this.height = 40,
  }) : assert(min >= 0),
       assert(max >= 0);

  @override
  State<PackageSelector> createState() => _PackageSelectorState();
}

class _PackageSelectorState extends State<PackageSelector> {
  late int _value;

  @override
  void initState() {
    super.initState();
    final start = widget.initial ?? widget.min;
    _value = start.clamp(widget.min, widget.max);
  }

  void _notify() {
    if (widget.onChanged != null) widget.onChanged!(_value);
  }

  void _inc() {
    if (_value < widget.max) {
      setState(() => _value++);
      _notify();
    }
  }

  void _dec() {
    if (_value > widget.min) {
      setState(() => _value--);
      _notify();
    }
  }

  @override
  void didUpdateWidget(covariant PackageSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If min/max change and current value is out of bounds, clamp it
    final clamped = _value.clamp(widget.min, widget.max);
    if (clamped != _value) {
      _value = clamped;
      _notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabledMinus = _value <= widget.min;
    final disabledPlus  = _value >= widget.max;

    return Padding(
      padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: widget.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: disabledMinus ? null : _dec,
                icon: const Icon(Icons.remove),
                tooltip: 'Decrease',
              ),
              const VerticalDivider(width: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_value',
                  style: const TextStyle(
                    fontSize: 16, 
                    color: Colors.deepOrange),
                ),
              ),
              const VerticalDivider(width: 1),
              IconButton(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: disabledPlus ? null : _inc,
                icon: const Icon(Icons.add),
                tooltip: 'Increase',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
