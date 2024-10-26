import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';

import 'package:mit_pos/api.dart';
import 'package:mit_pos/config.dart';

final GlobalKey<NewProductFormState> newProductPageKey = GlobalKey<NewProductFormState>();

class NewProductForm extends StatefulWidget {
  final String initialBarcode;

  const NewProductForm({super.key, required this.initialBarcode});

  @override
  NewProductFormState createState() => NewProductFormState();
}

class NewProductFormState extends State<NewProductForm> {
  final _formKey = GlobalKey<FormState>();
  late String _barcode;
  String _name = '';
  String _size = '';
  double _price = 0.0;
  int _quantity = 1;
  
  // Add these controllers
  late TextEditingController _nameController;
  late TextEditingController _sizeController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;

  late FocusNode _priceFocusNode;

  bool _isLoading = false;
  bool _hasStock = true;

  @override
  void initState() {
    super.initState();
    _barcode = widget.initialBarcode;
    // Initialize controllers
    _nameController = TextEditingController(text: _name);
    _sizeController = TextEditingController(text: _size);
    _priceController = TextEditingController(text: _price.toStringAsFixed(2));
    _quantityController = TextEditingController(text: _quantity.toString());
    _priceFocusNode = FocusNode();

    // Load product info
    _loadProductInfo();
  }

  Future<void> _loadProductInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final productInfo = await ApiService.getProductInfo(_barcode);
      if (productInfo['has_product'] == true) {
        var data = productInfo['product_info'];
        setState(() {
          if (data['name'] != null) {
            _name = data['name'];
            _nameController.text = _name;
          }
          if (data['size'] != null) {
            _size = data['size'];
            _sizeController.text = _size;
          }
          if (data['price'] != null) {
            _price = data['price'];
            _priceController.text = _price.toStringAsFixed(2);
          }
          if (data['quantity'] != null) {
            _hasStock = data['quantity'] > 0;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(newProductPageKey.currentContext!).showSnackBar(
        SnackBar(content: Text('Error loading product info: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  XFile? _image;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _image = image;
      });

      _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    var request = http.MultipartRequest('POST', Uri.parse('${Config.apiEndpoint}/parse-product-data'));
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        
        if (jsonResponse.containsKey('data')) {
          Map<String, dynamic> data = jsonResponse['data'];
          
          setState(() {
            if (data.containsKey('name')) {
              _name = _capitalizeFirstLetter(data['name']);
              _nameController.text = _name;
            }
            if (data.containsKey('content')) {
              _size = data['content'];
              _sizeController.text = _size;
            }
            if (data.containsKey('quantity')) {
              _quantity = int.parse(data['quantity'].toString());
              _quantityController.text = data['quantity'].toString();
            }
          });
          
          _formKey.currentState?.setState(() {});

          WidgetsBinding.instance.addPostFrameCallback((_) {
            FocusScope.of(context).requestFocus(_priceFocusNode);
          });

        }
      } else {
        ScaffoldMessenger.of(newProductPageKey.currentContext!).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(newProductPageKey.currentContext!).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
      _quantityController.text = _quantity.toString();
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
        _quantityController.text = _quantity.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell a product'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: _barcode,
                      decoration: const InputDecoration(labelText: 'Barcode'),
                      readOnly: true, // Make the field read-only
                      enabled: false, // Disable the field
                      style: TextStyle(color: Colors.grey[700]), // Optional: change text color to indicate it's read-only
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _pickImage();
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Fill info from photo'),
                    ),
                    TextFormField(
                      controller: _nameController,  // Use controller instead of initialValue
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                      onChanged: (value) { 
                        if (value.isNotEmpty) {
                          setState(() {
                            _name = value;
                          });
                        }
                      },
                    ),
                    TextFormField(
                      controller: _sizeController,  // Use controller instead of initialValue
                      decoration: const InputDecoration(labelText: 'Size'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a size';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            _size = value;
                          });
                        }
                      },
                    ),
                    TextFormField(
                      controller: _priceController,
                      inputFormatters: [CurrencyTextInputFormatter.currency(
                        locale: 'en_US',
                        symbol: '\$',
                        decimalDigits: 2,
                      )],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price'),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            _price = double.parse(value.replaceAll('\$', ''));
                          });
                        } else {
                          setState(() {
                            _price = 0.0;
                          });
                        }
                      },
                      focusNode: _priceFocusNode,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(labelText: 'Quantity'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a quantity';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid integer';
                              }
                              if (int.parse(value) < 1) {
                                return 'Quantity must be at least 1';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (int.tryParse(value) != null) {
                                setState(() {
                                  _quantity = int.parse(value);
                                });
                              }
                            },
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _incrementQuantity,
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _decrementQuantity,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), // Add some spacing
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: (_name.isNotEmpty && _size.isNotEmpty && _price > 0 && _hasStock)
                            ? () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();

                                  Navigator.pop(context, {
                                    'barcode': _barcode,
                                    'name': _name,
                                    'size': _size,
                                    'price': _price,
                                    'quantity': _quantity,
                                  });
                                }
                              }
                            : null,
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            _hasStock ? 'Add to cart' : 'No stock',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
