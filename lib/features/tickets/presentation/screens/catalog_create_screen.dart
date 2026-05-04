import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../domain/entities/service_catalog.dart';
import '../providers/service_catalogs_provider.dart';

/// Screen to select a service catalog for creating catalog-based tickets.
/// Fetches and displays all service catalogs from the API.
class CatalogCreateScreen extends ConsumerWidget {
  const CatalogCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final catalogsAsync = ref.watch(serviceCatalogsNotifierProvider);

    return Scaffold(
      backgroundColor: ColorPalette.opsSurface,
      appBar: AppBar(
        backgroundColor: ColorPalette.opsSurface,
        foregroundColor: ColorPalette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(s.createCatalogTitle, style: TypographyManager.screenTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: catalogsAsync.when(
          data: (state) {
            if (state.error != null) {
              return _ErrorView(
                error: state.error!,
                onRetry: () => ref
                    .read(serviceCatalogsNotifierProvider.notifier)
                    .refresh(),
              );
            }
            if (state.catalogs.isEmpty) {
              return _EmptyView(
                onRefresh: () => ref
                    .read(serviceCatalogsNotifierProvider.notifier)
                    .refresh(),
              );
            }
            return _CatalogListView(
              catalogs: state.catalogs,
              onCatalogSelected: (catalog) =>
                  _onCatalogSelected(context, catalog),
            );
          },
          loading: () => const _LoadingView(),
          error: (error, _) => _ErrorView(
            error: error.toString(),
            onRetry: () =>
                ref.read(serviceCatalogsNotifierProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }

  void _onCatalogSelected(BuildContext context, ServiceCatalog catalog) {
    // TODO: Navigate to catalog detail/items screen
    // For now just show a toast
    context.showInfo('Selected: ${catalog.name}');
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: ColorPalette.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No service catalogs available',
            style: TypographyManager.bodyLarge.copyWith(
              color: ColorPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRefresh, child: const Text('Refresh')),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: ColorPalette.error),
            const SizedBox(height: 16),
            Text('Failed to load catalogs', style: TypographyManager.bodyLarge),
            const SizedBox(height: 8),
            Text(
              error,
              style: TypographyManager.bodySmall.copyWith(
                color: ColorPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _CatalogListView extends StatelessWidget {
  final List<ServiceCatalog> catalogs;
  final ValueChanged<ServiceCatalog> onCatalogSelected;

  const _CatalogListView({
    required this.catalogs,
    required this.onCatalogSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: catalogs.length,
      itemBuilder: (context, index) {
        final catalog = catalogs[index];
        return _CatalogCard(
          catalog: catalog,
          onTap: () => onCatalogSelected(catalog),
        );
      },
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final ServiceCatalog catalog;
  final VoidCallback onTap;

  const _CatalogCard({required this.catalog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brandColor = catalog.brandColor != null
        ? _parseColor(catalog.brandColor!)
        : ColorPalette.opsPurple;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ColorPalette.opsBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Logo or brand colored icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: catalog.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: catalog.logoUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Icon(Icons.store, color: brandColor, size: 28),
                        ),
                      )
                    : Icon(Icons.store, color: brandColor, size: 28),
              ),
              const SizedBox(width: 16),
              // Catalog info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      catalog.name,
                      style: TypographyManager.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (catalog.description != null &&
                        catalog.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        catalog.description!,
                        style: TypographyManager.bodySmall.copyWith(
                          color: ColorPalette.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Stats
                    Row(
                      children: [
                        _StatBadge(
                          icon: Icons.category_outlined,
                          value: catalog.categories,
                          label: 'Categories',
                        ),
                        const SizedBox(width: 16),
                        _StatBadge(
                          icon: Icons.inventory_2_outlined,
                          value: catalog.items,
                          label: 'Items',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(Icons.chevron_right, color: ColorPalette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return ColorPalette.opsPurple;
    }
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ColorPalette.textSecondary),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TypographyManager.bodySmall.copyWith(
            color: ColorPalette.textSecondary,
          ),
        ),
      ],
    );
  }
}
