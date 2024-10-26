import 'package:logging/logging.dart';
import 'package:flutter/material.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mit_pos/firebase_options.dart';

import 'package:image_picker/image_picker.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import 'package:mit_pos/pages/new_product.dart';
import 'package:mit_pos/api.dart';

import 'logger_config.dart';

void main() async {
  setupLogging();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// Add this line at the top level of your file
final GlobalKey<MyHomePageState> myHomePageKey = GlobalKey<MyHomePageState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MIT POS for México',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA31F34), // MIT Red
          primary: const Color(0xFFA31F34), // MIT Red
          secondary: const Color(0xFF8A8B8C), // MIT Gray
          background: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFA31F34), // MIT Red
          foregroundColor: Colors.white, // White text for contrast
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA31F34), // MIT Red
            foregroundColor: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'MIT POS for México', key: myHomePageKey),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {

  final Logger _logger = Logger('_MyHomePageState');
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> currentInventory = [];
  int _currentTab = 0;
  Map<int, int> scannedItems = {};

  XFile? _image;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  late FirebaseMessaging _firebaseMessaging;
  String _message = '';

  bool _isDetectingProducts = false;

  Future<void> initialize() async {
    String? token = await messaging.getToken();
    print("Device Token: $token");
    // Send this token to your server to use it in Python to send notifications
  }

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    initialize();
  }

void _initializeNotifications() async {
  if (await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.areNotificationsEnabled() !=
      true) {
    // Request notification permissions if not already granted
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(initSettings);


  _firebaseMessaging = FirebaseMessaging.instance;

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Message received: ${message.notification?.title} - ${message.notification?.body}');
    setState(() {
      _message = message.notification?.title ?? 'New Notification';
    });
    _showInAppNotification(_message, message.notification?.body);
  });
}

  void _showInAppNotification(String title, String? body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body ?? 'New notification!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mitpos',
      'mitpos',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(0, title, body, details);
  }

  Future<void> _takePhotoAndDetectProduct() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _image = image;
        _isDetectingProducts = true;
      });

      // Show loading dialog
      showDialog(
        context: myHomePageKey.currentContext!,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      try {
        final result = await ApiService.sendImageForProductDetection(_image!.path);
        
        _logger.info('Product detection result: $result');

        // Reload the inventory list
        setState(() {
          // This will trigger a rebuild of the inventory tab
        });

      } catch (e) {
        _logger.severe('Error detecting products from image: $e');
        // Show error message to user
        ScaffoldMessenger.of(myHomePageKey.currentContext!).showSnackBar(
          SnackBar(content: Text('Error detecting products: $e')),
        );
      } finally {
        // Hide loading dialog
        Navigator.of(myHomePageKey.currentContext!).pop();
        setState(() {
          _isDetectingProducts = false;
        });
      }
    } else {
      _logger.warning('No image selected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Row(
            children: [
              const Icon(Icons.point_of_sale, color: Colors.white), // Add this line
              const SizedBox(width: 8), // Add some spacing
              Text(widget.title),
            ],
          ),
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.shopping_cart), text: 'Cart'),
              Tab(icon: Icon(Icons.list), text: 'Inventory'),
            ],
            onTap: (index) {
              setState(() {
                _currentTab = index;
              });
            },
          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              showNotification('Gracias por usar MIT POS', '¡Bienvenido de nuevo!');
            },
          ),
        ],
        ),
        body: TabBarView(
          children: [
            _buildCartTab(),
            _buildInventoryTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (_currentTab == 0) {
              var res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SimpleBarcodeScannerPage(),
                ),
              );
              
              if (res != null && res != '-1') {
                final newProduct = await Navigator.push(
                  myHomePageKey.currentContext!,
                  MaterialPageRoute(
                    builder: (context) => NewProductForm(initialBarcode: res),
                  ),
                );
                
                if (newProduct != null) {
                  setState(() {
                    products.add(newProduct);
                  });
                  ApiService.createProduct(newProduct);
                }
              }
            } else {
              await _takePhotoAndDetectProduct();
            }
          },
          tooltip: _currentTab == 0 ? 'Scan Barcode' : 'Scan products',
          child: Icon(_currentTab == 0 ? Icons.camera_alt : Icons.barcode_reader),
        ),
      ),
    );
  }

  Widget _buildCartTab() {
    return Column(
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Scan a barcode to add a new product',
            style: TextStyle(fontSize: 18),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(products[index]['name']),
                subtitle: Text('Quantity: ${products[index]['quantity']}'),
                trailing: Text('\$${(products[index]['price'] * products[index]['quantity']).toStringAsFixed(2)}'),
              );
            },
          ),
        ),
        // Add the checkout button here
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: products.isNotEmpty
              ? () {
                  setState(() {
                    products.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cart cleared. Checkout complete!')),
                  );
                }
              : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: products.isNotEmpty ? Colors.red : Colors.grey,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
            ),
            child: const Text('Checkout', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService.getInventory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isDetectingProducts) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No inventory items found'));
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              final itemId = item['id'];
              final quantity = item['quantity'];
              final scannedCount = scannedItems[itemId] ?? 0;
              final isConfirmed = scannedCount >= quantity || item['confirmed'] == 1;
              final isOutOfStock = quantity == 0;

              // When it is -1, it mean that one new item was added to the inventory, so it needs to be scanned
              if (item['confirmed'] == -1) {
                scannedItems[itemId] = quantity - 1;
              }

              return Dismissible(
                key: Key(itemId.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _deleteInventoryItem(itemId);
                },
                child: ListTile(
                  title: Text(
                    item['name'],
                    style: TextStyle(
                      color: isOutOfStock ? Colors.red : null,
                    ),
                  ),
                  subtitle: Text(
                    '${item['description']}',
                    style: TextStyle(
                      color: isOutOfStock ? Colors.red : null,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Quantity: ${item['quantity']}',
                        style: TextStyle(
                          color: isOutOfStock ? Colors.red : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isConfirmed ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isConfirmed ? 'C' : 'U',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      if (!isConfirmed) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner, size: 20),
                          onPressed: () => _scanItemBarcode(itemId, ((quantity == scannedCount + 1) || item['confirmed'] == -1)),
                        ),
                      ],
                    ],
                  ),
                  onTap: () => _showEditDialog(item),
                ),
              );
            },
          );
        }
      },
    );
  }

  Future<void> _scanItemBarcode(int itemId, bool lastItem) async {
    var res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleBarcodeScannerPage(),
      ),
    );
    
    if (res is String && res.isNotEmpty && res != '-1') {
      setState(() {
        scannedItems[itemId] = (scannedItems[itemId] ?? 0) + 1;
      });

      await ApiService.addProductToInventory({
        'barcode': res,
        'inventory_id': itemId,
      });

      if (lastItem) {
        await ApiService.confirmElement(itemId);
      }
      ScaffoldMessenger.of(myHomePageKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Barcode scanned successfully!')),
      );
    }
  }

  // Add this method to handle item deletion
  Future<void> _deleteInventoryItem(int itemId) async {
    try {
      await ApiService.deleteInventoryItem(itemId);
      setState(() {
        scannedItems.remove(itemId);
      });
      ScaffoldMessenger.of(myHomePageKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Item deleted successfully')),
      );
    } catch (e) {
      _logger.severe('Error deleting inventory item: $e');
      ScaffoldMessenger.of(myHomePageKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Error deleting item')),
      );
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    final nameController = TextEditingController(text: item['name']);
    final descriptionController = TextEditingController(text: item['description']);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                final updatedItem = {
                  'id': item['id'],
                  'name': nameController.text,
                  'description': descriptionController.text,
                };
                await _updateInventoryItem(updatedItem);
                Navigator.of(myHomePageKey.currentContext!).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateInventoryItem(Map<String, dynamic> updatedItem) async {
    try {
      await ApiService.updateNameAndDescription(updatedItem);
      setState(() {
        // Update the item in the local state if needed
      });
      ScaffoldMessenger.of(myHomePageKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Item updated successfully')),
      );
    } catch (e) {
      _logger.severe('Error updating inventory item: $e');
      ScaffoldMessenger.of(myHomePageKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Error updating item')),
      );
    }
  }
}
