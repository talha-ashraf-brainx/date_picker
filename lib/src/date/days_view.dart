import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../shared/picker_grid_delegate.dart';
import '../shared/types.dart';

class DaysView extends StatelessWidget {
  DaysView(
      {super.key,
      required this.currentDate,
      required this.onChanged,
      required this.minDate,
      required this.maxDate,
      this.selectedDate,
      required this.displayedMonth,
      required this.daysOfTheWeekTextStyle,
      required this.enabledCellsTextStyle,
      required this.enabledCellsDecoration,
      required this.disabledCellsTextStyle,
      required this.disabledCellsDecoration,
      required this.currentDateTextStyle,
      required this.currentDateDecoration,
      required this.selectedDayTextStyle,
      required this.selectedDayDecoration,
      required this.highlightColor,
      required this.splashColor,
      this.splashRadius,
      this.disabledDayPredicate,
      this.otherMonthStyle}) {
    assert(!minDate.isAfter(maxDate), "minDate can't be after maxDate");

    assert(() {
      if (selectedDate == null) return true;
      final min = DateTime(minDate.year, minDate.month, minDate.day);
      final max = DateTime(maxDate.year, maxDate.month, maxDate.day);
      final selected = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
      );
      return (selected.isAfter(min) || selected.isAtSameMomentAs(min)) &&
          (selected.isBefore(max) || selected.isAtSameMomentAs(max));
    }(), "selected date should be in the range of min date & max date");
  }

  final DateTime? selectedDate;
  final DateTime currentDate;
  final ValueChanged<DateTime> onChanged;
  final DateTime minDate;
  final DateTime maxDate;
  final DateTime displayedMonth;
  final TextStyle daysOfTheWeekTextStyle;
  final TextStyle enabledCellsTextStyle;
  final BoxDecoration enabledCellsDecoration;
  final TextStyle disabledCellsTextStyle;
  final BoxDecoration disabledCellsDecoration;
  final TextStyle currentDateTextStyle;
  final BoxDecoration currentDateDecoration;
  final TextStyle selectedDayTextStyle;
  final BoxDecoration selectedDayDecoration;
  final Color splashColor;
  final Color highlightColor;
  final double? splashRadius;
  final DatePredicate? disabledDayPredicate;
  final TextStyle? otherMonthStyle;

  List<Widget> _dayHeaders(
    TextStyle headerStyle,
    Locale locale,
    MaterialLocalizations localizations,
  ) {
    final List<Widget> result = <Widget>[];
    final weekdayNames =
        DateFormat('', locale.toString()).dateSymbols.SHORTWEEKDAYS;

    for (int i = localizations.firstDayOfWeekIndex; true; i = (i + 1) % 7) {
      final String weekday = weekdayNames[i].replaceFirst('ال', '');
      result.add(
        ExcludeSemantics(
          child: Center(
            child: Text(
              weekday,
              style: daysOfTheWeekTextStyle,
            ),
          ),
        ),
      );
      if (i == (localizations.firstDayOfWeekIndex - 1) % 7) {
        break;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final int year = displayedMonth.year;
    final int month = displayedMonth.month;

    final DateTime firstOfMonth = DateTime(year, month, 1);
    final DateTime lastOfMonth = DateTime(year, month + 1, 0);
    final int daysInMonth = lastOfMonth.day;
    final int dayOffset = DateUtils.firstDayOffset(year, month, localizations);

    final DateTime _maxDate = DateUtils.dateOnly(maxDate);
    final DateTime _minDate = DateUtils.dateOnly(minDate);

    final List<Widget> dayItems = _dayHeaders(
      daysOfTheWeekTextStyle,
      Localizations.localeOf(context),
      MaterialLocalizations.of(context),
    );

    // Add days from the previous month if needed
    final DateTime prevMonth = DateTime(year, month - 1);
    final int daysInPrevMonth =
        DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);

    for (int i = daysInPrevMonth - dayOffset + 1; i <= daysInPrevMonth; i++) {
      final DateTime dayToBuild = DateTime(prevMonth.year, prevMonth.month, i);
      dayItems.add(_buildDayWidget(dayToBuild, true));
    }

    // Add current month's days
    for (int day = 1; day <= daysInMonth; day++) {
      final DateTime dayToBuild = DateTime(year, month, day);
      dayItems.add(_buildDayWidget(dayToBuild, false));
    }

    // Add days from the next month to complete the grid if necessary
    final int totalDays = dayItems.length - 7;
    final int nextMonthDays = 42 - totalDays;
    final DateTime nextMonth = DateTime(year, month + 1);
    for (int i = 1; i <= nextMonthDays; i++) {
      final DateTime dayToBuild = DateTime(nextMonth.year, nextMonth.month, i);
      dayItems.add(_buildDayWidget(dayToBuild, true));
    }

    return GridView.custom(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: PickerGridDelegate(
        columnCount: 7,
        rowCount: dayItems.length >= 43 ? 7 : 6,
      ),
      childrenDelegate: SliverChildListDelegate(
        addRepaintBoundaries: false,
        dayItems,
      ),
    );
  }

  Widget _buildDayWidget(DateTime dayToBuild, bool isOtherMonth) {
    final bool isDisabled = dayToBuild.isAfter(maxDate) ||
        dayToBuild.isBefore(minDate) ||
        (disabledDayPredicate?.call(dayToBuild) ?? false);
    final bool isSelectedDay = DateUtils.isSameDay(selectedDate, dayToBuild);
    final bool isCurrent = DateUtils.isSameDay(currentDate, dayToBuild);

    BoxDecoration decoration = enabledCellsDecoration;
    TextStyle style = enabledCellsTextStyle;

    if (isCurrent) {
      style = currentDateTextStyle;
      decoration = currentDateDecoration;
    }

    if (isSelectedDay) {
      style = selectedDayTextStyle;
      decoration = selectedDayDecoration;
    }

    if (isDisabled || isOtherMonth) {
      style = disabledCellsTextStyle;
      decoration = disabledCellsDecoration;
    }

    if (isOtherMonth) {
      if (otherMonthStyle != null) {
        style = otherMonthStyle!;
      }
    }

    Widget dayWidget = Container(
      decoration: decoration,
      child: Center(
        child: Text(
          dayToBuild.day.toString(),
          style: style,
        ),
      ),
    );

    if (isDisabled || isOtherMonth) {
      dayWidget = ExcludeSemantics(child: dayWidget);
    } else {
      dayWidget = InkResponse(
        onTap: () => onChanged(dayToBuild),
        radius: splashRadius,
        splashColor: splashColor,
        highlightColor: highlightColor,
        child: Semantics(
          label:
              '${DateFormat.Md().format(dayToBuild)} ${DateFormat.yMMM().format(dayToBuild)}',
          selected: isSelectedDay,
          excludeSemantics: true,
          child: dayWidget,
        ),
      );
    }
    return dayWidget;
  }
}
