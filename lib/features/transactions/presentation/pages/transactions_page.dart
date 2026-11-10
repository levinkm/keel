import 'package:keel/core/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:keel/features/accounts/presentation/bloc/accounts_cubit.dart';
import 'package:keel/features/contacts/domain/entities/contact.dart';
import 'package:keel/features/contacts/domain/repositories/contact_repository.dart';
import 'package:keel/features/contacts/presentation/bloc/contacts_cubit.dart';
import 'package:keel/features/contacts/presentation/widgets/contact_detail_panel.dart';
import 'package:keel/features/contacts/presentation/widgets/contact_dialog.dart';
import 'package:keel/features/contacts/presentation/widgets/contact_list_tile.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/ledger/presentation/bloc/ledger_cubit.dart';
import 'package:keel/features/projects/domain/entities/project.dart';
import 'package:keel/features/projects/domain/repositories/project_repository.dart';
import 'package:keel/features/projects/presentation/bloc/projects_cubit.dart';
import 'package:keel/features/transactions/presentation/widgets/entry_detail_panel.dart';
import 'package:keel/features/transactions/presentation/widgets/entry_list_tile.dart';
import 'package:keel/features/transactions/presentation/widgets/quick_add_dialog.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/shimmer.dart';

enum _Tab { entries, contacts }

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<LedgerCubit>()..loadPeriod()),
        BlocProvider(create: (_) => getIt<AccountsCubit>()..loadAccounts()),
        BlocProvider(create: (_) => getIt<ProjectsCubit>()..load()),
        BlocProvider(create: (_) => getIt<ContactsCubit>()..load()),
      ],
      child: const _TransactionsView(),
    );
  }
}

class _TransactionsView extends StatefulWidget {
  const _TransactionsView();

  @override
  State<_TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<_TransactionsView> {
  _Tab _tab = _Tab.entries;
  JournalEntry? _selected;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: BlocBuilder<AccountsCubit, AccountsState>(
        builder: (context, accountsState) {
          final accounts = accountsState.maybeWhen(
            loaded: (a, _, f, s, h, sp) => a,
            orElse: () => <Account>[],
          );
          return BlocBuilder<ProjectsCubit, ProjectsState>(
            builder: (context, projectsState) {
              final projects = projectsState.maybeMap(
                loaded: (s) => s.projects,
                orElse: () => <Project>[],
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Transactions',
                                style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                    letterSpacing: -0.5)),
                            const SizedBox(height: 2),
                            Text(
                              _tab == _Tab.entries
                                  ? 'Journal entries for the period'
                                  : 'People & organisations',
                              style: TextStyle(
                                  fontSize: 13, color: textSecondary),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Tab switcher
                        _TabSwitcher(
                          value: _tab,
                          isDark: isDark,
                          onChanged: (t) => setState(() => _tab = t),
                        ),
                        const SizedBox(width: 16),
                        // Context-sensitive action button
                        if (_tab == _Tab.entries)
                          BlocBuilder<LedgerCubit, LedgerState>(
                            builder: (context, state) {
                              final cubit = context.read<LedgerCubit>();
                              return FilledButton.icon(
                                onPressed: () => showQuickAddDialog(
                                  context,
                                  accounts,
                                  cubit,
                                  projects: projects,
                                  contacts: context
                                      .read<ContactsCubit>()
                                      .state
                                      .maybeMap(
                                        loaded: (s) => s.contacts,
                                        orElse: () => [],
                                      ),
                                  projectRepository:
                                      getIt<ProjectRepository>(),
                                  contactRepository:
                                      getIt<ContactRepository>(),
                                  accountsRepository:
                                      getIt<AccountsRepository>(),
                                ),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('New entry'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.royalBlue,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                              );
                            },
                          )
                        else
                          FilledButton.icon(
                            onPressed: () => showContactDialog(
                              context: context,
                              onSave: context.read<ContactsCubit>().createContact,
                            ),
                            icon: const Icon(Icons.person_add_outlined,
                                size: 16),
                            label: const Text('Add contact'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.royalBlue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Body ─────────────────────────────────────────────────
                  Expanded(
                    child: _tab == _Tab.entries
                        ? _EntriesTab(
                            accounts: accounts,
                            projects: projects,
                            contacts: const [],
                            projectsState: projectsState,
                            selected: _selected,
                            search: _search,
                            isDark: isDark,
                            onSearchChanged: (v) =>
                                setState(() => _search = v),
                            onSelect: (e) => setState(() => _selected = e),
                            onClearSelected: () =>
                                setState(() => _selected = null),
                          )
                        : const _ContactsTab(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ── Entries tab ───────────────────────────────────────────────────────────────

class _EntriesTab extends StatelessWidget {
  final List<Account> accounts;
  final List<Project> projects;
  final List<Contact> contacts;
  final ProjectsState projectsState;
  final JournalEntry? selected;
  final String search;
  final bool isDark;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<JournalEntry> onSelect;
  final VoidCallback onClearSelected;

  const _EntriesTab({
    required this.accounts,
    required this.projects,
    required this.contacts,
    required this.projectsState,
    required this.selected,
    required this.search,
    required this.isDark,
    required this.onSearchChanged,
    required this.onSelect,
    required this.onClearSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BlocBuilder<LedgerCubit, LedgerState>(
      builder: (context, state) {
        final cubit = context.read<LedgerCubit>();
        final period = state.maybeWhen(
          loaded: (_, p, __, ___) => p,
          orElse: () => cubit.currentPeriod,
        );

              return BlocBuilder<ContactsCubit, ContactsState>(
                builder: (context, contactsState) {
                  final contacts = contactsState.maybeMap(
                    loaded: (s) => s.contacts,
                    orElse: () => <Contact>[],
                  );
                  return Column(
                    children: [
                      // Period switcher + search
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          children: [
                            SizedBox(
                              width: sidebarWidth(context),
                              child: TextField(
                                onChanged: onSearchChanged,
                                decoration: InputDecoration(
                                  hintText: 'Search entries…',
                                  prefixIcon: Icon(Icons.search,
                                      size: 18, color: textSecondary),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const Spacer(),
                            _PeriodSwitcher(
                              period: period,
                              isDark: isDark,
                              onPrev: cubit.previousPeriod,
                              onNext: cubit.nextPeriod,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: state.when(
                          initial: () => const SizedBox.shrink(),
                          loading: () => const PanelShimmer(rowCount: 8),
                          error: (msg) => Center(
                              child: Text(msg,
                                  style: const TextStyle(
                                      color: AppColors.error))),
                          loaded: (entries, _, selectedEntry, validationError) {
                            final effectiveSelected = selectedEntry ?? selected;
                            final filtered = search.isEmpty
                                ? entries
                                : entries
                                    .where((e) => e.description
                                        .toLowerCase()
                                        .contains(search.toLowerCase()))
                                    .toList();

                            if (effectiveSelected == null &&
                                filtered.isNotEmpty) {
                              WidgetsBinding.instance
                                  .addPostFrameCallback((_) {
                                onSelect(filtered.first);
                              });
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 380,
                                  child: _EntryList(
                                    entries: filtered,
                                    selected: effectiveSelected,
                                    accounts: accounts,
                                    isDark: isDark,
                                    onSelect: onSelect,
                                  ),
                                ),
                                Expanded(
                                  child: effectiveSelected == null
                                      ? _EmptyDetail(isDark: isDark)
                                      : EntryDetailPanel(
                                          entry: effectiveSelected,
                                          accounts: accounts,
                                          projects: projects,
                                          contacts: contacts,
                                          currentProjectId: null,
                                          isDark: isDark,
                                          onReverse: (reason) {
                                            cubit.reverseEntry(
                                                effectiveSelected.id,
                                                reason);
                                            onClearSelected();
                                          },
                                          onUpdateMeta: cubit.updateEntryMeta,
                                          onAddCost: ({
                                            required feeAccountId,
                                            required paidFromAccountId,
                                            required amountMinor,
                                            required memo,
                                          }) =>
                                              cubit.addTransactionCost(
                                                entryId: effectiveSelected.id,
                                                feeAccountId: feeAccountId,
                                                paidFromAccountId:
                                                    paidFromAccountId,
                                                amountMinor: amountMinor,
                                                currency: 'KES',
                                                memo: memo,
                                              ),
                                          onRetag: (newProjectId) async {
                                            final projectRepo =
                                                getIt<ProjectRepository>();
                                            final currentIds =
                                                await projectRepo
                                                    .getProjectIdsForEntry(
                                                        effectiveSelected.id);
                                            currentIds.fold(
                                                (_) => null, (ids) async {
                                              for (final id in ids) {
                                                await projectRepo.untagEntry(
                                                    id, effectiveSelected.id);
                                              }
                                            });
                                            if (newProjectId != null) {
                                              await projectRepo.tagEntry(
                                                  newProjectId,
                                                  effectiveSelected.id);
                                            }
                                          },
                                          onRetagContact: (newContactId) async {
                                            final contactRepo =
                                                getIt<ContactRepository>();
                                            if (newContactId != null) {
                                              await contactRepo.tagEntry(
                                                  newContactId,
                                                  effectiveSelected.id);
                                            } else {
                                              await contactRepo.untagEntry(
                                                  effectiveSelected.id);
                                            }
                                          },
                                          onAddAttachment: (path, name, mime) =>
                                              cubit.addAttachment(
                                                entryId: effectiveSelected.id,
                                                filePath: path,
                                                fileName: name,
                                                mimeType: mime,
                                              ),
                                          onRemoveAttachment: (attachmentId) =>
                                              cubit.removeAttachment(
                                                  attachmentId,
                                                  effectiveSelected.id),
                                        ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
      },
    );
  }
}

// ── Contacts tab ──────────────────────────────────────────────────────────────

class _ContactsTab extends StatelessWidget {
  const _ContactsTab();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContactsCubit, ContactsState>(
      listenWhen: (_, current) => current.maybeMap(
          loaded: (s) => s.validationError != null, orElse: () => false),
      listener: (context, state) {
        final error = state.maybeMap(
            loaded: (s) => s.validationError, orElse: () => null);
        if (error == null) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
        context.read<ContactsCubit>().clearValidationError();
      },
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const PanelShimmer(),
          error: (msg) => Center(
              child: Text(msg,
                  style: const TextStyle(color: AppColors.error))),
          loaded: (contacts, summaries, selectedContactId, selectedEntries, _) {
            final cubit = context.read<ContactsCubit>();
            final isDark =
                Theme.of(context).brightness == Brightness.dark;
            final bg = isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground;
            final textSecondary = isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary;
            final textTertiary = isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary;
            final divider =
                isDark ? AppColors.darkBorder : AppColors.lightBorder;

            final selectedContact = selectedContactId == null
                ? null
                : contacts.cast<Contact?>().firstWhere(
                    (c) => c?.id == selectedContactId,
                    orElse: () => null);

            return Container(
              color: bg,
              padding: const EdgeInsets.only(top: kTitleBarHeight),
              child: Row(
                children: [
                  // Left: contact list
                  SizedBox(
                    width: 300,
                    child: Container(
                      color: bg,
                      child: contacts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 36, color: textTertiary),
                                  const SizedBox(height: 12),
                                  Text('No contacts yet.',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: textSecondary)),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => showContactDialog(
                                      context: context,
                                      onSave: cubit.createContact,
                                    ),
                                    child: const Text(
                                        'Add your first contact'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: contacts.length,
                              itemBuilder: (_, i) {
                                final c = contacts[i];
                                return ContactListTile(
                                  contact: c,
                                  summary: summaries[c.id]!,
                                  isSelected: c.id == selectedContactId,
                                  onTap: () => cubit.selectContact(
                                      c.id == selectedContactId
                                          ? null
                                          : c.id),
                                );
                              },
                            ),
                    ),
                  ),

                  VerticalDivider(width: 1, color: divider),

                  // Right: detail
                  Expanded(
                    child: selectedContact == null
                        ? Center(
                            child: Text(
                              contacts.isEmpty
                                  ? 'Add a contact to track shared finances.'
                                  : 'Select a contact to view details.',
                              style: TextStyle(
                                  fontSize: 13, color: textSecondary),
                            ),
                          )
                        : ContactDetailPanel(
                            contact: selectedContact,
                            summary: summaries[selectedContact.id]!,
                            entries: selectedEntries,
                            onEdit: () => showContactDialog(
                              context: context,
                              existing: selectedContact,
                              onSave: cubit.updateContact,
                            ),
                            onDelete: () =>
                                cubit.deleteContact(selectedContact.id),
                            onUntagEntry: cubit.untagEntry,
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Tab switcher ──────────────────────────────────────────────────────────────

class _TabSwitcher extends StatelessWidget {
  final _Tab value;
  final bool isDark;
  final ValueChanged<_Tab> onChanged;

  const _TabSwitcher({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceSecondary;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabItem(
            label: 'Entries',
            icon: Icons.receipt_long_outlined,
            isActive: value == _Tab.entries,
            isDark: isDark,
            onTap: () => onChanged(_Tab.entries),
          ),
          _TabItem(
            label: 'Contacts',
            icon: Icons.people_outline,
            isActive: value == _Tab.contacts,
            isDark: isDark,
            onTap: () => onChanged(_Tab.contacts),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isActive ? AppColors.royalBlue : textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.royalBlue : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Entry list ────────────────────────────────────────────────────────────────

class _EntryList extends StatelessWidget {
  final List<JournalEntry> entries;
  final JournalEntry? selected;
  final List<Account> accounts;
  final bool isDark;
  final ValueChanged<JournalEntry> onSelect;

  const _EntryList({
    required this.entries,
    required this.selected,
    required this.accounts,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 32,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary),
            const SizedBox(height: 12),
            Text('No entries this period.',
                style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(32, 8, 16, 32),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        return EntryListTile(
          entry: entry,
          accounts: accounts,
          isSelected: selected?.id == entry.id,
          isDark: isDark,
          onTap: () => onSelect(entry),
        );
      },
    );
  }
}

// ── Period switcher ───────────────────────────────────────────────────────────

class _PeriodSwitcher extends StatelessWidget {
  final String period;
  final bool isDark;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _PeriodSwitcher({
    required this.period,
    required this.isDark,
    required this.onPrev,
    required this.onNext,
  });

  String get _label {
    final parts = period.split('-');
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[int.parse(parts[1])]} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, size: 18, color: textSecondary),
          onPressed: onPrev,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
        Text(_label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary)),
        IconButton(
          icon: Icon(Icons.chevron_right, size: 18, color: textSecondary),
          onPressed: onNext,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  final bool isDark;
  const _EmptyDetail({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Select an entry to view details',
        style: TextStyle(
          fontSize: 13,
          color: isDark
              ? AppColors.darkTextTertiary
              : AppColors.lightTextTertiary,
        ),
      ),
    );
  }
}
