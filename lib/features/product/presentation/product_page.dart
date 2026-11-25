import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/graphql/graphql_client.dart';
import '../../../core/l10n/l10n.dart';
import '../../cart/application/cart_controller.dart';
import '../application/product_providers.dart';
import '../domain/product_detail.dart';

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  String? _selectedVariantId;

  // Image decode/upload during the push transition janks the animation
  // (worst on single-threaded web); hold the placeholder until settled.
  bool _routeSettled = false;
  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeSettled || _routeAnimation != null) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      _routeSettled = true;
    } else {
      _routeAnimation = animation;
      animation.addStatusListener(_onRouteAnimationStatus);
    }
  }

  void _onRouteAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _routeSettled = true);
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(),
      body: product.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  describeError(context.l10n, error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(productProvider(widget.productId)),
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (detail) => _ProductView(
          product: detail,
          showImage: _routeSettled,
          selectedVariantId:
              _selectedVariantId ??
              detail.variants.where((v) => v.availableForSale).firstOrNull?.id,
          onVariantSelected: (id) => setState(() => _selectedVariantId = id),
        ),
      ),
    );
  }
}

class _ProductView extends ConsumerWidget {
  const _ProductView({
    required this.product,
    required this.showImage,
    required this.selectedVariantId,
    required this.onVariantSelected,
  });

  final ProductDetail product;
  final bool showImage;
  final String? selectedVariantId;
  final ValueChanged<String> onVariantSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedVariant = product.variants
        .where((v) => v.id == selectedVariantId)
        .firstOrNull;
    final cartBusy = ref.watch(cartControllerProvider).isLoading;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: product.imageUrl == null || !showImage
                    ? const ColoredBox(color: Colors.black12)
                    : CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        memCacheWidth: 1280,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            const ColoredBox(color: Colors.black12),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    if (selectedVariant != null)
                      Text(
                        context.money(selectedVariant.price),
                        style: theme.textTheme.titleLarge,
                      ),
                    if (!product.hasSingleVariant) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final variant in product.variants)
                            ChoiceChip(
                              label: Text(variant.title),
                              selected: variant.id == selectedVariantId,
                              onSelected: variant.availableForSale
                                  ? (_) => onVariantSelected(variant.id)
                                  : null,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      product.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: selectedVariant == null || cartBusy
                  ? null
                  : () async {
                      final l10n = context.l10n;
                      final messenger = ScaffoldMessenger.of(context);
                      final notifier = ref.read(
                        cartControllerProvider.notifier,
                      );
                      final success = await notifier.addLine(
                        selectedVariant.id,
                      );
                      if (success == null) return;
                      final error = success ? null : notifier.consumeError();
                      final message = success
                          ? l10n.addedToCart(product.title)
                          : error == null
                          ? l10n.addToCartFailed
                          : describeError(l10n, error);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(message),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(
                cartBusy ? context.l10n.adding : context.l10n.addToCart,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
