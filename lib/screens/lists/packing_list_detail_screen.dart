import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added Firestore import
import '../../models/packing_list.dart';

class AppColors {
  static const Color primaryColor = Colors.black;
  static const Color accentColor = Color(0xFFBA0E02);
  static const Color backgroundColor = Colors.white;
  static const Color lightGrey = Color(0xFFE9E7E7);
  static const Color midGrey = Color(0xFF9E9E9E);
  static const Color darkGrey = Color(0xFF424242);
  static const Color green = Color(0xFF43A047);
}

class PackingListDetailScreen extends StatefulWidget {
  final PackingList packingList;

  const PackingListDetailScreen({Key? key, required this.packingList})
      : super(key: key);

  @override
  State<PackingListDetailScreen> createState() =>
      _PackingListDetailScreenState();
}

class _PackingListDetailScreenState extends State<PackingListDetailScreen>
    with TickerProviderStateMixin {
  late Map<String, List<PackingItem>> _categorizedItems;
  late int _totalItems;
  late int _packedItems;
  late TabController _tabController;
  bool _showOnlyEssentials = false;
  bool _showOnlyUnpacked = false;

  // Added Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _updateCounts();
    _categorizeItems();
    _tabController =
        TabController(length: _categorizedItems.keys.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateCounts() {
    _totalItems = widget.packingList.items.length;
    _packedItems =
        widget.packingList.items.where((item) => item.isPacked).length;
  }

  void _categorizeItems() {
    _categorizedItems = {};

    // Filter items based on current view settings
    List<PackingItem> filteredItems = widget.packingList.items;

    if (_showOnlyEssentials) {
      filteredItems = filteredItems.where((item) => item.isEssential).toList();
    }

    if (_showOnlyUnpacked) {
      filteredItems = filteredItems.where((item) => !item.isPacked).toList();
    }

    // Group filtered items by category
    for (var item in filteredItems) {
      if (!_categorizedItems.containsKey(item.category)) {
        _categorizedItems[item.category] = [];
      }
      _categorizedItems[item.category]!.add(item);
    }
  }

  // Updated to persist changes to Firestore
  void _toggleItemPacked(PackingItem item) {
    setState(() {
      item.isPacked = !item.isPacked;
      _updateCounts();
    });

    // Save changes to Firestore if tripId is available
    _updateItemInFirestore(item);
  }

  // New method to update item in Firestore
  Future<void> _updateItemInFirestore(PackingItem item) async {
    try {
      // Only update if we have a tripId (list is associated with a trip)
      if (widget.packingList.tripId != null) {
        // Get reference to the packing list document
        final docRef = _firestore
            .collection('tripPlans')
            .doc(widget.packingList.tripId)
            .collection('packingLists')
            .doc(widget.packingList.id);

        // Get current document
        final docSnap = await docRef.get();

        if (docSnap.exists) {
          final data = docSnap.data() as Map<String, dynamic>;
          final items = (data['items'] as List<dynamic>);

          // Find and update the specific item
          for (int i = 0; i < items.length; i++) {
            if (items[i]['name'] == item.name &&
                items[i]['category'] == item.category) {
              items[i]['isPacked'] = item.isPacked;
              break;
            }
          }

          // Update only the items array in Firestore
          await docRef.update({'items': items});
        }
      }
    } catch (e) {
      print('Error updating item in Firestore: $e');
      // Optionally show a snackbar on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.packingList.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.primaryColor,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() {
                if (value == 'essentials') {
                  _showOnlyEssentials = !_showOnlyEssentials;
                  _showOnlyUnpacked = false;
                } else if (value == 'unpacked') {
                  _showOnlyUnpacked = !_showOnlyUnpacked;
                  _showOnlyEssentials = false;
                } else if (value == 'all') {
                  _showOnlyEssentials = false;
                  _showOnlyUnpacked = false;
                }
                _categorizeItems();
                _tabController = TabController(
                    length: _categorizedItems.keys.length, vsync: this);
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      color: (!_showOnlyEssentials && !_showOnlyUnpacked)
                          ? AppColors.accentColor
                          : AppColors.darkGrey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text('Show All'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'essentials',
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: _showOnlyEssentials
                          ? AppColors.accentColor
                          : AppColors.darkGrey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text('Essential Items Only'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'unpacked',
                child: Row(
                  children: [
                    Icon(
                      Icons.check_box_outline_blank,
                      color: _showOnlyUnpacked
                          ? AppColors.accentColor
                          : AppColors.darkGrey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text('Unpacked Items Only'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$_packedItems / $_totalItems packed',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _totalItems > 0 ? _packedItems / _totalItems : 0,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _packedItems == _totalItems
                          ? AppColors.green
                          : AppColors.accentColor,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Created: ${_formatDate(widget.packingList.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    if (_packedItems == _totalItems && _totalItems > 0)
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'All Packed!',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.green,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Empty state
          if (widget.packingList.items.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.luggage,
                      size: 64,
                      color: AppColors.midGrey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No items in this list',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the edit button to add items',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.midGrey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_categorizedItems.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showOnlyEssentials ? Icons.star : Icons.check_box,
                      size: 64,
                      color: AppColors.midGrey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _showOnlyEssentials
                          ? 'No essential items in this list'
                          : 'All items are packed!',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the filter icon to view all items',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.midGrey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          // Item tabs by category
          else
            Expanded(
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.accentColor,
                    unselectedLabelColor: AppColors.darkGrey,
                    indicatorColor: AppColors.accentColor,
                    tabs: _categorizedItems.keys.map((category) {
                      final items = _categorizedItems[category]!;
                      final packedCount = items.where((i) => i.isPacked).length;
                      return Tab(
                        child: Row(
                          children: [
                            Text(category),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: packedCount == items.length
                                    ? AppColors.green
                                    : AppColors.midGrey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$packedCount/${items.length}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: _categorizedItems.keys.map((category) {
                        final items = _categorizedItems[category]!;
                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _buildItemTile(item);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentColor,
        child: const Icon(Icons.edit, color: Colors.white),
        onPressed: () async {
          // Pass the tripId when navigating to edit screen
          final result = await Navigator.pushNamed(
            context,
            '/edit-packing-list',
            arguments: {
              'packingList': widget.packingList,
              'tripId': widget.packingList.tripId,
            },
          );
          if (result != null) {
            // Handle edited list
            setState(() {
              _updateCounts();
              _categorizeItems();
              _tabController = TabController(
                  length: _categorizedItems.keys.length, vsync: this);
            });
          }
        },
      ),
    );
  }

  Widget _buildItemTile(PackingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: item.isPacked ? AppColors.lightGrey : Colors.transparent,
          ),
        ),
        color: item.isPacked ? AppColors.lightGrey : Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: InkWell(
            onTap: () => _toggleItemPacked(item),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.isPacked ? AppColors.green : AppColors.midGrey,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Icon(
                  item.isPacked ? Icons.check : null,
                  color: AppColors.green,
                  size: 20,
                ),
              ),
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontSize: 16,
              color: item.isPacked ? AppColors.midGrey : AppColors.darkGrey,
              fontWeight:
                  item.isEssential ? FontWeight.bold : FontWeight.normal,
              decoration: item.isPacked ? TextDecoration.lineThrough : null,
            ),
          ),
          trailing: item.isEssential
              ? Tooltip(
                  message: 'Essential Item',
                  child: Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20,
                  ),
                )
              : null,
          onTap: () => _toggleItemPacked(item),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}
