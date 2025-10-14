import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class Todolist extends StatelessWidget {
  final String TaskName;
  final bool IsChecked;
  final Function(bool?)? onChanged;
  final Function(BuildContext)? Delete_Fun;
  final Function(BuildContext)? Update_Fun;

  const Todolist({
    super.key,
    required this.TaskName,
    required this.IsChecked,
    required this.onChanged,
    required this.Delete_Fun,
    required this.Update_Fun,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: Update_Fun,
              icon: Icons.edit_rounded,
              backgroundColor: Color(0xFF448AFF),
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(15),
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: Delete_Fun,
              icon: Icons.delete_rounded,
              backgroundColor: Color(0xFFEF5350),
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(15),
              label: 'Delete',
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: IsChecked
                  ? [
                      Color(0xFFE8EAF6),
                      Color(0xFFC5CAE9),
                    ]
                  : [
                      Colors.white,
                      Color(0xFFFAFAFA),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: IsChecked
                  ? Color(0xFF7C4DFF).withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: IsChecked
                    ? Color(0xFF7C4DFF).withOpacity(0.15)
                    : Colors.black.withOpacity(0.08),
                offset: Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onChanged?.call(!IsChecked),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Custom Checkbox
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: IsChecked
                            ? LinearGradient(
                                colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: IsChecked ? null : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: IsChecked
                              ? Colors.transparent
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                        boxShadow: IsChecked
                            ? [
                                BoxShadow(
                                  color: Color(0xFF7C4DFF).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: IsChecked
                          ? Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                    SizedBox(width: 16),
                    // Task Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            TaskName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: IsChecked
                                  ? Colors.grey.shade600
                                  : Color(0xFF2C3E50),
                              decoration: IsChecked
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: Colors.grey.shade400,
                              decorationThickness: 2,
                            ),
                          ),
                          if (IsChecked) ...[
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: Color(0xFF4CAF50),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Completed',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Swipe Indicator
                    Icon(
                      Icons.chevron_left,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}