// Utility functions for deadline and date formatting

/// Format deadline in a readable way
/// Returns: "Today", "Tomorrow", "Yesterday", "Monday", "15 Sep 2026", etc.
String formatDeadlineDate(DateTime? deadline) {
  if (deadline == null) return 'No deadline';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);

  final difference = deadlineDate.difference(today).inDays;

  if (difference == 0) {
    return 'Today';
  } else if (difference == 1) {
    return 'Tomorrow';
  } else if (difference == -1) {
    return 'Yesterday';
  } else if (difference > 1 && difference <= 7) {
    final dayName = _getDayName(deadline);
    return dayName;
  } else if (difference < -1 && difference >= -7) {
    return 'Last ${_getDayName(deadline)}';
  } else {
    // Return formatted date like "15 Sep 2026"
    return _formatDate(deadline);
  }
}

/// Format time remaining until deadline
/// Returns: "2 days left", "5 hours left", "30 minutes left", "Overdue", etc.
String formatTimeRemaining(DateTime? deadline) {
  if (deadline == null) return '';

  final now = DateTime.now();
  final difference = deadline.difference(now);

  if (difference.isNegative) {
    final overdueDays = difference.inDays.abs();
    if (overdueDays == 0) {
      final overdueHours = difference.inHours.abs();
      if (overdueHours == 0) {
        return 'Overdue by ${difference.inMinutes.abs()} minutes';
      }
      return 'Overdue by $overdueHours hour${overdueHours > 1 ? 's' : ''}';
    }
    return 'Overdue by $overdueDays day${overdueDays > 1 ? 's' : ''}';
  }

  if (difference.inDays > 0) {
    return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} left';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} left';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} left';
  } else {
    return 'Due soon';
  }
}

/// Format date as "15 Sep 2026"
String _formatDate(DateTime date) {
  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Get day name from date
String _getDayName(DateTime date) {
  final days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return days[date.weekday - 1];
}

/// Format time as "2:30 PM" or "14:30" (depending on locale)
String formatTime(DateTime? time) {
  if (time == null) return '';
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Check if deadline is today
bool isDeadlineToday(DateTime? deadline) {
  if (deadline == null) return false;
  final now = DateTime.now();
  return deadline.year == now.year &&
      deadline.month == now.month &&
      deadline.day == now.day;
}

/// Check if deadline is overdue
bool isDeadlineOverdue(DateTime? deadline, bool isCompleted) {
  if (deadline == null || isCompleted) return false;
  return DateTime.now().isAfter(deadline);
}

/// Check if deadline is soon (within 24 hours and not overdue)
bool isDeadlineSoon(DateTime? deadline, bool isCompleted) {
  if (deadline == null || isCompleted) return false;
  final now = DateTime.now();
  final difference = deadline.difference(now);
  return difference.inHours <= 24 && difference.inHours > 0;
}

/// Get color based on priority
/// 0 = green (low), 1 = blue (medium), 2 = red (high)
String getPriorityLabel(int priority) {
  switch (priority) {
    case 0:
      return 'Low';
    case 1:
      return 'Medium';
    case 2:
      return 'High';
    default:
      return 'Medium';
  }
}

/// Get days until birthday
int? getDaysUntilBirthday(DateTime? dateOfBirth) {
  if (dateOfBirth == null) return null;

  final now = DateTime.now();
  var nextBirthday = DateTime(now.year, dateOfBirth.month, dateOfBirth.day);

  if (nextBirthday.isBefore(now)) {
    nextBirthday = DateTime(now.year + 1, dateOfBirth.month, dateOfBirth.day);
  }

  return nextBirthday.difference(now).inDays;
}

/// Format birthday message
String formatBirthdayMessage(DateTime? dateOfBirth) {
  if (dateOfBirth == null) return '';

  final daysUntil = getDaysUntilBirthday(dateOfBirth);
  if (daysUntil == null) return '';

  if (daysUntil == 0) {
    return 'Today is their birthday! 🎉';
  } else if (daysUntil == 1) {
    return 'Birthday tomorrow! 🎂';
  } else if (daysUntil <= 7) {
    return 'Birthday in $daysUntil days';
  }
  return '';
}
