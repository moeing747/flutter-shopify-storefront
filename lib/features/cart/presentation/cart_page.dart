import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../application/cart_controller.dart';
import '../domain/cart.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(cartControllerProvider, (_, next) {
      if (next.hasError) {
        final message = ref
            .read(cartControllerProvider.notifier)
            .consumeError();
        if (message != null && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      }
    });

    final cartState = ref.watch(cartControllerProvider);
    final cart = cartState.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cart == null && cartState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cart == null || cart.isEmpty
          ? const Center(child: Text('Your cart is empty.'))
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
            ? line.price.format()
            : '${line.variantTitle} · ${line.price.format()}',
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
              Text('Subtotal', style: Theme.of(context).textTheme.titleMedium),
              Text(
                cart.subtotal.format(),
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
                          const SnackBar(
                            content: Text('Could not open checkout.'),
                          ),
                        );
                      }
                    },
              child: const Text('Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}
