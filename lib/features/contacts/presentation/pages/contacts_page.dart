import 'package:keel/core/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/contacts/domain/entities/contact.dart';
import 'package:keel/features/contacts/presentation/bloc/contacts_cubit.dart';
import 'package:keel/features/contacts/presentation/widgets/contact_detail_panel.dart';
import 'package:keel/features/contacts/presentation/widgets/contact_dialog.dart';
import 'package:keel/features/contacts/presentation/widgets/contact_list_tile.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/blurred_amount.dart';
import 'package:keel/core/widgets/shimmer.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ContactsCubit>()..load(),
      child: const _ContactsView(),
    );
  }
}

class _ContactsView extends StatelessWidget {
  const _ContactsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContactsCubit, ContactsState>(
      listenWhen: (_, current) => current.maybeMap(
          loaded: (s) => s.validationError != null, orElse: () => false),
      listener: (context, state) {
        final error =
            state.maybeMap(loaded: (s) => s.validationError, orElse: () => null);
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
          loading: () => const MasterDetailShimmer(statCardCount: 4),
          error: (msg) => Center(
              child: Text(msg, style: const TextStyle(color: AppColors.error))),
          loaded: (contacts, summaries, selectedContactId, selectedEntries, _) {
            final cubit = context.read<ContactsCubit>();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg =
                isDark ? AppColors.darkBackground : AppColors.lightBackground;
            final surface =
                isDark ? AppColors.darkSurface : AppColors.lightSurface;
            final textPrimary =
                isDark ? AppColors.darkText : AppColors.lightText;
            final textSecondary = isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary;
            final textTertiary = isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary;
            final divider =
                isDark ? AppColors.darkBorder : AppColors.lightBorder;

            // Aggregate stats
            final totalPaidOut = summaries.values
                .fold(0, (s, c) => s + c.totalPaidOutMinor);
            final totalReceived = summaries.values
                .fold(0, (s, c) => s + c.totalReceivedMinor);
            final netPosition = totalReceived - totalPaidOut;

            final selectedContact = selectedContactId == null
                ? null
                : contacts.cast<Contact?>().firstWhere(
                    (c) => c?.id == selectedContactId,
                    orElse: () => null);

            return Container(
              color: bg,
              padding: const EdgeInsets.only(top: kTitleBarHeight),
              child: Column(
                children: [
                  // ── Top bar ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text('Contacts',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                    letterSpacing: -0.3)),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: () => showContactDialog(
                                context: context,
                                onSave: cubit.createContact,
                              ),
                              icon: const Icon(Icons.person_add_outlined,
                                  size: 16),
                              label: const Text('Add contact'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.royalBlue,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Stat cards
                        Row(
                          children: [
                            _StatCard(
                              label: 'CONTACTS',
                              value: '${contacts.length}',
                              color: textPrimary,
                              surface: surface,
                              icon: Icons.people_outline,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'TOTAL PAID OUT',
                              value: _fmt(totalPaidOut),
                              color: totalPaidOut > 0
                                  ? AppColors.error
                                  : textTertiary,
                              surface: surface,
                              icon: Icons.arrow_upward,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'TOTAL RECEIVED',
                              value: _fmt(totalReceived),
                              color: totalReceived > 0
                                  ? AppColors.success
                                  : textTertiary,
                              surface: surface,
                              icon: Icons.arrow_downward,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: netPosition >= 0
                                  ? 'NET RECEIVED'
                                  : 'NET OWED',
                              value: _fmt(netPosition.abs()),
                              color: netPosition > 0
                                  ? AppColors.success
                                  : netPosition < 0
                                      ? AppColors.error
                                      : textTertiary,
                              surface: surface,
                              icon: Icons.balance_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Split panel ──────────────────────────────────────────
                  Expanded(
                    child: Row(
                      children: [
                        // Left: contact list
                        SizedBox(
                          width: listPanelWidth(context),
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
                                          child: const Text('Add your first contact'),
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

                        // Right: detail panel
                        Expanded(
                          child: selectedContact == null
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.person_outline,
                                          size: 40, color: textTertiary),
                                      const SizedBox(height: 12),
                                      Text(
                                        contacts.isEmpty
                                            ? 'Add a contact to track shared finances.'
                                            : 'Select a contact to view details.',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: textSecondary),
                                      ),
                                    ],
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color surface;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.surface,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: surface, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: textSecondary)),
                const SizedBox(height: 4),
                BlurredAmount(
                    text: value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
