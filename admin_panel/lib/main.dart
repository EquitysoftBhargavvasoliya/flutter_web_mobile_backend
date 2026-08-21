import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_translations.dart';
import 'core/routing/app_routes.dart';
import 'presentation/controllers/admin_controller.dart';
import 'presentation/ui/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('No .env file found');
  }
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AdminController());
    return GetMaterialApp(
      title: 'Orbit Admin',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: AppRoutes.login,
      getPages: [
        GetPage(name: AppRoutes.login, page: () => LoginScreen()),
        GetPage(name: AppRoutes.dashboard, page: () => const MainLayout()),
      ],
    );
  }
}

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find<AdminController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text('Orbit Admin Panel - ${controller.activeTab.value.capitalizeFirst}')),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              Get.changeThemeMode(Get.isDarkMode ? ThemeMode.light : ThemeMode.dark);
            },
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              var locale = Get.locale?.languageCode == 'en' ? const Locale('fr', 'FR') : const Locale('en', 'US');
              Get.updateLocale(locale);
            },
          ),
          const SizedBox(width: 8),
          Obx(() => Center(
            child: Text(
              controller.adminName.value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          )),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => controller.logout(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Theme.of(context).colorScheme.surface,
            child: Obx(() => ListView(
              children: [
                _buildSidebarTile(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  isSelected: controller.activeTab.value == 'dashboard',
                  onTap: () => controller.activeTab.value = 'dashboard',
                ),
                _buildSidebarTile(
                  icon: Icons.people,
                  title: 'Users',
                  isSelected: controller.activeTab.value == 'users',
                  onTap: () => controller.activeTab.value = 'users',
                ),
                _buildSidebarTile(
                  icon: Icons.shopping_bag,
                  title: 'Products',
                  isSelected: controller.activeTab.value == 'products',
                  onTap: () => controller.activeTab.value = 'products',
                ),
                _buildSidebarTile(
                  icon: Icons.shopping_cart,
                  title: 'Orders',
                  isSelected: controller.activeTab.value == 'orders',
                  onTap: () => controller.activeTab.value = 'orders',
                ),
              ],
            )),
          ),
          // Main Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).colorScheme.background,
              child: Obx(() {
                switch (controller.activeTab.value) {
                  case 'dashboard':
                    return _buildDashboardView(context, controller);
                  case 'users':
                    return _buildUsersView(context, controller);
                  case 'products':
                    return _buildProductsView(context, controller);
                  case 'orders':
                    return _buildOrdersView(context, controller);
                  default:
                    return _buildDashboardView(context, controller);
                }
              }),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSidebarTile({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF6200EE) : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF6200EE) : null,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }

  Widget _buildDashboardView(BuildContext context, AdminController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome, ${controller.adminName.value}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Here is the live overview of Orbit Marketplace.', style: TextStyle(color: Colors.grey[500])),
        const SizedBox(height: 32),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            _buildStatCard(context, 'Total Sales', '${controller.totalSalesCount.value} orders', Icons.shopping_cart, Colors.blue),
            _buildStatCard(context, 'Active Users', '${controller.activeUsersCount.value} accounts', Icons.people, Colors.green),
            _buildStatCard(context, 'Total Revenue', '\$${controller.totalRevenue.value.toStringAsFixed(2)}', Icons.attach_money, Colors.purple),
            _buildStatCard(context, 'Active Products', '${controller.activeProductsCount} listed', Icons.inventory, Colors.orange),
            _buildStatCard(context, 'Total Products', '${controller.allProductsCount} total', Icons.widgets, Colors.teal),
          ],
        )
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 280,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, color: Colors.grey), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersView(BuildContext context, AdminController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Users List', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('View registered Buyer and Seller accounts.', style: TextStyle(color: Colors.grey[500])),
        const SizedBox(height: 24),
        Expanded(
          child: Card(
            child: controller.users.isEmpty
                ? const Center(child: Text("No users registered yet."))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: controller.users.map<DataRow>((u) {
                          return DataRow(cells: [
                            DataCell(Text(u['id'].toString())),
                            DataCell(Text(u['name'].toString())),
                            DataCell(Text(u['email'].toString())),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: u['role'] == 'Admin'
                                      ? Colors.purple.withOpacity(0.1)
                                      : u['role'] == 'Seller'
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  u['role'].toString(),
                                  style: TextStyle(
                                    color: u['role'] == 'Admin'
                                        ? Colors.purple
                                        : u['role'] == 'Seller'
                                            ? Colors.blue
                                            : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsView(BuildContext context, AdminController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Moderated Products', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Activate, deactivate, edit, or delete listings directly.', style: TextStyle(color: Colors.grey[500])),
        const SizedBox(height: 24),
        Expanded(
          child: Card(
            child: controller.products.isEmpty
                ? const Center(child: Text("No products listed yet."))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.products.length,
                    separatorBuilder: (c, i) => const Divider(),
                    itemBuilder: (context, index) {
                      final prod = controller.products[index];
                      final bool isActive = prod['is_active'] ?? true;
                      
                      return ListTile(
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
                          clipBehavior: Clip.antiAlias,
                          child: prod['image_url'] != null && (prod['image_url'] as String).isNotEmpty
                              ? Image.network(prod['image_url'], fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image))
                              : const Icon(Icons.image),
                        ),
                        title: Text(prod['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(
                          "\$${prod['price']} | Stock: ${prod['stock']} | Seller ID: ${prod['seller_id']}\n${prod['description'] ?? ''}",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Active status switch
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(isActive ? 'Active' : 'Inactive', style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                Switch(
                                  value: isActive,
                                  activeColor: Colors.green,
                                  onChanged: (val) {
                                    controller.toggleProductActive(
                                      prod['id'],
                                      val,
                                      prod['title'],
                                      prod['description'],
                                      double.parse(prod['price'].toString()),
                                      int.parse(prod['stock'].toString()),
                                      prod['image_url'],
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditProductDialog(context, controller, prod),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                Get.defaultDialog(
                                  title: 'Confirm Delete',
                                  content: Text('Are you sure you want to delete ${prod['title']} permanently?'),
                                  textCancel: 'Cancel',
                                  textConfirm: 'Delete',
                                  confirmTextColor: Colors.white,
                                  buttonColor: Colors.red,
                                  onConfirm: () {
                                    Get.back();
                                    controller.deleteProductDetail(prod['id']);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  void _showEditProductDialog(BuildContext context, AdminController controller, dynamic prod) {
    final nameCtrl = TextEditingController(text: prod['title']);
    final descCtrl = TextEditingController(text: prod['description'] ?? '');
    final priceCtrl = TextEditingController(text: prod['price'].toString());
    final stockCtrl = TextEditingController(text: prod['stock'].toString());
    final imgCtrl = TextEditingController(text: prod['image_url'] ?? '');
    final formKey = GlobalKey<FormState>();

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
                      Text("Edit Listing (Admin)", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Price (\$)', border: OutlineInputBorder()),
                          validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid price' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()),
                          validator: (v) => v == null || int.tryParse(v) == null ? 'Invalid stock' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: imgCtrl,
                    decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EE),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          Get.back();
                          await controller.updateProductDetail(prod['id'], {
                            'title': nameCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'price': double.parse(priceCtrl.text),
                            'stock': int.parse(stockCtrl.text),
                            'image_url': imgCtrl.text.trim(),
                            'is_active': prod['is_active'] ?? true,
                          });
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
  }

  Widget _buildOrdersView(BuildContext context, AdminController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Marketplace Orders', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('View all checkout logs processed by buyers.', style: TextStyle(color: Colors.grey[500])),
        const SizedBox(height: 24),
        Expanded(
          child: Card(
            child: controller.orders.isEmpty
                ? const Center(child: Text("No orders placed yet."))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Buyer ID', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Seller ID', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Total Price', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: controller.orders.map<DataRow>((o) {
                          return DataRow(cells: [
                            DataCell(Text(o['id'].toString())),
                            DataCell(Text(o['buyer_id'].toString())),
                            DataCell(Text(o['seller_id'].toString())),
                            DataCell(Text('\$${o['total_price']}')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: o['status'] == 'Pending'
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  o['status'].toString(),
                                  style: TextStyle(
                                    color: o['status'] == 'Pending' ? Colors.orange : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
