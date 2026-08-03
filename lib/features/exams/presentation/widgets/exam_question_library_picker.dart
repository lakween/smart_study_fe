import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ExamQuestionLibraryPicker extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final int? maxSelection;
  final EdgeInsets padding;

  const ExamQuestionLibraryPicker({
    super.key,
    required this.questions,
    required this.selectedIds,
    required this.onSelectionChanged,
    this.maxSelection,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 24),
  });

  @override
  State<ExamQuestionLibraryPicker> createState() =>
      _ExamQuestionLibraryPickerState();
}

class _ExamQuestionLibraryPickerState extends State<ExamQuestionLibraryPicker> {
  final _searchController = TextEditingController();
  String _search = '';
  String? _subject;
  String? _topic;
  String? _quiz;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _value(Map<String, dynamic> row, String key) =>
      row[key] as String? ?? '';

  String _id(Map<String, dynamic> row) => row['id'] as String;

  String _groupKey(Map<String, dynamic> row) =>
      '${_value(row, 'subjectName')}\u0000${_value(row, 'topicName')}\u0000${_value(row, 'quizTitle')}';

  List<String> _values(
    String key, [
    bool Function(Map<String, dynamic>)? test,
  ]) {
    final result = widget.questions
        .where(test ?? (_) => true)
        .map((row) => _value(row, key))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return result;
  }

  List<Map<String, dynamic>> get _filtered {
    final query = _search.trim().toLowerCase();
    return widget.questions.where((row) {
      if (_subject != null && _value(row, 'subjectName') != _subject) {
        return false;
      }
      if (_topic != null && _value(row, 'topicName') != _topic) {
        return false;
      }
      if (_quiz != null && _value(row, 'quizTitle') != _quiz) return false;
      if (query.isEmpty) return true;
      return [
        _value(row, 'text'),
        _value(row, 'subjectName'),
        _value(row, 'topicName'),
        _value(row, 'quizTitle'),
      ].any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> _grouped(
    Iterable<Map<String, dynamic>> rows,
  ) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      groups.putIfAbsent(_groupKey(row), () => []).add(row);
    }
    final entries = groups.entries.toList()
      ..sort((a, b) {
        final first = _value(a.value.first, 'quizTitle');
        final second = _value(b.value.first, 'quizTitle');
        return first.toLowerCase().compareTo(second.toLowerCase());
      });
    return Map.fromEntries(entries);
  }

  int get _remaining {
    final maximum = widget.maxSelection;
    return maximum == null
        ? 1 << 30
        : (maximum - widget.selectedIds.length).clamp(0, maximum);
  }

  void _replaceSelection(Set<String> selection) {
    widget.onSelectionChanged(Set.unmodifiable(selection));
  }

  void _add(Iterable<Map<String, dynamic>> rows) {
    final next = Set<String>.of(widget.selectedIds);
    var remaining = _remaining;
    for (final row in rows) {
      if (remaining <= 0) break;
      if (next.add(_id(row))) remaining--;
    }
    _replaceSelection(next);
  }

  void _remove(Iterable<Map<String, dynamic>> rows) {
    final next = Set<String>.of(widget.selectedIds)..removeAll(rows.map(_id));
    _replaceSelection(next);
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _search = '';
      _subject = null;
      _topic = null;
      _quiz = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final selectedRows = widget.questions
        .where((row) => widget.selectedIds.contains(_id(row)))
        .toList();
    final availableRows = filtered
        .where((row) => !widget.selectedIds.contains(_id(row)))
        .toList();
    final selectedGroups = _grouped(selectedRows);
    final availableGroups = _grouped(availableRows);
    final filtersActive = _search.isNotEmpty ||
        _subject != null ||
        _topic != null ||
        _quiz != null;
    final maxSelection = widget.maxSelection;

    return Column(
      children: [
        Padding(
          padding: widget.padding.copyWith(bottom: 10),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search questions or quiz names',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final halfWidth = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: halfWidth,
                        child: _FilterDropdown(
                          label: 'Subject',
                          value: _subject,
                          values: _values('subjectName'),
                          onChanged: (value) => setState(() {
                            _subject = value;
                            _topic = null;
                            _quiz = null;
                          }),
                        ),
                      ),
                      SizedBox(
                        width: halfWidth,
                        child: _FilterDropdown(
                          label: 'Topic',
                          value: _topic,
                          values: _values(
                            'topicName',
                            (row) =>
                                _subject == null ||
                                _value(row, 'subjectName') == _subject,
                          ),
                          onChanged: (value) => setState(() {
                            _topic = value;
                            _quiz = null;
                          }),
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: _FilterDropdown(
                          label: 'Quiz',
                          value: _quiz,
                          values: _values(
                            'quizTitle',
                            (row) =>
                                (_subject == null ||
                                    _value(row, 'subjectName') == _subject) &&
                                (_topic == null ||
                                    _value(row, 'topicName') == _topic),
                          ),
                          onChanged: (value) => setState(() => _quiz = value),
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (filtersActive) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: const Text('Clear filters'),
                  ),
                ),
              ],
              if (maxSelection != null)
                _SelectionCapacity(
                  selected: widget.selectedIds.length,
                  maximum: maxSelection,
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: widget.padding.copyWith(top: 0),
            children: [
              _SectionHeader(
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                title: 'Selected quizzes',
                subtitle: selectedRows.isEmpty
                    ? 'Questions you add will appear here'
                    : '${selectedGroups.length} ${selectedGroups.length == 1 ? 'quiz' : 'quizzes'} • '
                        '${selectedRows.length} ${selectedRows.length == 1 ? 'question' : 'questions'}',
                actionLabel: selectedRows.isEmpty ? null : 'Clear all',
                onAction:
                    selectedRows.isEmpty ? null : () => _remove(selectedRows),
              ),
              const SizedBox(height: 10),
              if (selectedRows.isEmpty)
                const _EmptySelection()
              else
                ...selectedGroups.values.map(
                  (rows) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _QuizGroupCard(
                      rows: rows,
                      totalQuestions: widget.questions
                          .where(
                              (row) => _groupKey(row) == _groupKey(rows.first))
                          .length,
                      selected: true,
                      onGroupAction: () => _remove(rows),
                      onQuestionAction: (row) => _remove([row]),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              _SectionHeader(
                icon: Icons.auto_stories_rounded,
                color: AppColors.primary,
                title: 'Available quiz library',
                subtitle: filtersActive
                    ? '${availableRows.length} matching ${availableRows.length == 1 ? 'question' : 'questions'}'
                    : '${availableRows.length} ${availableRows.length == 1 ? 'question' : 'questions'} ready to add',
              ),
              const SizedBox(height: 10),
              if (availableRows.isEmpty)
                _AvailableEmpty(
                  hasQuestions: widget.questions.isNotEmpty,
                  filtersActive: filtersActive,
                  selectionFull: maxSelection != null && _remaining == 0,
                  onClearFilters: filtersActive ? _clearFilters : null,
                )
              else
                ...availableGroups.values.map(
                  (rows) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _QuizGroupCard(
                      rows: rows,
                      totalQuestions: rows.length,
                      selected: false,
                      canAdd: _remaining > 0,
                      onGroupAction: () => _add(rows),
                      onQuestionAction: (row) => _add([row]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('All')),
        ...values.map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _SelectionCapacity extends StatelessWidget {
  final int selected;
  final int maximum;

  const _SelectionCapacity({required this.selected, required this.maximum});

  @override
  Widget build(BuildContext context) {
    final remaining = (maximum - selected).clamp(0, maximum);
    final full = remaining == 0;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: (full ? AppColors.success : AppColors.primary)
            .withValues(alpha: .09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (full ? AppColors.success : AppColors.primary)
              .withValues(alpha: .22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            full ? Icons.task_alt_rounded : Icons.add_task_rounded,
            color: full ? AppColors.success : AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              full
                  ? 'All $maximum ${maximum == 1 ? 'question slot is' : 'question slots are'} filled'
                  : '$selected of $maximum selected • $remaining ${remaining == 1 ? 'slot' : 'slots'} remaining',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _QuizGroupCard extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final int totalQuestions;
  final bool selected;
  final bool canAdd;
  final VoidCallback onGroupAction;
  final ValueChanged<Map<String, dynamic>> onQuestionAction;

  const _QuizGroupCard({
    required this.rows,
    required this.totalQuestions,
    required this.selected,
    required this.onGroupAction,
    required this.onQuestionAction,
    this.canAdd = true,
  });

  String _text(String key) => rows.first[key] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.success : AppColors.primary;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: selected || rows.length <= 3,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(
            selected ? Icons.task_alt_rounded : Icons.quiz_outlined,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          _text('quizTitle'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${_text('subjectName')} • ${_text('topicName')}\n'
          '${selected ? '${rows.length} of $totalQuestions selected' : '${rows.length} available'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: TextButton.icon(
          onPressed: selected || canAdd ? onGroupAction : null,
          icon: Icon(
            selected ? Icons.remove_circle_outline_rounded : Icons.add_rounded,
            size: 18,
          ),
          label: Text(selected ? 'Remove' : 'Add all'),
        ),
        children: [
          const Divider(height: 1),
          ...rows.asMap().entries.map((entry) {
            final row = entry.value;
            return Column(
              children: [
                ListTile(
                  dense: true,
                  leading: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    row['text'] as String? ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: selected ? 'Remove question' : 'Add question',
                    onPressed:
                        selected || canAdd ? () => onQuestionAction(row) : null,
                    icon: Icon(
                      selected
                          ? Icons.remove_circle_rounded
                          : Icons.add_circle_rounded,
                      color: selected ? AppColors.error : color,
                    ),
                  ),
                ),
                if (entry.key < rows.length - 1)
                  const Divider(height: 1, indent: 56),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _EmptySelection extends StatelessWidget {
  const _EmptySelection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withValues(alpha: .2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.touch_app_rounded, color: AppColors.success),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Choose a whole quiz or add only the questions you want.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableEmpty extends StatelessWidget {
  final bool hasQuestions;
  final bool filtersActive;
  final bool selectionFull;
  final VoidCallback? onClearFilters;

  const _AvailableEmpty({
    required this.hasQuestions,
    required this.filtersActive,
    required this.selectionFull,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final message = !hasQuestions
        ? 'No quiz questions are available yet.'
        : selectionFull
            ? 'Your question set is full. Remove a selected question to choose another.'
            : filtersActive
                ? 'No unselected questions match these filters.'
                : 'Every available question is already selected.';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined,
              color: AppColors.textMuted, size: 30),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (onClearFilters != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onClearFilters,
              child: const Text('Show all available questions'),
            ),
          ],
        ],
      ),
    );
  }
}
