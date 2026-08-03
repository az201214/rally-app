import 'package:flutter/material.dart';

import '../../../../../theme/app_radius.dart';
import '../../../../../theme/app_spacing.dart';

enum AvailabilityOption {
  now('NOW'),
  tonight('TONIGHT'),
  custom('CUSTOM');

  const AvailabilityOption(this.label);

  final String label;
}

class AvailabilitySelector extends StatelessWidget {
  const AvailabilitySelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final AvailabilityOption selected;
  final ValueChanged<AvailabilityOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Availability',
      child: Row(
        children: AvailabilityOption.values.map((option) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: option == AvailabilityOption.custom ? 0 : AppSpacing.xs,
              ),
              child: _AvailabilityButton(
                option: option,
                isSelected: option == selected,
                onPressed: () => onSelected(option),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AvailabilityButton extends StatelessWidget {
  const _AvailabilityButton({
    required this.option,
    required this.isSelected,
    required this.onPressed,
  });

  final AvailabilityOption option;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected ? colors.primary : colors.surfaceContainerHighest,
        borderRadius: AppRadius.medium,
        child: InkWell(
          key: Key('availability-${option.name}'),
          onTap: onPressed,
          borderRadius: AppRadius.medium,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.xxl),
            child: Center(
              child: Text(
                option.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected ? colors.onPrimary : colors.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
