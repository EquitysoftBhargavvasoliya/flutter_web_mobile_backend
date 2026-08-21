import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'presentation/ui/auth/login_screen.dart';
import 'presentation/ui/auth/register_screen.dart';
import 'presentation/ui/auth/forgot_password_screen.dart';
import 'presentation/ui/auth/verify_otp_screen.dart';
import 'presentation/ui/auth/reset_password_screen.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/product_controller.dart';

class AppTheme {
  static const Color primary = Color(0xFFE91E63);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color bgLight = Color(0xFFF9F9F9);
  static const Color bgDark = Color(0xFF121212);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light, background: bgLight),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgLight,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgLight,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark, background: bgDark),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgDark,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'home': 'Home',
      'search': 'Search',
      'cart': 'Cart',
      'profile': 'Profile',
      'seller_mode': 'Seller Mode',
      'my_products': 'My Products',
      'orders': 'Orders',
      'settings': 'Settings',
      'logout': 'Logout',
    },
    'fr_FR': {
      'home': 'Accueil',
      'search': 'Recherche',
      'cart': 'Panier',
      'profile': 'Profil',
      'seller_mode': 'Mode Vendeur',
      'my_products': 'Mes Produits',
      'orders': 'Commandes',
      'settings': 'Paramètres',
      'logout': 'Déconnexion',
    }
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('No .env file found');
  }
  runApp(const OrbitMobileApp());
}

class OrbitMobileApp extends StatelessWidget {
  const OrbitMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Orbit Mobile',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/register', page: () => RegisterScreen()),
        GetPage(name: '/forgot-password', page: () => const ForgotPasswordScreen()),
        GetPage(name: '/verify-otp', page: () => const VerifyOtpScreen()),
        GetPage(name: '/reset-password', page: () => const ResetPasswordScreen()),
        GetPage(name: '/home', page: () => MainNavigation()),
      ],
    );
  }
}

class MainNavController extends GetxController {
  var currentIndex = 0.obs;
  var isSellerMode = false.obs;

  void changePage(int index) {
    currentIndex.value = index;
  }

  void toggleSellerMode() {
    isSellerMode.value = !isSellerMode.value;
    currentIndex.value = 0; // reset to home of whichever mode
  }
}

class MainNavigation extends StatelessWidget {
  final MainNavController ctrl = Get.put(MainNavController());

  MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.put(AuthController());
    final productCtrl = Get.put(ProductController());

    // Trigger initial loads
    productCtrl.fetchProducts();
    if (authCtrl.userRole.value == 'Seller') {
      productCtrl.fetchMyProducts(authCtrl.userId.value);
      productCtrl.fetchReceivedOrders(authCtrl.userId.value);
    }
    productCtrl.fetchMyOrders(authCtrl.userId.value);

    return Obx(() {
      final isSeller = ctrl.isSellerMode.value;
      final pages = isSeller ? [
        SellerDashboardView(productCtrl: productCtrl, authCtrl: authCtrl),
        SellerMyProductsView(productCtrl: productCtrl, authCtrl: authCtrl),
        SellerOrdersReceivedView(productCtrl: productCtrl, authCtrl: authCtrl),
        ProfileView()
      ] : [
        MarketplaceHomeView(productCtrl: productCtrl, authCtrl: authCtrl),
        const Center(child: Text("Search & Categories (Under construction)")),
        MyOrdersView(productCtrl: productCtrl, authCtrl: authCtrl),
        ProfileView()
      ];

      final items = isSeller ? [
        BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: 'home'.tr),
        BottomNavigationBarItem(icon: const Icon(Icons.inventory), label: 'my_products'.tr),
        BottomNavigationBarItem(icon: const Icon(Icons.receipt), label: 'orders'.tr),
        BottomNavigationBarItem(icon: const Icon(Icons.person), label: 'profile'.tr),
      ] : [
        BottomNavigationBarItem(icon: const Icon(Icons.home), label: 'home'.tr),
        BottomNavigationBarItem(icon: const Icon(Icons.search), label: 'search'.tr),
        BottomNavigationBarItem(icon: const Icon(Icons.shopping_bag), label: 'orders'.tr),
        BottomNavigationBarItem(icon: const Icon(Icons.person), label: 'profile'.tr),
      ];

      return Scaffold(
        body: pages[ctrl.currentIndex.value],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: ctrl.currentIndex.value,
          onTap: ctrl.changePage,
          items: items,
        ),
      );
    });
  }
}

class ProfileView extends StatelessWidget {
  final MainNavController ctrl = Get.find();

  ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.put(AuthController());
    return Scaffold(
      appBar: AppBar(title: Text('profile'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 20),
          Obx(() => authCtrl.userRole.value == 'Seller'
              ? SwitchListTile(
                  title: Text('seller_mode'.tr),
                  value: ctrl.isSellerMode.value,
                  onChanged: (v) => ctrl.toggleSellerMode(),
                )
              : const SizedBox.shrink()),
          ListTile(
            title: const Text('Theme'),
            trailing: const Icon(Icons.brightness_4),
            onTap: () {
              Get.changeThemeMode(Get.isDarkMode ? ThemeMode.light : ThemeMode.dark);
            },
          ),
          ListTile(
            title: const Text('Language'),
            trailing: const Icon(Icons.language),
            onTap: () {
              var locale = Get.locale?.languageCode == 'en' ? const Locale('fr', 'FR') : const Locale('en', 'US');
              Get.updateLocale(locale);
            },
          ),
          ListTile(
            title: Text('logout'.tr),
            trailing: const Icon(Icons.exit_to_app, color: Colors.red),
            onTap: () => authCtrl.logout(),
          )
        ],
      ),
    );
  }
}

class MarketplaceHomeView extends StatelessWidget {
  final ProductController productCtrl;
  final AuthController authCtrl;

  const MarketplaceHomeView({super.key, required this.productCtrl, required this.authCtrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orbit Marketplace")),
      body: Obx(() {
        if (productCtrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (productCtrl.products.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => productCtrl.fetchProducts(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                Center(child: Text("No products available.")),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => productCtrl.fetchProducts(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: productCtrl.products.length,
            itemBuilder: (context, index) {
              final prod = productCtrl.products[index];
              final isOwn = prod['seller_id'] == authCtrl.userId.value;
              final hasStock = prod['stock'] > 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: prod['image_url'] != null && (prod['image_url'] as String).isNotEmpty
                            ? Image.network(prod['image_url'], fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image))
                            : const Icon(Icons.image),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prod['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(prod['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text("\$${prod['price']}", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          isOwn
                              ? const Text("Own listing", style: TextStyle(color: Colors.grey, fontSize: 12))
                              : !hasStock
                                  ? const Text("Sold Out", style: TextStyle(color: Colors.red, fontSize: 12))
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                                      onPressed: () {
                                        Get.defaultDialog(
                                          title: 'Checkout',
                                          content: Text('Confirm order for ${prod['title']} via Cash on Delivery (COD)?'),
                                          onConfirm: () async {
                                            Get.back();
                                            await productCtrl.buyProduct(
                                              buyerId: authCtrl.userId.value,
                                              sellerId: prod['seller_id'],
                                              price: double.parse(prod['price'].toString()),
                                              productId: prod['id'],
                                              quantity: 1,
                                            );
                                          },
                                          textCancel: 'Cancel',
                                          textConfirm: 'Confirm',
                                        );
                                      },
                                      child: const Text("Buy"),
                                    ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class MyOrdersView extends StatelessWidget {
  final ProductController productCtrl;
  final AuthController authCtrl;

  const MyOrdersView({super.key, required this.productCtrl, required this.authCtrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Orders")),
      body: Obx(() {
        if (productCtrl.myOrders.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => productCtrl.fetchMyOrders(authCtrl.userId.value),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                Center(child: Text("You have no orders.")),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => productCtrl.fetchMyOrders(authCtrl.userId.value),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: productCtrl.myOrders.length,
            itemBuilder: (context, index) {
              final order = productCtrl.myOrders[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.local_shipping, color: Colors.green),
                  title: Text("Order ID: ${order['id']}"),
                  subtitle: Text("Seller ID: ${order['seller_id']}"),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("\$${order['total_price']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(order['status'], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class SellerDashboardView extends StatelessWidget {
  final ProductController productCtrl;
  final AuthController authCtrl;

  const SellerDashboardView({super.key, required this.productCtrl, required this.authCtrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seller Dashboard")),
      body: Obx(() {
        final listingsCount = productCtrl.myProducts.length;
        final ordersCount = productCtrl.receivedOrders.length;
        double totalSales = 0;
        for (var o in productCtrl.receivedOrders) {
          totalSales += double.parse(o['total_price'].toString());
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hello, ${authCtrl.userName.value}!", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text("Listings", style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text("$listingsCount", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text("Total Sales", style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text("\$${totalSales.toStringAsFixed(2)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt, color: Colors.orange),
                  title: const Text("Orders Received"),
                  trailing: Text("$ordersCount", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class SellerMyProductsView extends StatelessWidget {
  final ProductController productCtrl;
  final AuthController authCtrl;

  SellerMyProductsView({super.key, required this.productCtrl, required this.authCtrl});

  final nameController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final imgController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Products"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Get.bottomSheet(
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        const Text("Add Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder()),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descController,
                          decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: "Price (\$)", border: OutlineInputBorder()),
                          validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid price' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Stock Qty", border: OutlineInputBorder()),
                          validator: (v) => v == null || int.tryParse(v) == null ? 'Enter valid stock count' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: imgController,
                          decoration: const InputDecoration(labelText: "Image URL", border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              Get.back();
                              await productCtrl.addProduct({
                                'title': nameController.text.trim(),
                                'description': descController.text.trim(),
                                'price': double.parse(priceController.text),
                                'stock': int.parse(stockController.text),
                                'image_url': imgController.text.trim(),
                              }, authCtrl.userId.value);
                              nameController.clear();
                              descController.clear();
                              priceController.clear();
                              stockController.clear();
                              imgController.clear();
                            }
                          },
                          child: const Text("Create Listing"),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: Obx(() {
        if (productCtrl.myProducts.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => productCtrl.fetchMyProducts(authCtrl.userId.value),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                Center(child: Text("No listed products yet. Press + to add.")),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => productCtrl.fetchMyProducts(authCtrl.userId.value),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: productCtrl.myProducts.length,
            itemBuilder: (context, index) {
              final prod = productCtrl.myProducts[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: prod['image_url'] != null && (prod['image_url'] as String).isNotEmpty
                        ? Image.network(prod['image_url'], width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image))
                        : const Icon(Icons.image),
                    title: Text(prod['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("\$${prod['price']} | Stock Qty: ${prod['stock']}"),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Active Status: ", style: TextStyle(color: (prod['is_active'] ?? true) ? Colors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(
                              height: 24,
                              child: Switch(
                                value: prod['is_active'] ?? true,
                                activeColor: Colors.green,
                                onChanged: (val) async {
                                  await productCtrl.updateProduct(prod['id'], {
                                    'title': prod['title'],
                                    'description': prod['description'],
                                    'price': double.parse(prod['price'].toString()),
                                    'stock': prod['stock'],
                                    'image_url': prod['image_url'],
                                    'is_active': val,
                                  }, authCtrl.userId.value);
                                },
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                          onPressed: () {
                            Get.bottomSheet(
                              Container(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                padding: const EdgeInsets.all(16),
                                child: Form(
                                  key: _formKey,
                                  child: ListView(
                                    children: [
                                      const Text("Edit Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: nameController..text = prod['title'],
                                        decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder()),
                                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: descController..text = prod['description'] ?? '',
                                        decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: priceController..text = prod['price'].toString(),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(labelText: "Price (\$)", border: OutlineInputBorder()),
                                        validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid price' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: stockController..text = prod['stock'].toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: "Stock Qty", border: OutlineInputBorder()),
                                        validator: (v) => v == null || int.tryParse(v) == null ? 'Enter valid stock count' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: imgController..text = prod['image_url'] ?? '',
                                        decoration: const InputDecoration(labelText: "Image URL", border: OutlineInputBorder()),
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: () async {
                                          if (_formKey.currentState!.validate()) {
                                            Get.back();
                                            await productCtrl.updateProduct(prod['id'], {
                                              'title': nameController.text.trim(),
                                              'description': descController.text.trim(),
                                              'price': double.parse(priceController.text),
                                              'stock': int.parse(stockController.text),
                                              'image_url': imgController.text.trim(),
                                              'is_active': prod['is_active'] ?? true,
                                            }, authCtrl.userId.value);
                                            nameController.clear();
                                            descController.clear();
                                            priceController.clear();
                                            stockController.clear();
                                            imgController.clear();
                                          }
                                        },
                                        child: const Text("Save Changes"),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => productCtrl.deleteProduct(prod['id'], authCtrl.userId.value),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class SellerOrdersReceivedView extends StatelessWidget {
  final ProductController productCtrl;
  final AuthController authCtrl;

  const SellerOrdersReceivedView({super.key, required this.productCtrl, required this.authCtrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orders Received")),
      body: Obx(() {
        if (productCtrl.receivedOrders.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => productCtrl.fetchReceivedOrders(authCtrl.userId.value),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                Center(child: Text("No orders received yet.")),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => productCtrl.fetchReceivedOrders(authCtrl.userId.value),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: productCtrl.receivedOrders.length,
            itemBuilder: (context, index) {
              final order = productCtrl.receivedOrders[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag, color: Colors.orange),
                  title: Text("Order ID: ${order['id']}"),
                  subtitle: Text("Buyer ID: ${order['buyer_id']}"),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("\$${order['total_price']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(order['status'], style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
