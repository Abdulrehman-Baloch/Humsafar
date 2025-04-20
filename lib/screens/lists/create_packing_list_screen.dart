import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/packing_list.dart';

class AppColors {
  static const Color primaryColor = Colors.black;
  static const Color accentColor = Color(0xFFBA0E02);
  static const Color backgroundColor = Colors.white;
  static const Color lightGrey = Color(0xFFE9E7E7);
  static const Color midGrey = Color(0xFF9E9E9E);
  static const Color darkGrey = Color(0xFF424242);
}

class CreatePackingListScreen extends StatefulWidget {
  final PackingList? existingList;
  final String? tripId;
  final String? tripName;

  const CreatePackingListScreen({
    Key? key,
    this.existingList,
    this.tripId,
    this.tripName,
  }) : super(key: key);

  @override
  State<CreatePackingListScreen> createState() =>
      _CreatePackingListScreenState();
}

class _CreatePackingListScreenState extends State<CreatePackingListScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late List<PackingItem> _items;
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String _selectedCategory = 'Clothing';
  bool _isEssential = false;
  bool _showAddItemForm = false;
  Map<String, List<PackingItem>> _categorizedItems = {};
  bool _isSaving = false;

  // Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Predefined categories
  final List<String> _categories = [
    'Clothing',
    'Toiletries',
    'Electronics',
    'Documents',
    'Accessories',
    'Footwear',
    'Medicines',
    'Food & Drinks',
    'Outdoor Gear',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingList?.name ?? '',
    );
    _items = widget.existingList?.items ?? [];
    _updateCategorizedItems();

    // If editing an existing list, fetch the latest data from Firestore
    if (widget.existingList != null && widget.tripId != null) {
      _fetchPackingListFromFirestore();
    }
  }

  Future<void> _fetchPackingListFromFirestore() async {
    try {
      final docSnap = await _firestore
          .collection('tripPlans')
          .doc(widget.tripId)
          .collection('packingLists')
          .doc(widget.existingList!.id)
          .get();

      if (docSnap.exists) {
        final data = docSnap.data() as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>)
            .map((item) => PackingItem.fromMap(item))
            .toList();

        setState(() {
          _nameController.text = data['name'];
          _items = items;
          _updateCategorizedItems();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading packing list: $e')),
      );
    }
  }

  void _updateCategorizedItems() {
    _categorizedItems = {};
    for (var item in _items) {
      if (!_categorizedItems.containsKey(item.category)) {
        _categorizedItems[item.category] = [];
      }
      _categorizedItems[item.category]!.add(item);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _addItem({PackingItem? existingItem, int? index}) {
    if (_itemNameController.text.isNotEmpty &&
        _quantityController.text.isNotEmpty) {
      final quantity = int.tryParse(_quantityController.text) ?? 1;
      if (quantity <= 0 || quantity > 1000)
        return; // Enforce quantity constraints

      setState(() {
        final newItem = PackingItem(
          name: _itemNameController.text,
          category: _selectedCategory,
          isEssential: _isEssential,
          isPacked: existingItem?.isPacked ?? false,
          quantity: quantity,
        );

        if (existingItem != null && index != null) {
          _items[index] = newItem; // Update existing item
        } else {
          _items.add(newItem); // Add new item
        }

        _itemNameController.clear();
        _quantityController.clear();
        _isEssential = false;
        _showAddItemForm = false;
        _updateCategorizedItems();
      });
    }
  }

  void _removeItem(PackingItem item) {
    setState(() {
      _items.remove(item);
      _updateCategorizedItems();
    });
  }

  void _editItem(PackingItem item, int index) {
    setState(() {
      _itemNameController.text = item.name;
      _selectedCategory = item.category;
      _isEssential = item.isEssential;
      _quantityController.text = item.quantity.toString();
      _showAddItemForm = true;
    });
    _showAddItemDialog(existingItem: item, index: index);
  }

  void _toggleItemPacked(PackingItem item, bool value) {
    setState(() {
      item.isPacked = value;
    });

    if (widget.existingList != null && widget.tripId != null) {
      _updateItemInFirestore(item);
    }
  }

  Future<void> _updateItemInFirestore(PackingItem item) async {
    try {
      final docRef = _firestore
          .collection('tripPlans')
          .doc(widget.tripId)
          .collection('packingLists')
          .doc(widget.existingList!.id);

      final docSnap = await docRef.get();

      if (docSnap.exists) {
        final data = docSnap.data() as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>);

        for (int i = 0; i < items.length; i++) {
          if (items[i]['name'] == item.name &&
              items[i]['category'] == item.category) {
            items[i]['isPacked'] = item.isPacked;
            items[i]['quantity'] = item.quantity;
            break;
          }
        }

        await docRef.update({'items': items});
      }
    } catch (e) {
      print('Error updating item in Firestore: $e');
    }
  }

  Future<void> _saveList() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final listId = widget.existingList?.id ??
            DateTime.now().millisecondsSinceEpoch.toString();

        final list = PackingList(
          id: listId,
          name: _nameController.text,
          items: _items,
          createdAt: widget.existingList?.createdAt ?? DateTime.now(),
          tripId: widget.tripId,
        );

        if (widget.tripId != null) {
          final Map<String, dynamic> listData = {
            'id': list.id,
            'name': list.name,
            'createdAt': Timestamp.fromDate(list.createdAt),
            'tripId': list.tripId,
            'items': _items.map((item) => item.toMap()).toList(),
          };

          await _firestore
              .collection('tripPlans')
              .doc(widget.tripId)
              .collection('packingLists')
              .doc(listId)
              .set(listData);
        }

        Navigator.pop(context, list);
      } catch (e) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving packing list: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingList == null
              ? 'Create Packing List'
              : 'Edit Packing List',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        actions: [
          _isSaving
              ? Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : TextButton.icon(
                  icon: const Icon(Icons.check, color: Colors.white),
                  label:
                      const Text('SAVE', style: TextStyle(color: Colors.white)),
                  onPressed: _saveList,
                ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.lightGrey,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.tripName != null && widget.tripName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Trip: ${widget.tripName}',
                        style: TextStyle(
                          color: AppColors.darkGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'List Name',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a list name';
                      }
                      if (value.length > 200) {
                        return 'Name must be 200 characters or less';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.luggage, size: 64, color: AppColors.midGrey),
                        const SizedBox(height: 16),
                        Text(
                          'No items yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.darkGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add items to your packing list',
                          style: TextStyle(color: AppColors.midGrey),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    children: _categorizedItems.entries.map((entry) {
                      final category = entry.key;
                      final categoryItems = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGrey,
                              ),
                            ),
                          ),
                          ...categoryItems.asMap().entries.map((mapEntry) {
                            final index = mapEntry.key;
                            final item = mapEntry.value;
                            return _buildItemTile(item, index);
                          }).toList(),
                          const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          setState(() {
            _showAddItemForm = true;
            _itemNameController.clear();
            _quantityController.text = '1';
            _isEssential = false;
            _selectedCategory = 'Clothing';
          });
          _showAddItemDialog();
        },
      ),
    );
  }

  Widget _buildItemTile(PackingItem item, int index) {
    return Dismissible(
      key:
          Key(item.name + item.quantity.toString() + DateTime.now().toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _removeItem(item);
      },
      child: ListTile(
        leading: Checkbox(
          value: item.isPacked,
          activeColor: AppColors.accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          onChanged: (value) {
            _toggleItemPacked(item, value ?? false);
          },
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isPacked ? TextDecoration.lineThrough : null,
            color: item.isPacked ? AppColors.midGrey : Colors.black,
          ),
        ),
        subtitle: Text(
          'Quantity: ${item.quantity}',
          style: TextStyle(color: AppColors.midGrey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isEssential)
              Chip(
                label: const Text(
                  'Essential',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: AppColors.accentColor,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () => _editItem(item, index),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog({PackingItem? existingItem, int? index}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existingItem == null ? 'Add Item' : 'Edit Item',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _itemNameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      errorText: _itemNameController.text.isEmpty
                          ? 'Item name cannot be empty'
                          : _itemNameController.text.length > 200
                              ? 'Item name must be 200 characters or less'
                              : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _categories.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      errorText: _quantityController.text.isEmpty
                          ? 'Quantity cannot be empty'
                          : (int.tryParse(_quantityController.text) ?? 0) <= 0
                              ? 'Quantity must be greater than 0'
                              : (int.tryParse(_quantityController.text) ?? 0) >
                                      1000
                                  ? 'Quantity must be 1000 or less'
                                  : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Mark as essential'),
                    value: _isEssential,
                    onChanged: (value) {
                      setState(() {
                        _isEssential = value ?? false;
                      });
                    },
                    activeColor: AppColors.accentColor,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _itemNameController.clear();
                          _quantityController.clear();
                          _isEssential = false;
                        },
                        child: Text(
                          'CANCEL',
                          style: TextStyle(color: AppColors.darkGrey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: (_itemNameController.text.isNotEmpty &&
                                _quantityController.text.isNotEmpty &&
                                (int.tryParse(_quantityController.text) ?? 0) >
                                    0 &&
                                (int.tryParse(_quantityController.text) ?? 0) <=
                                    1000)
                            ? () {
                                _addItem(
                                    existingItem: existingItem, index: index);
                                Navigator.pop(context);
                              }
                            : null,
                        child: Text(
                          existingItem == null ? 'ADD' : 'UPDATE',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
