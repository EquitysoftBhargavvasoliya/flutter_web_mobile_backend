import 'package:backend/src/core/network/database.dart';
import 'package:crypt/crypt.dart';

void main() async {
  print('Initializing database connection...');
  try {
    await Database.initialize();
    final pool = Database.pool;

    print('Updating existing users with "User" role to "Buyer"...');
    final res = await pool.execute("UPDATE users SET role = 'Buyer' WHERE role = 'User'");
    print('User migration complete! Affected rows: ${res.affectedRows}');

    print('Adding FCM token columns to users table...');
    await pool.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token_web VARCHAR(255)");
    await pool.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token_app VARCHAR(255)");

    print('Adding image_url column to products table...');
    await pool.execute("ALTER TABLE products ADD COLUMN IF NOT EXISTS image_url VARCHAR(500)");
    
    print('Adding is_active column to products table...');
    await pool.execute("ALTER TABLE products ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE");

    print('Checking if Super Admin exists...');
    final adminCheck = await pool.execute("SELECT id FROM users WHERE email = 'admin@gmail.com'");
    if (adminCheck.isEmpty) {
      print('Creating Super Admin user...');
      final passwordHash = Crypt.sha256('123456').toString();
      await pool.execute(
        "INSERT INTO users (email, password_hash, name, role) VALUES ('admin@gmail.com', '$passwordHash', 'Super Admin', 'Admin')"
      );
      print('Super Admin user created successfully!');
    } else {
      print('Super Admin user already exists.');
    }

    print('Product migration complete!');
  } catch (e) {
    print('Migration failed: $e');
  }
}
