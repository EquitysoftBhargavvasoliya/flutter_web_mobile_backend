import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'dashboard': 'Dashboard',
          'users': 'Users',
          'categories': 'Categories',
          'products': 'Products',
          'orders': 'Orders',
          'settings': 'Settings',
          'login': 'Login',
          'email': 'Email',
          'password': 'Password',
          'welcome': 'Welcome to Orbit Admin',
          'total_sales': 'Total Sales',
          'active_users': 'Active Users',
          'revenue': 'Revenue',
          'search': 'Search...',
          'add_new': 'Add New',
          'logout': 'Logout',
        },
        'fr_FR': {
          'dashboard': 'Tableau de bord',
          'users': 'Utilisateurs',
          'categories': 'Catégories',
          'products': 'Produits',
          'orders': 'Commandes',
          'settings': 'Paramètres',
          'login': 'Connexion',
          'email': 'E-mail',
          'password': 'Mot de passe',
          'welcome': 'Bienvenue dans Orbit Admin',
          'total_sales': 'Ventes totales',
          'active_users': 'Utilisateurs actifs',
          'revenue': 'Revenu',
          'search': 'Recherche...',
          'add_new': 'Ajouter un nouveau',
          'logout': 'Déconnexion',
        }
      };
}
