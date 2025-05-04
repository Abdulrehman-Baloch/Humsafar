import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/packing_list.dart';
import 'create_packing_list_screen.dart';
import 'packing_list_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class AppColors {
  static const Color primaryColor = Colors.black;
  static const Color accentColor = Color(0xFFBA0E02);
  static const Color backgroundColor = Colors.white;
  static const Color lightGrey = Color(0xFFE9E7E7);
  static const Color midGrey = Color(0xFF9E9E9E);
  static const Color darkGrey = Color(0xFF424242);
}

class MyListsScreen extends StatefulWidget {
  final String? tripId;
  final String? tripName;

  const MyListsScreen({Key? key, this.tripId, this.tripName}) : super(key: key);

  @override
  State<MyListsScreen> createState() => _MyListsScreenState();
}

class _MyListsScreenState extends State<MyListsScreen> {
  List<PackingList> packingLists = [];
  List<PackingList> filteredLists = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  bool _useSimpleQuery = false;

  @override
  void initState() {
    super.initState();
    _loadPackingLists();
  }

  Future<void> _loadPackingLists() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.tripId != null) {
        Query query = FirebaseFirestore.instance
            .collection('tripPlans')
            .doc(widget.tripId)
            .collection('packingLists');

        if (_useSimpleQuery) {
          final querySnapshot = await query.get();
          final lists = _processQueryResults(querySnapshot, widget.tripId!);
          setState(() {
            packingLists = lists;
            filteredLists = _applyCurrentFilters(lists);
            _isLoading = false;
          });
        } else {
          try {
            final querySnapshot =
                await query.orderBy('createdAt', descending: true).get();
            final lists = _processQueryResults(querySnapshot, widget.tripId!);
            setState(() {
              packingLists = lists;
              filteredLists = _applyCurrentFilters(lists);
              _isLoading = false;
            });
          } catch (e) {
            if (e.toString().contains('failed-precondition') ||
                e.toString().contains('requires an index')) {
              setState(() {
                _useSimpleQuery = true;
              });
              final querySnapshot = await query.get();
              final lists = _processQueryResults(querySnapshot, widget.tripId!);
              setState(() {
                packingLists = lists;
                filteredLists = _applyCurrentFilters(lists);
                _isLoading = false;
              });
            } else {
              throw e;
            }
          }
        }
      } else {
        final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
        if (currentUserEmail == null) {
          setState(() {
            packingLists = [];
            filteredLists = [];
            _isLoading = false;
            _errorMessage = 'Please log in to view your packing lists.';
          });
          return;
        }

        final tripsSnapshot = await FirebaseFirestore.instance
            .collection('tripPlans')
            .where('userEmail', isEqualTo: currentUserEmail)
            .get();

        if (tripsSnapshot.docs.isEmpty) {
          setState(() {
            packingLists = [];
            filteredLists = [];
            _isLoading = false;
          });
          return;
        }

        List<PackingList> allLists = [];

        final futures = <Future>[];
        for (var tripDoc in tripsSnapshot.docs) {
          final tripId = tripDoc.id;

          Query query = FirebaseFirestore.instance
              .collection('tripPlans')
              .doc(tripId)
              .collection('packingLists');

          if (_useSimpleQuery) {
            futures.add(query.get().then((querySnapshot) {
              allLists.addAll(_processQueryResults(querySnapshot, tripId));
            }));
          } else {
            try {
              futures.add(query
                  .orderBy('createdAt', descending: true)
                  .get()
                  .then((querySnapshot) {
                allLists.addAll(_processQueryResults(querySnapshot, tripId));
              }));
            } catch (e) {
              if (e.toString().contains('failed-precondition') ||
                  e.toString().contains('requires an index')) {
                setState(() {
                  _useSimpleQuery = true;
                });
                futures.add(query.get().then((querySnapshot) {
                  allLists.addAll(_processQueryResults(querySnapshot, tripId));
                }));
              } else {
                throw e;
              }
            }
          }
        }

        await Future.wait(futures);

        if (_useSimpleQuery) {
          allLists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        setState(() {
          packingLists = allLists;
          filteredLists = _applyCurrentFilters(allLists);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load packing lists: $e';
      });
    }
  }

  void _navigateToCreateScreen({PackingList? existingList}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePackingListScreen(
          tripId: existingList?.tripId ?? widget.tripId!,
          existingList: existingList,
          tripName: widget.tripName,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _loadPackingLists();
      }
    });
  }

  Future<void> _deleteList(String listId, int index) async {
    try {
      await FirebaseFirestore.instance
          .collection('tripPlans')
          .doc(widget.tripId)
          .collection('packingLists')
          .doc(listId)
          .delete();

      setState(() {
        packingLists.removeAt(index);
        filteredLists = _applyCurrentFilters(packingLists);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Packing list deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting packing list: $e')),
      );
    }
  }

  Widget _buildListCard(PackingList packingList, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          packingList.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: packingList.isCompleted
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: packingList.isCompleted
                      ? Colors.green.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Text(
                packingList.isCompleted ? 'Completed' : 'Incomplete',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: packingList.isCompleted ? Colors.green : Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Created ${_formatDate(packingList.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.midGrey,
              ),
            ),
            if (packingList.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: packingList.items
                    .take(3)
                    .map((item) => Chip(
                          label: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.darkGrey,
                            ),
                          ),
                          backgroundColor: AppColors.lightGrey,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.black),
              tooltip: 'Share list',
              onPressed: () {
                if (packingList.items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('This list is empty - add items before sharing'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  _sharePackingList(packingList);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () {
                _navigateToCreateScreen(existingList: packingList);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _confirmDelete(packingList.id, index);
              },
            ),
          ],
        ),
        onTap: () {
          _viewListDetails(packingList);
        },
      ),
    );
  }

  void _sharePackingList(PackingList packingList) {
    // Format the packing list as a string
    StringBuffer shareText = StringBuffer();
    shareText.writeln('Packing List: ${packingList.name}');
    shareText.writeln(
        'Status: ${packingList.isCompleted ? 'Completed' : 'Incomplete'}');
    shareText.writeln('Items:');

    if (packingList.items.isEmpty) {
      shareText.writeln('  - No items in this list');
    } else {
      for (var item in packingList.items) {
        shareText.writeln('  - ${item.name} (${item.category})');
        shareText.writeln('    Packed: ${item.isPacked ? 'Yes' : 'No'}');
        if (item.isEssential) {
          shareText.writeln('    Essential: Yes');
        }
        if (item.quantity > 1) {
          shareText.writeln('    Quantity: ${item.quantity}');
        }
      }
    }

    // Share the formatted text
    Share.share(
      shareText.toString(),
      subject: 'Packing List: ${packingList.name}',
    );
  }

  /*@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.tripName != null ? '${widget.tripName} Lists' : 'My Lists',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: widget.tripId != null
            ? [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    _sharePackingList();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.sort, color: Colors.white),
                  onPressed: _showSortOptions,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search lists...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  filteredLists = _applyCurrentFilters(packingLists);
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : filteredLists.isEmpty
                        ? _buildEmptyState()
                        : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentColor,
        onPressed: () {
          if (widget.tripId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a trip to add a packing list.'),
              ),
            );
            return;
          }
          _navigateToCreateScreen();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      //leftNavigationBar: const nv.NavigationBar(),
    );
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.tripName != null ? '${widget.tripName} Lists' : 'My Lists',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: widget.tripId != null
            ? [
                if (packingLists.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    tooltip: 'Share first list',
                    onPressed: () {
                      _sharePackingList(packingLists.first);
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.sort, color: Colors.white),
                  onPressed: _showSortOptions,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search lists...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  filteredLists = _applyCurrentFilters(packingLists);
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : filteredLists.isEmpty
                        ? _buildEmptyState()
                        : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentColor,
        onPressed: () {
          if (widget.tripId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a trip to add a packing list.'),
              ),
            );
            return;
          }
          _navigateToCreateScreen();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _loadPackingLists,
      child: filteredLists.isEmpty
          ? const Center(child: Text('No lists found'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredLists.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final packingList = filteredLists[index];
                return _buildListCard(packingList, index);
              },
            ),
    );
  }

  List<PackingList> _processQueryResults(
      QuerySnapshot snapshot, String tripId) {
    final lists = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      List<PackingItem> items = [];
      if (data['items'] != null) {
        items = (data['items'] as List).map((item) {
          return PackingItem(
            name: item['name'] ?? '',
            category: item['category'] ?? '',
            isPacked: item['isPacked'] ?? false,
            isEssential: item['isEssential'] ?? false,
            quantity: item['quantity'] ?? 1,
          );
        }).toList();
      }

      DateTime createdAt;
      try {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } catch (e) {
        createdAt = DateTime.now();
      }

      return PackingList(
        id: doc.id,
        name: data['name'] ?? 'Untitled List',
        items: items,
        createdAt: createdAt,
        tripId: tripId,
      );
    }).toList();

    return lists;
  }

  List<PackingList> _applyCurrentFilters(List<PackingList> lists) {
    if (_searchQuery.isEmpty) {
      return lists;
    }

    return lists
        .where((list) =>
            list.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            list.items.any((item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList();
  }

  Widget _buildErrorState() {
    bool isIndexError = _errorMessage != null &&
        (_errorMessage!.contains('index') ||
            _errorMessage!.contains('failed-precondition'));

    String? indexUrl;
    if (isIndexError && _errorMessage != null) {
      final RegExp urlRegExp = RegExp(r'https://[^\s]+');
      final match = urlRegExp.firstMatch(_errorMessage!);
      if (match != null) {
        indexUrl = match.group(0);
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: AppColors.midGrey,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              isIndexError
                  ? 'This query requires a Firebase index to be created.'
                  : _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.midGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (isIndexError && indexUrl != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                // To open the URL, add url_launcher and use:
                // launchUrl(Uri.parse(indexUrl));
              },
              child: Text(
                'Click here to create the index',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (isIndexError)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _useSimpleQuery = true;
                });
                _loadPackingLists();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Use Simple Query'),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPackingLists,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list_alt,
            size: 72,
            color: AppColors.midGrey,
          ),
          const SizedBox(height: 24),
          Text(
            'No Lists Available',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.tripName != null
                ? 'There are no packing lists for ${widget.tripName} yet'
                : 'You haven\'t created any packing lists yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.midGrey,
            ),
          ),
        ],
      ),
    );
  }

  /*Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _loadPackingLists,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: filteredLists.length,
        itemBuilder: (context, index) {
          final packingList = filteredLists[index];
          return _buildListCard(packingList, index);
        },
      ),
    );
  }*/

  void _viewListDetails(PackingList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PackingListDetailScreen(
          packingList: list,
        ),
      ),
    ).then((_) => _loadPackingLists());
  }

  void _confirmDelete(String listId, int index) {
    final packingList = filteredLists[index];
    if (packingList.tripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Trip ID not found for this list'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text(
          'Delete "${packingList.name}"?',
          style: TextStyle(color: AppColors.darkGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: AppColors.darkGrey)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('tripPlans')
                    .doc(packingList.tripId)
                    .collection('packingLists')
                    .doc(listId)
                    .delete();

                Navigator.pop(context);
                _loadPackingLists();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('List deleted'),
                    duration: Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting list: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sort Lists By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Recent First'),
                onTap: () {
                  setState(() {
                    packingLists
                        .sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    filteredLists = _applyCurrentFilters(packingLists);
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('Alphabetical'),
                onTap: () {
                  setState(() {
                    packingLists.sort((a, b) => a.name.compareTo(b.name));
                    filteredLists = _applyCurrentFilters(packingLists);
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.format_list_numbered),
                title: const Text('Item Count'),
                onTap: () {
                  setState(() {
                    packingLists.sort(
                        (a, b) => b.items.length.compareTo(a.items.length));
                    filteredLists = _applyCurrentFilters(packingLists);
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Completion Status'),
                onTap: () {
                  setState(() {
                    packingLists.sort((a, b) => (b.isCompleted ? 1 : 0)
                        .compareTo(a.isCompleted ? 1 : 0));
                    filteredLists = _applyCurrentFilters(packingLists);
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }
}

class PackingListSearchDelegate extends SearchDelegate<String> {
  final List<PackingList> packingLists;
  final ValueChanged<String> onQueryChanged;

  PackingListSearchDelegate({
    required this.packingLists,
    required this.onQueryChanged,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onQueryChanged(query);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    onQueryChanged(query);
    return Container();
  }
}
