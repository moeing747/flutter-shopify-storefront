import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/graphql/graphql_client.dart';
import '../../../core/l10n/l10n.dart';
import '../application/cart_controller.dart';
import '../domain/cart.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(cartControllerProvider, (_, next) {
      if (next.hasError) {
        final error = ref.read(cartControllerProvider.notifier).consumeError();
        if (error != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(describeError(context.l10n, error))),
          );
        }
      }
    });

    final cartState = ref.watch(cartControllerProvider);
    final cart = cartState.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.cartTitle)),
      body: cart == null && cartState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cart == null || cart.isEmpty
          ? Center(child: Text(context.l10n.cartEmpty))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: cart.lines.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _CartLineTile(line: cart.lines[index]),
                  ),
                ),
                _CheckoutBar(cart: cart, busy: cartState.isLoading),
              ],
            ),
    );
  }
}

class _CartLineTile extends ConsumerWidget {
  const _CartLineTile({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(cartControllerProvider.notifier);
    final busy = ref.watch(cartControllerProvider).isLoading;

    return ListTile(
      leading: line.imageUrl == null
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: line.imageUrl!,
                memCacheWidth: 160,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
      title: Text(line.productTitle),
      subtitle: Text(
        line.variantTitle == 'Default Title'
            ? context.money(line.price)
            : '${line.variantTitle} · ${context.money(line.price)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: busy
                ? null
                : () => controller.setLineQuantity(line.id, line.quantity - 1),
            icon: Icon(
              line.quantity == 1 ? Icons.delete_outline : Icons.remove,
            ),
          ),
          Text('${line.quantity}'),
          IconButton(
            onPressed: busy
                ? null
                : () => controller.setLineQuantity(line.id, line.quantity + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.cart, required this.busy});

  final Cart cart;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.subtotal,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                context.money(cart.subtotal),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final l10n = context.l10n;
                      final messenger = ScaffoldMessenger.of(context);
                      var opened = false;
                      try {
                        opened = await launchUrl(
                          Uri.parse(cart.checkoutUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      } on Exception {
                        opened = false;
                      }
                      if (!opened) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.checkoutFailed)),
                        );
                      }
                    },
              child: Text(context.l10n.checkout),
            ),
          ),
        ],
      ),
    );
  }
}
