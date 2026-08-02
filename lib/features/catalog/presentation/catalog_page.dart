import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../cart/application/cart_controller.dart';
import '../application/catalog_providers.dart';
import '../domain/product_summary.dart';

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.brand.displayName),
        actions: const [_CartButton()],
      ),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorRetry(
          message: error.toString(),
          onRetry: () => ref.invalidate(catalogControllerProvider),
        ),
        data: (connection) {
          final items = connection.items;
          if (items.isEmpty) {
            return const Center(child: Text('No products available.'));
          }
          // One extra slot at the end while more pages exist; building it
          // is the signal to fetch the next page.
          final itemCount = items.length + (connection.hasNextPage ? 1 : 0);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(catalogControllerProvider.future),
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  ref.read(catalogControllerProvider.notifier).loadMore();
                  return const Center(child: CircularProgressIndicator());
                }
                return _ProductCard(product: items[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CartButton extends ConsumerWidget {
  const _CartButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(
      cartControllerProvider.select(
        (cart) => cart.valueOrNull?.totalQuantity ?? 0,
      ),
    );

    return IconButton(
      onPressed: () => context.push('/cart'),
      icon: Badge(
        isLabelVisible: quantity > 0,
        label: Text('$quantity'),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ProductSummary product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id.split('/').last}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: product.imageUrl == null
                  ? const ColoredBox(
                      color: Colors.black12,
                      child: Center(child: Icon(Icons.image_not_supported)),
                    )
                  : CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      memCacheWidth: 640,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          const ColoredBox(color: Colors.black12),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'from ${product.minPrice.format()}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
