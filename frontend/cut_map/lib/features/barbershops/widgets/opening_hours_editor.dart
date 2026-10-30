import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/models/opening_hours_model.dart';
import 'package:flutter/material.dart';

const weekdayNames = [
  'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo',
];

class OpeningHoursEditor extends StatelessWidget {
  const OpeningHoursEditor({
    super.key,
    required this.hours,
    required this.onToggleDay,
    required this.onChanged,
  });

  final List<OpeningHoursModel> hours;
  final ValueChanged<int> onToggleDay;
  final ValueChanged<OpeningHoursModel> onChanged;

  Future<String?> _pickTime(BuildContext context, String initial) async {
    final parts = initial.split(':');
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (selected == null) return null;
    return '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
  }

  Widget _timeField(
    BuildContext context,
    String label,
    String value,
    ValueChanged<String> onSelected,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppFonts.regular12.apply(color: AppColors.gray)),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: () async {
              final time = await _pickTime(context, value);
              if (time != null) onSelected(time);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.white,
              side: const BorderSide(color: AppColors.darkGray),
              minimumSize: const Size.fromHeight(44),
            ),
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Horários de funcionamento *',
            style: AppFonts.bold16.apply(color: AppColors.white)),
        const SizedBox(height: 6),
        Text('Selecione os dias e defina os horários de cada um.',
            style: AppFonts.regular12.apply(color: AppColors.gray)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (var day = 1; day <= 7; day++)
              FilterChip(
                label: Text(weekdayNames[day - 1].substring(0, 3)),
                selected: hours.any((item) => item.dayOfWeek == day),
                onSelected: (_) => onToggleDay(day),
                selectedColor: AppColors.yellow,
                backgroundColor: AppColors.darkGray,
                labelStyle: TextStyle(
                  color: hours.any((item) => item.dayOfWeek == day)
                      ? AppColors.background : AppColors.white,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (final hour in hours) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(weekdayNames[hour.dayOfWeek - 1],
                    style: AppFonts.bold14.apply(color: AppColors.white)),
                const SizedBox(height: 12),
                Row(children: [
                  _timeField(context, 'Início', hour.opensAt, (value) =>
                      onChanged(OpeningHoursModel(
                        dayOfWeek: hour.dayOfWeek, opensAt: value,
                        closesAt: hour.closesAt,
                        breakStartsAt: hour.breakStartsAt,
                        breakEndsAt: hour.breakEndsAt,
                      ))),
                  const SizedBox(width: 10),
                  _timeField(context, 'Fim', hour.closesAt, (value) =>
                      onChanged(OpeningHoursModel(
                        dayOfWeek: hour.dayOfWeek, opensAt: hour.opensAt,
                        closesAt: value,
                        breakStartsAt: hour.breakStartsAt,
                        breakEndsAt: hour.breakEndsAt,
                      ))),
                ]),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Pausa para almoço',
                      style: AppFonts.regular14.apply(color: AppColors.white)),
                  value: hour.hasBreak,
                  activeTrackColor: AppColors.yellow,
                  onChanged: (enabled) => onChanged(OpeningHoursModel(
                    dayOfWeek: hour.dayOfWeek,
                    opensAt: hour.opensAt,
                    closesAt: hour.closesAt,
                    breakStartsAt: enabled ? '12:00' : null,
                    breakEndsAt: enabled ? '13:00' : null,
                  )),
                ),
                if (hour.hasBreak)
                  Row(children: [
                    _timeField(context, 'Pausa', hour.breakStartsAt!, (value) =>
                        onChanged(OpeningHoursModel(
                          dayOfWeek: hour.dayOfWeek,
                          opensAt: hour.opensAt,
                          closesAt: hour.closesAt,
                          breakStartsAt: value,
                          breakEndsAt: hour.breakEndsAt,
                        ))),
                    const SizedBox(width: 10),
                    _timeField(context, 'Retorno', hour.breakEndsAt!, (value) =>
                        onChanged(OpeningHoursModel(
                          dayOfWeek: hour.dayOfWeek,
                          opensAt: hour.opensAt,
                          closesAt: hour.closesAt,
                          breakStartsAt: hour.breakStartsAt,
                          breakEndsAt: value,
                        ))),
                  ]),
                if (!hour.isValid) ...[
                  const SizedBox(height: 8),
                  Text('Confira a ordem dos horários e da pausa.',
                      style: AppFonts.regular12.apply(color: AppColors.redSnack)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
