import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../core/ui_helpers.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Carrito de Compras"),
        backgroundColor: Colors.black,
      ),

      body: cart.items.isEmpty
          ? const Center(
              child: Text(
                "Tu carrito está vacío.",
                style: TextStyle(fontSize: 18),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, i) {
                      final item = cart.items[i];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        child: ListTile(
                          leading: Image.network(
                            item.product.imageUrl,
                            width: 60,
                            fit: BoxFit.cover,
                          ),
                          title: Text(item.product.name),
                          subtitle:
                              Text("\$${item.product.price.toStringAsFixed(0)} COP"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              debugPrint('CartScreen: Click en eliminar producto - ${item.product.name}');
                              final confirm = await ConfirmationHelper.showDeleteConfirmation(
                                context: context,
                                title: "¿Quitar del carrito?",
                                message: "¿Deseas eliminar este producto de tu carrito?",
                              );
                              debugPrint('CartScreen: Resultado confirmación: $confirm');
                              if (confirm) {
                                cart.removeFromCart(item.product);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // TOTAL
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, -2),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total:",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "\$${cart.totalPrice.toStringAsFixed(0)} COP",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Botón Pagar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Pago procesado (demo). Gracias!")),
                            );
                          },
                          child: const Text(
                            "Procesar Pago",
                            style: TextStyle(fontSize: 17),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
