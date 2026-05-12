import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../auth/auth_provider.dart';
import '../../models/supplier_model.dart';
import '../../provider/suppliers_provider.dart';

class PurchaseReportScreen extends ConsumerStatefulWidget {
  const PurchaseReportScreen({super.key});

  @override
  ConsumerState<PurchaseReportScreen> createState() =>
      _PurchaseReportScreenState();
}

class _PurchaseReportScreenState extends ConsumerState<PurchaseReportScreen> {
  static const List<String> _reportTypes = [
    'Material Received Report',
    'List of Supplier',
    'Purchase Orders Detailed Report',
    'Purchase Orders Summary Report',
  ];

  String? _selectedReportType;
  int? _selectedSupplierId;

  void _generatePdf() {
    final reportType = _selectedReportType ?? 'purchase report';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $reportType PDF...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final token = authState.accessToken;
    final suppliersAsync = token == null
        ? null
        : ref.watch(suppliersProvider(token));
    final isDark = theme.brightness == Brightness.dark;
    final panelColor = isDark ? colorScheme.surface : Colors.white;
    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.8);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Purchase Reports',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 34, 10, 24),
          decoration: BoxDecoration(
            color: panelColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              final reportTypeField = _ReportField(
                label: 'Report Type',
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedReportType,
                  isExpanded: true,
                  hint: const Text('Select purchases report type'),
                  icon: const Icon(LucideIcons.chevronDown),
                  decoration: _fieldDecoration(context),
                  items: _reportTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedReportType = value);
                  },
                ),
              );
              final supplierField = _ReportField(
                label: 'Supplier',
                child: _buildSupplierDropdown(
                  context,
                  authState.isLoading,
                  suppliersAsync,
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: reportTypeField),
                        const Spacer(flex: 3),
                        Expanded(flex: 5, child: supplierField),
                        const Spacer(flex: 3),
                      ],
                    )
                  else ...[
                    reportTypeField,
                    const SizedBox(height: 16),
                    supplierField,
                  ],
                  const SizedBox(height: 28),
                  Align(
                    alignment: isWide
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _selectedReportType == null
                            ? null
                            : _generatePdf,
                        icon: const Icon(LucideIcons.download, size: 18),
                        label: const Text('Generate PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierDropdown(
    BuildContext context,
    bool authIsLoading,
    AsyncValue<List<Supplier>>? suppliersAsync,
  ) {
    if (authIsLoading || suppliersAsync == null) {
      return InputDecorator(
        decoration: _fieldDecoration(context),
        child: const Text('Loading suppliers...'),
      );
    }

    return suppliersAsync.when(
      loading: () => InputDecorator(
        decoration: _fieldDecoration(context),
        child: const Text('Loading suppliers...'),
      ),
      error: (error, _) => InputDecorator(
        decoration: _fieldDecoration(context),
        child: Text(
          'Could not load suppliers',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (suppliers) {
        final supplierIds = suppliers.map((supplier) => supplier.id).toSet();
        if (_selectedSupplierId != null &&
            !supplierIds.contains(_selectedSupplierId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedSupplierId = null);
          });
        }

        return DropdownButtonFormField<int?>(
          initialValue: _selectedSupplierId,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown),
          decoration: _fieldDecoration(context),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('All Suppliers'),
            ),
            ...suppliers.map(
              (supplier) => DropdownMenuItem<int?>(
                value: supplier.id,
                child: Text(supplier.name),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => _selectedSupplierId = value);
          },
        );
      },
    );
  }

  InputDecoration _fieldDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      filled: true,
      fillColor: colorScheme.surface.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }
}

class _ReportField extends StatelessWidget {
  final String label;
  final Widget child;

  const _ReportField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
