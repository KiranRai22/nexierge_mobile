import 'package:flutter/material.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/color_palette.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../domain/models/ticket.dart';

/// Vertical stepper that shows a ticket's lifecycle: Created · Accepted ·
/// Done. Inactive steps are dimmed; reached steps are filled.
class TimingStepper extends StatelessWidget {
  final Ticket ticket;
  const TimingStepper({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final steps = <_TimingStep>[
      _TimingStep(
        label: s.detailCreated,
        when: ticket.createdAt,
        reached: true,
      ),
      _TimingStep(
        label: s.detailAccepted,
        when: ticket.acceptedAt,
        reached: ticket.acceptedAt != null,
      ),
      _TimingStep(
        label: s.detailDone,
        when: ticket.doneAt,
        reached: ticket.doneAt != null,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.detailTimingLabel,
          style: TypographyManager.sectionOverline,
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            step: steps[i],
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _TimingStep {
  final String label;
  final DateTime? when;
  final bool reached;
  const _TimingStep({
    required this.label,
    required this.when,
    required this.reached,
  });
}

class _StepRow extends StatelessWidget {
  final _TimingStep step;
  final bool isLast;
  const _StepRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = step.reached
        ? ColorPalette.opsPurple
        : ColorPalette.textDisabled;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: step.reached
                      ? ColorPalette.opsPurple
                      : ColorPalette.opsSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: ColorPalette.opsBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    step.label,
                    style: TypographyManager.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: step.reached
                          ? ColorPalette.textPrimary
                          : ColorPalette.textDisabled,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.when == null
                        ? context.l10n.detailEmpty
                        : AppDateUtils.timingLine(step.when!),
                    style: TypographyManager.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
