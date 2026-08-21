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
import 'presentation/ui/admin/admin_dashboard_screen.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/product_controller.dart';

class WebTheme {
  static const Color primary = Color(0xFF2563EB); // Modern Blue
  static const Color secondary = Color(0xFF10B981); // Emerald
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFF0F172A);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light, background: bgLight),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark, background: bgDark),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
    );
  }
}

class WebTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'home': 'Home',
      'categories': 'Categories',
      'search': 'Search products...',
      'login': 'Login',
      'logout': 'Logout',
      'cart': 'Cart',
      'seller_dashboard': 'Seller Dashboard',
      'seller_mode': 'Seller Mode',
    },
    'fr_FR': {
      'home': 'Accueil',
      'categories': 'Catégories',
      'search': 'Rechercher...',
      'login': 'Connexion',
      'logout': 'Déconnexion',
      'cart': 'Panier',
      'seller_dashboard': 'Tableau de bord Vendeur',
      'seller_mode': 'Mode Vendeur',
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
  runApp(const OrbitWebApp());
}

class OrbitWebApp extends StatelessWidget {
  const OrbitWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Orbit Web Marketplace',
      theme: WebTheme.light,
      darkTheme: WebTheme.dark,
      themeMode: ThemeMode.system,
      translations: WebTranslations(),
      locale: const Locale('en', 'US'),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => LoginScreen()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/register', page: () => RegisterScreen()),
        GetPage(name: '/forgot-password', page: () => const ForgotPasswordScreen()),
        GetPage(name: '/verify-otp', page: () => const VerifyOtpScreen()),
        GetPage(name: '/reset-password', page: () => const ResetPasswordScreen()),
        GetPage(name: '/home', page: () => const WebLayout()),
        GetPage(name: '/admin', page: () => const AdminDashboardScreen()),
      ],
    );
  }
}

class WebLayout extends StatelessWidget {
  const WebLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AuthController());
    final productCtrl = Get.put(ProductController());
    final activeTab = 'home'.obs;
    final isSellerMode = false.obs;

    // Load initial data
    if (ctrl.userRole.value == 'Seller') {
      productCtrl.fetchMyProducts(ctrl.userId.value);
      productCtrl.fetchReceivedOrders(ctrl.userId.value);
    }
    productCtrl.fetchMyOrders(ctrl.userId.value);

    // Form fields for adding product
    final nameFormController = TextEditingController();
    final descFormController = TextEditingController();
    final priceFormController = TextEditingController();
    final stockFormController = TextEditingController();
    final imgFormController = TextEditingController();
    final addFormKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
            color: Theme.of(context).appBarTheme.backgroundColor,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            children: [
              Text('Orbit', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: WebTheme.primary)),
              const SizedBox(width: 40),
              Obx(() {
                if (isSellerMode.value) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => activeTab.value = 'dashboard',
                        child: Text('Dashboard', style: TextStyle(fontSize: 16, fontWeight: activeTab.value == 'dashboard' ? FontWeight.bold : FontWeight.normal)),
                      ),
                      const SizedBox(width: 20),
                      TextButton(
                        onPressed: () {
                          activeTab.value = 'products';
                          productCtrl.fetchMyProducts(ctrl.userId.value);
                        },
                        child: Text('my_products'.tr, style: TextStyle(fontSize: 16, fontWeight: activeTab.value == 'products' ? FontWeight.bold : FontWeight.normal)),
                      ),
                      const SizedBox(width: 20),
                      TextButton(
                        onPressed: () {
                          activeTab.value = 'received_orders';
                          productCtrl.fetchReceivedOrders(ctrl.userId.value);
                        },
                        child: Text('orders'.tr, style: TextStyle(fontSize: 16, fontWeight: activeTab.value == 'received_orders' ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => activeTab.value = 'home',
                        child: Text('home'.tr, style: TextStyle(fontSize: 16, fontWeight: activeTab.value == 'home' ? FontWeight.bold : FontWeight.normal)),
                      ),
                      const SizedBox(width: 20),
                      TextButton(
                        onPressed: () {
                          activeTab.value = 'orders';
                          productCtrl.fetchMyOrders(ctrl.userId.value);
                        },
                        child: Text('orders'.tr, style: TextStyle(fontSize: 16, fontWeight: activeTab.value == 'orders' ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ],
                  );
                }
              }),
              const Spacer(),
              SizedBox(
                width: 300,
                height: 40,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'search'.tr,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Get.isDarkMode ? Colors.black26 : Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const Spacer(),
              Obx(() => ctrl.userRole.value == 'Seller'
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront, size: 20),
                      const SizedBox(width: 8),
                      Text('seller_mode'.tr, style: const TextStyle(fontWeight: FontWeight.w500)),
                      Switch(
                        value: isSellerMode.value,
                        onChanged: (v) {
                          isSellerMode.value = v;
                          if (v) {
                            activeTab.value = 'dashboard';
                            productCtrl.fetchMyProducts(ctrl.userId.value);
                            productCtrl.fetchReceivedOrders(ctrl.userId.value);
                          } else {
                            activeTab.value = 'home';
                          }
                        },
                        activeColor: WebTheme.primary,
                      ),
                      const SizedBox(width: 20),
                    ],
                  )
                : const SizedBox.shrink()
              ),
              IconButton(
                icon: const Icon(Icons.brightness_6),
                onPressed: () => Get.changeThemeMode(Get.isDarkMode ? ThemeMode.light : ThemeMode.dark),
              ),
              IconButton(
                icon: const Icon(Icons.language),
                onPressed: () {
                  var locale = Get.locale?.languageCode == 'en' ? const Locale('fr', 'FR') : const Locale('en', 'US');
                  Get.updateLocale(locale);
                },
              ),
              const SizedBox(width: 20),
              OutlinedButton(onPressed: () => ctrl.logout(), child: Text('logout'.tr)),
            ],
          ),
        ),
      ),
      body: Obx(() {
        final tab = activeTab.value;
        if (isSellerMode.value) {
          if (tab == 'dashboard') {
            return _buildSellerDashboardHome(context, ctrl, productCtrl);
          } else if (tab == 'products') {
            return _buildSellerProductsView(context, ctrl, productCtrl, addFormKey, nameFormController, descFormController, priceFormController, stockFormController, imgFormController);
          } else {
            return _buildSellerOrdersReceivedView(context, productCtrl);
          }
        } else {
          if (tab == 'home') {
            return _buildMarketplaceHome(context, ctrl, productCtrl);
          } else {
            return _buildMyOrders(context, productCtrl);
          }
        }
      }),
    );
  }

  Widget _buildMarketplaceHome(BuildContext context, AuthController ctrl, ProductController productCtrl) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero Banner
          Container(
            width: double.infinity,
            height: 250,
            color: WebTheme.primary.withOpacity(0.1),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Discover Amazing Products", style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("The best global marketplace for everything you need.", style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ),
          // Products Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
            child: Obx(() {
              if (productCtrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (productCtrl.products.isEmpty) {
                return const Center(child: Text("No products available."));
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                ),
                itemCount: productCtrl.products.length,
                itemBuilder: (context, index) {
                  final prod = productCtrl.products[index];
                  final isOwn = prod['seller_id'] == ctrl.userId.value;
                  final hasStock = prod['stock'] > 0;

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: prod['image_url'] != null && (prod['image_url'] as String).isNotEmpty
                                ? Image.network(
                                    prod['image_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.image, size: 50, color: Colors.grey),
                                  )
                                : const Icon(Icons.image, size: 50, color: Colors.grey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(prod['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(prod['description'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("\$${prod['price']}", style: const TextStyle(color: WebTheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: isOwn
                                    ? const OutlinedButton(
                                        onPressed: null,
                                        child: Text("Your Listing"),
                                      )
                                    : !hasStock
                                        ? const ElevatedButton(
                                            onPressed: null,
                                            child: Text("Out of Stock"),
                                          )
                                        : ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: WebTheme.primary, foregroundColor: Colors.white),
                                            onPressed: () {
                                              Get.defaultDialog(
                                                title: 'Confirm Purchase',
                                                content: Padding(
                                                  padding: const EdgeInsets.all(12.0),
                                                  child: Text('Place Cash on Delivery (COD) order for 1 unit of ${prod['title']}?'),
                                                ),
                                                textCancel: 'Cancel',
                                                textConfirm: 'Confirm (COD)',
                                                confirmTextColor: Colors.white,
                                                onConfirm: () async {
                                                  Get.back();
                                                  await productCtrl.buyProduct(
                                                    buyerId: ctrl.userId.value,
                                                    sellerId: prod['seller_id'],
                                                    price: double.parse(prod['price'].toString()),
                                                    productId: prod['id'],
                                                    quantity: 1,
                                                  );
                                                },
                                              );
                                            },
                                            child: const Text("Buy (COD)"),
                                          ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            }),
          )
        ],
      ),
    );
  }  Widget _buildSellerDashboardHome(
    BuildContext context,
    AuthController ctrl,
    ProductController productCtrl,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Seller Dashboard", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Welcome back, ${ctrl.userName.value}! Here is a summary of your sales and status.", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Obx(() {
            final listingsCount = productCtrl.myProducts.length;
            final ordersCount = productCtrl.receivedOrders.length;
            double totalSales = 0;
            for (var o in productCtrl.receivedOrders) {
              totalSales += double.parse(o['total_price'].toString());
            }

            return Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                _buildStatCard(
                  context,
                  title: "Total Revenue",
                  value: "\$${totalSales.toStringAsFixed(2)}",
                  icon: Icons.monetization_on,
                  color: const Color(0xFF10B981),
                ),
                _buildStatCard(
                  context,
                  title: "Active Listings",
                  value: "$listingsCount items",
                  icon: Icons.storefront,
                  color: const Color(0xFF2563EB),
                ),
                _buildStatCard(
                  context,
                  title: "Orders Received",
                  value: "$ordersCount orders",
                  icon: Icons.receipt_long,
                  color: const Color(0xFFF59E0B),
                ),
              ],
            );
          }),
          const SizedBox(height: 40),
          Text("Recent Received Checkouts", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Obx(() {
              if (productCtrl.receivedOrders.isEmpty) {
                return const Center(child: Text("No checkouts received yet."));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: productCtrl.receivedOrders.length > 5 ? 5 : productCtrl.receivedOrders.length,
                separatorBuilder: (c, i) => const Divider(),
                itemBuilder: (context, index) {
                  final order = productCtrl.receivedOrders[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFEF3C7),
                      child: Icon(Icons.shopping_bag, color: Color(0xFFD97706)),
                    ),
                    title: Text("Invoice: #${order['id'].substring(0, 8)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Buyer ID: ${order['buyer_id']}"),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("\$${order['total_price']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: WebTheme.primary)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order['status'],
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerProductsView(
    BuildContext context,
    AuthController ctrl,
    ProductController productCtrl,
    GlobalKey<FormState> formKey,
    TextEditingController nameCtrl,
    TextEditingController descCtrl,
    TextEditingController priceCtrl,
    TextEditingController stockCtrl,
    TextEditingController imgCtrl,
  ) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("My Active Products", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: WebTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Get.dialog(
                    Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        width: 500,
                        padding: const EdgeInsets.all(32.0),
                        child: Form(
                          key: formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Create New Listing", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Get.back(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text("Publish a new product to the marketplace instantly.", style: TextStyle(color: Colors.grey[500])),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: nameCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Product Name',
                                    prefixIcon: const Icon(Icons.shopping_bag_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  validator: (v) => v == null || v.isEmpty ? 'Product name is required' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: descCtrl,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: 'Product Description',
                                    prefixIcon: const Icon(Icons.description_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: priceCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          labelText: 'Price (\$)',
                                          prefixIcon: const Icon(Icons.attach_money_outlined),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) return 'Required';
                                          if (double.tryParse(v) == null) return 'Invalid price';
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: stockCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Stock Qty',
                                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) return 'Required';
                                          if (int.tryParse(v) == null) return 'Invalid stock';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: imgCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Image URL',
                                    prefixIcon: const Icon(Icons.image_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: WebTheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () async {
                                      if (formKey.currentState!.validate()) {
                                        Get.back();
                                        await productCtrl.addProduct({
                                          'title': nameCtrl.text.trim(),
                                          'description': descCtrl.text.trim(),
                                          'price': double.parse(priceCtrl.text),
                                          'stock': int.parse(stockCtrl.text),
                                          'image_url': imgCtrl.text.trim(),
                                        }, ctrl.userId.value);

                                        nameCtrl.clear();
                                        descCtrl.clear();
                                        priceCtrl.clear();
                                        stockCtrl.clear();
                                        imgCtrl.clear();
                                      }
                                    },
                                    child: const Text("Publish Product", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Add Product", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Grid View of Products (Matches Discover grid styling but with a delete action)
          Expanded(
            child: Obx(() {
              if (productCtrl.myProducts.isEmpty) {
                return const Center(child: Text("You have not listed any products yet. Click 'Add Product' to get started."));
              }
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                ),
                itemCount: productCtrl.myProducts.length,
                itemBuilder: (context, index) {
                  final prod = productCtrl.myProducts[index];
                  final hasStock = prod['stock'] > 0;

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: prod['image_url'] != null && (prod['image_url'] as String).isNotEmpty
                                ? Image.network(
                                    prod['image_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.image, size: 50, color: Colors.grey),
                                  )
                                : const Icon(Icons.image, size: 50, color: Colors.grey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(prod['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(prod['description'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("\$${prod['price']}", style: const TextStyle(color: WebTheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text("Qty: ${prod['stock']}", style: TextStyle(color: hasStock ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Active Status", style: TextStyle(fontWeight: FontWeight.bold, color: (prod['is_active'] ?? true) ? Colors.green : Colors.grey)),
                                  Switch(
                                    value: prod['is_active'] ?? true,
                                    activeColor: Colors.green,
                                    onChanged: (val) async {
                                      final updatedData = {
                                        'title': prod['title'],
                                        'description': prod['description'],
                                        'price': double.parse(prod['price'].toString()),
                                        'stock': prod['stock'],
                                        'image_url': prod['image_url'],
                                        'is_active': val,
                                      };
                                      await productCtrl.updateProduct(prod['id'], updatedData, ctrl.userId.value);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () {
                                        nameCtrl.text = prod['title'];
                                        descCtrl.text = prod['description'] ?? '';
                                        priceCtrl.text = prod['price'].toString();
                                        stockCtrl.text = prod['stock'].toString();
                                        imgCtrl.text = prod['image_url'] ?? '';

                                        Get.dialog(
                                          Dialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            child: Container(
                                              width: 500,
                                              padding: const EdgeInsets.all(32.0),
                                              child: Form(
                                                key: formKey,
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text("Edit Listing", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                                          IconButton(
                                                            icon: const Icon(Icons.close),
                                                            onPressed: () => Get.back(),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 24),
                                                      TextFormField(
                                                        controller: nameCtrl,
                                                        decoration: InputDecoration(
                                                          labelText: 'Product Name',
                                                          prefixIcon: const Icon(Icons.shopping_bag_outlined),
                                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                        ),
                                                        validator: (v) => v == null || v.isEmpty ? 'Product name is required' : null,
                                                      ),
                                                      const SizedBox(height: 16),
                                                      TextFormField(
                                                        controller: descCtrl,
                                                        maxLines: 3,
                                                        decoration: InputDecoration(
                                                          labelText: 'Product Description',
                                                          prefixIcon: const Icon(Icons.description_outlined),
                                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                        ),
                                                        validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
                                                      ),
                                                      const SizedBox(height: 16),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: TextFormField(
                                                              controller: priceCtrl,
                                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                              decoration: InputDecoration(
                                                                labelText: 'Price (\$)',
                                                                prefixIcon: const Icon(Icons.attach_money_outlined),
                                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                              ),
                                                              validator: (v) {
                                                                if (v == null || v.isEmpty) return 'Required';
                                                                if (double.tryParse(v) == null) return 'Invalid price';
                                                                return null;
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(width: 16),
                                                          Expanded(
                                                            child: TextFormField(
                                                              controller: stockCtrl,
                                                              keyboardType: TextInputType.number,
                                                              decoration: InputDecoration(
                                                                labelText: 'Stock Qty',
                                                                prefixIcon: const Icon(Icons.inventory_2_outlined),
                                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                              ),
                                                              validator: (v) {
                                                                if (v == null || v.isEmpty) return 'Required';
                                                                if (int.tryParse(v) == null) return 'Invalid stock';
                                                                return null;
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 16),
                                                      TextFormField(
                                                        controller: imgCtrl,
                                                        decoration: InputDecoration(
                                                          labelText: 'Image URL',
                                                          prefixIcon: const Icon(Icons.image_outlined),
                                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 24),
                                                      SizedBox(
                                                        width: double.infinity,
                                                        height: 50,
                                                        child: ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: WebTheme.primary,
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                          ),
                                                          onPressed: () async {
                                                            if (formKey.currentState!.validate()) {
                                                              Get.back();
                                                              await productCtrl.updateProduct(prod['id'], {
                                                                'title': nameCtrl.text.trim(),
                                                                'description': descCtrl.text.trim(),
                                                                'price': double.parse(priceCtrl.text),
                                                                'stock': int.parse(stockCtrl.text),
                                                                'image_url': imgCtrl.text.trim(),
                                                                'is_active': prod['is_active'] ?? true,
                                                              }, ctrl.userId.value);

                                                              nameCtrl.clear();
                                                              descCtrl.clear();
                                                              priceCtrl.clear();
                                                              stockCtrl.clear();
                                                              imgCtrl.clear();
                                                            }
                                                          },
                                                          child: const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.edit_outlined, size: 16),
                                      label: const Text("Edit"),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[50],
                                        foregroundColor: Colors.red,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => productCtrl.deleteProduct(prod['id'], ctrl.userId.value),
                                      icon: const Icon(Icons.delete_outline, size: 16),
                                      label: const Text("Delete"),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerOrdersReceivedView(BuildContext context, ProductController productCtrl) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Received Checkouts", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Obx(() {
                if (productCtrl.receivedOrders.isEmpty) {
                  return const Center(child: Text("No checkouts received yet."));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: productCtrl.receivedOrders.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final order = productCtrl.receivedOrders[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFEF3C7),
                        child: Icon(Icons.shopping_bag, color: Color(0xFFD97706)),
                      ),
                      title: Text("Invoice: #${order['id'].substring(0, 8)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Buyer ID: ${order['buyer_id']}"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("\$${order['total_price']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: WebTheme.primary)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order['status'],
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return SizedBox(
      width: 300,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 14), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyOrders(BuildContext context, ProductController productCtrl) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("My Orders (Purchases)", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: Obx(() {
              if (productCtrl.myOrders.isEmpty) {
                return const Center(child: Text("You have not purchased any products yet."));
              }
              return ListView.builder(
                itemCount: productCtrl.myOrders.length,
                itemBuilder: (context, index) {
                  final order = productCtrl.myOrders[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_shipping, color: WebTheme.secondary),
                      title: Text("Order ID: ${order['id']}"),
                      subtitle: Text("Seller ID: ${order['seller_id']}"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("\$${order['total_price']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(order['status'], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          )
        ],
      ),
    );
  }
}
