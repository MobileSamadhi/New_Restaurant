class Cart {
  List<CartItem> items;

  Cart() : items = [];

  void addItem(CartItem item) {
    items.add(item);
  }

  void removeItem(int index) {
    items.removeAt(index);
  }

  double getTotalPrice() {
    double totalPrice = 0;
    for (var item in items) {
      totalPrice += item.price * item.quantity;
    }
    return totalPrice;
  }
}

class CartItem {
  final String productName;
  final double price;
  int quantity;
  int grams;

  CartItem({required this.productName, required this.price, required this.quantity, this.grams = 0});
}
