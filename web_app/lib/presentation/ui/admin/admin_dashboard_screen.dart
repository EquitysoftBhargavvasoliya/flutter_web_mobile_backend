import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/user_controller.dart';
import 'add_edit_product_dialog.dart';
import '../../../main.dart'; // For WebTheme

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProductController _productController = Get.put(ProductController());
  final UserController _userController = Get.put(UserController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: WebTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: WebTheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.inventory), text: 'Products'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Get.find<AuthController>().logout();
              Get.offAllNamed('/home');
            },
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildProductsTab(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Obx(() {
      if (_userController.isLoading.value && _userController.users.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_userController.users.isEmpty) {
        return const Center(child: Text("No users found."));
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          child: DataTable(
            headingRowColor: WidgetStateProperty.resolveWith((states) => Colors.grey[200]),
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _userController.users.map((user) {
              return DataRow(cells: [
                DataCell(Text(user['id']?.toString() ?? '-')),
                DataCell(Text(user['name']?.toString() ?? '-')),
                DataCell(Text(user['email']?.toString() ?? '-')),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteUser(user['id'].toString()),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      );
    });
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => const AddEditProductDialog(),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              style: ElevatedButton.styleFrom(backgroundColor: WebTheme.primary, foregroundColor: Colors.white),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (_productController.isLoading.value && _productController.products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_productController.products.isEmpty) {
              return const Center(child: Text("No products found."));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Card(
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.resolveWith((states) => Colors.grey[200]),
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _productController.products.map((product) {
                    return DataRow(cells: [
                      DataCell(Text(product['id']?.toString() ?? '-')),
                      DataCell(Text(product['name']?.toString() ?? '-')),
                      DataCell(Text("\$${product['price']?.toString() ?? '0.00'}")),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (context) => AddEditProductDialog(product: product),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteProduct(product['id'].toString()),
                            ),
                          ],
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _confirmDeleteUser(String id) {
    Get.defaultDialog(
      title: 'Delete User',
      middleText: 'Are you sure you want to delete this user?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        _userController.deleteUser(id);
      },
    );
  }

  void _confirmDeleteProduct(String id) {
    Get.defaultDialog(
      title: 'Delete Product',
      middleText: 'Are you sure you want to delete this product?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        _productController.deleteProduct(id);
      },
    );
  }
}
