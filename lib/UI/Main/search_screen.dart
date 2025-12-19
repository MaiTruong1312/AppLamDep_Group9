import 'dart:async';
import 'package:applamdep/models/nail_model.dart';
import 'package:applamdep/models/store_model.dart';
import 'package:applamdep/widgets/nail_card.dart';
import 'package:applamdep/widgets/store_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final BehaviorSubject<String> _searchSubject = BehaviorSubject<String>();
  Stream<SearchResult>? _resultsStream;
  List<String> _recentSearches = [];
  List<String> _popularSearches = ['gel', 'đính đá', 'french', 'cưới', 'hàn quốc'];
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;
  SearchCategory _selectedCategory = SearchCategory.all;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();

    _searchController.addListener(() {
      _searchSubject.add(_searchController.text);
      _updateSuggestions(_searchController.text);
    });

    _resultsStream = _searchSubject
        .where((query) => query.isNotEmpty)
        .debounceTime(const Duration(milliseconds: 300))
        .switchMap((query) => _performSearch(query));
  }

  void _loadRecentSearches() {
    // Load từ SharedPreferences hoặc local storage
    // _recentSearches = await _getRecentSearches();
  }

  void _saveSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.sublist(0, 5);
      }
    });

    // Save to local storage
    // _saveRecentSearches(_recentSearches);
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final suggestions = <String>[];
    final lowerQuery = query.toLowerCase();

    // Add popular searches that match
    for (var popular in _popularSearches) {
      if (popular.toLowerCase().contains(lowerQuery) && !suggestions.contains(popular)) {
        suggestions.add(popular);
      }
    }

    // Add recent searches that match
    for (var recent in _recentSearches) {
      if (recent.toLowerCase().contains(lowerQuery) && !suggestions.contains(recent)) {
        suggestions.add(recent);
      }
    }

    // Add tag suggestions
    final tagSuggestions = _getTagSuggestions(query);
    suggestions.addAll(tagSuggestions);

    setState(() {
      _searchSuggestions = suggestions.take(8).toList();
      _showSuggestions = suggestions.isNotEmpty;
    });
  }

  List<String> _getTagSuggestions(String query) {
    // Common nail tags based on query
    const tagDictionary = {
      'gel': ['sơn gel', 'gel trong', 'gel màu'],
      'đá': ['đính đá', 'phụ kiện đá', 'đá swarovski'],
      'french': ['french tip', 'viền trắng', 'móng tay french'],
      'cưới': ['cô dâu', 'cưới hỏi', 'trang trí cưới'],
      'hàn': ['hàn quốc', 'style hàn', 'trend hàn'],
      'nhật': ['nhật bản', 'style nhật', 'japanese'],
    };

    final suggestions = <String>[];
    final lowerQuery = query.toLowerCase();

    for (var entry in tagDictionary.entries) {
      if (entry.key.contains(lowerQuery) || lowerQuery.contains(entry.key)) {
        suggestions.addAll(entry.value);
      }
    }

    return suggestions;
  }

  Stream<SearchResult> _performSearch(String query) async* {
    if (query.trim().isEmpty) {
      yield SearchResult.empty();
      return;
    }

    _saveSearch(query);

    yield SearchResult.loading();

    final lowerCaseQuery = query.toLowerCase();
    final searchTerms = lowerCaseQuery.split(' ').where((term) => term.isNotEmpty).toList();

    try {
      // Tìm kiếm đa chiều
      final List<Nail> nails = await _searchNails(searchTerms);
      final List<Store> stores = await _searchStores(searchTerms);

      // Sắp xếp kết quả theo độ liên quan
      nails.sort((a, b) {
        final aScore = _calculateRelevanceScore(a, searchTerms, lowerCaseQuery);
        final bScore = _calculateRelevanceScore(b, searchTerms, lowerCaseQuery);
        return bScore.compareTo(aScore);
      });

      stores.sort((a, b) {
        final aScore = _calculateStoreRelevance(a, searchTerms, lowerCaseQuery);
        final bScore = _calculateStoreRelevance(b, searchTerms, lowerCaseQuery);
        return bScore.compareTo(aScore);
      });

      yield SearchResult(
        nails: nails,
        stores: stores,
        query: query,
      );
    } catch (e) {
      yield SearchResult.error(e.toString());
    }
  }

  Future<List<Nail>> _searchNails(List<String> searchTerms) async {
    final results = <Nail>{};

    for (var term in searchTerms) {
      if (term.isEmpty) continue;

      // Tìm theo tên (case-insensitive)
      final nameQuery = await FirebaseFirestore.instance
          .collection('nails')
          .where('name_lowercase', isGreaterThanOrEqualTo: term)
          .where('name_lowercase', isLessThanOrEqualTo: '$term\uf8ff')
          .limit(20)
          .get();

      // Tìm theo tags
      final tagsQuery = await FirebaseFirestore.instance
          .collection('nails')
          .where('tags', arrayContains: term)
          .limit(20)
          .get();

      // Tìm theo mô tả
      final descriptionQuery = await FirebaseFirestore.instance
          .collection('nails')
          .where('description_lowercase', arrayContains: term)
          .limit(20)
          .get();

      // Tìm theo giá (nếu term là số)
      if (_isNumeric(term)) {
        final price = int.tryParse(term);
        if (price != null) {
          final priceQuery = await FirebaseFirestore.instance
              .collection('nails')
              .where('price', isGreaterThanOrEqualTo: price - 50000)
              .where('price', isLessThanOrEqualTo: price + 50000)
              .limit(10)
              .get();

          for (var doc in priceQuery.docs) {
            results.add(Nail.fromFirestore(doc));
          }
        }
      }

      // Kết hợp kết quả
      for (var doc in [...nameQuery.docs, ...tagsQuery.docs, ...descriptionQuery.docs]) {
        results.add(Nail.fromFirestore(doc));
      }
    }

    return results.toList();
  }

  Future<List<Store>> _searchStores(List<String> searchTerms) async {
    final results = <Store>{};

    for (var term in searchTerms) {
      if (term.isEmpty) continue;

      // Tìm theo tên cửa hàng
      final nameQuery = await FirebaseFirestore.instance
          .collection('stores')
          .where('name_lowercase', isGreaterThanOrEqualTo: term)
          .where('name_lowercase', isLessThanOrEqualTo: '$term\uf8ff')
          .limit(10)
          .get();

      // Tìm theo địa chỉ
      final addressQuery = await FirebaseFirestore.instance
          .collection('stores')
          .where('address_lowercase', arrayContains: term)
          .limit(10)
          .get();

      for (var doc in [...nameQuery.docs, ...addressQuery.docs]) {
        results.add(Store.fromFirestore(doc));
      }
    }

    return results.toList();
  }

  int _calculateRelevanceScore(Nail nail, List<String> searchTerms, String fullQuery) {
    int score = 0;

    // Kiểm tra tên
    final lowerName = nail.name.toLowerCase();
    if (lowerName.contains(fullQuery)) {
      score += 100; // Khớp chính xác toàn bộ query
    } else {
      for (var term in searchTerms) {
        if (lowerName.contains(term)) {
          score += 30;
        }
      }
    }

    // Kiểm tra tags
    for (var tag in nail.tags) {
      final lowerTag = tag.toLowerCase();
      if (lowerTag.contains(fullQuery)) {
        score += 80;
      } else {
        for (var term in searchTerms) {
          if (lowerTag.contains(term)) {
            score += 20;
          }
        }
      }
    }

    // Kiểm tra mô tả
    final lowerDescription = nail.description.toLowerCase();
    if (lowerDescription.contains(fullQuery)) {
      score += 40;
    } else {
      for (var term in searchTerms) {
        if (lowerDescription.contains(term)) {
          score += 10;
        }
      }
    }

    // Ưu tiên Best Choice
    if (nail.isBestChoice) score += 15;

    // Ưu tiên lượt thích cao
    score += (nail.likes ~/ 100);

    return score;
  }

  int _calculateStoreRelevance(Store store, List<String> searchTerms, String fullQuery) {
    int score = 0;

    final lowerName = store.name.toLowerCase();
    final lowerAddress = store.address.toLowerCase();

    if (lowerName.contains(fullQuery)) {
      score += 100;
    } else {
      for (var term in searchTerms) {
        if (lowerName.contains(term)) score += 40;
      }
    }

    if (lowerAddress.contains(fullQuery)) {
      score += 60;
    } else {
      for (var term in searchTerms) {
        if (lowerAddress.contains(term)) score += 20;
      }
    }

    return score;
  }

  bool _isNumeric(String str) {
    return double.tryParse(str) != null;
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _showSuggestions = false;
      _searchSuggestions = [];
    });
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    setState(() {
      _showSuggestions = false;
    });
    _searchSubject.add(suggestion);
  }

  void _removeRecentSearch(String search) {
    setState(() {
      _recentSearches.remove(search);
    });
    // Update local storage
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E2022)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _buildSearchBar(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1E2022),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm mẫu nail, cửa hàng, tags...',
              hintStyle: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              border: InputBorder.none,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF777E90)),
                onPressed: _clearSearch,
              )
                  : const Icon(Icons.search, color: Color(0xFF777E90)),
            ),
            onTap: () {
              if (_searchController.text.isNotEmpty) {
                setState(() {
                  _showSuggestions = true;
                });
              }
            },
            onChanged: (value) {
              setState(() {
                _showSuggestions = value.isNotEmpty && _searchSuggestions.isNotEmpty;
              });
            },
          ),
          if (_showSuggestions && _searchSuggestions.isNotEmpty)
            _buildSuggestionsDropdown(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Gợi ý tìm kiếm',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ..._searchSuggestions.map((suggestion) => ListTile(
            dense: true,
            leading: const Icon(Icons.search, size: 20, color: Colors.grey),
            title: Text(suggestion),
            onTap: () => _selectSuggestion(suggestion),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_searchController.text.isEmpty) {
      return _buildInitialState();
    }

    return Column(
      children: [
        _buildCategoryTabs(),
        Expanded(
          child: StreamBuilder<SearchResult>(
            stream: _resultsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Đã có lỗi xảy ra',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildNoResults();
              }

              final result = snapshot.data!;
              return _buildResults(result);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: SearchCategory.values.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ChoiceChip(
              label: Text(category.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: const Color(0xFF4A6FA5),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            _buildSectionTitle('Tìm kiếm gần đây'),
            _buildRecentSearches(),
            const Divider(height: 32),
          ],
          _buildSectionTitle('Tìm kiếm phổ biến'),
          _buildPopularSearches(),
          const Divider(height: 32),
          _buildSearchTips(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E2022),
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _recentSearches.map((search) {
          return InputChip(
            label: Text(search),
            onPressed: () => _selectSuggestion(search),
            onDeleted: () => _removeRecentSearch(search),
            deleteIcon: const Icon(Icons.close, size: 16),
            backgroundColor: Colors.grey.shade100,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPopularSearches() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _popularSearches.map((search) {
          return ActionChip(
            label: Text(search),
            onPressed: () => _selectSuggestion(search),
            backgroundColor: const Color(0xFFE8F4FD),
            labelStyle: const TextStyle(color: Color(0xFF4A6FA5)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchTips() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mẹo tìm kiếm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E2022),
            ),
          ),
          const SizedBox(height: 12),
          _buildTipItem('🔍', 'Tìm theo tên mẫu nail, cửa hàng'),
          _buildTipItem('🏷️', 'Tìm theo tags: "gel", "đính đá", "french"'),
          _buildTipItem('💰', 'Tìm theo giá: "200k", "dưới 300k"'),
          _buildTipItem('⭐', 'Tìm mẫu nổi bật: "Best Choice", "Trending"'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy kết quả cho "${_searchController.text}"',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Thử các từ khóa khác như:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _popularSearches.take(4).map((keyword) {
              return ActionChip(
                label: Text(keyword),
                onPressed: () => _selectSuggestion(keyword),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(SearchResult result) {
    List<Widget> content = [];

    if (_selectedCategory == SearchCategory.all || _selectedCategory == SearchCategory.nails) {
      if (result.nails.isNotEmpty) {
        content.addAll([
          _buildResultHeader('Mẫu Nail (${result.nails.length})'),
          _buildNailGrid(result.nails),
        ]);
      }
    }

    if (_selectedCategory == SearchCategory.all || _selectedCategory == SearchCategory.stores) {
      if (result.stores.isNotEmpty) {
        content.addAll([
          _buildResultHeader('Cửa Hàng (${result.stores.length})'),
          _buildStoreList(result.stores),
        ]);
      }
    }

    return content.isEmpty
        ? _buildNoResults()
        : ListView(
      children: [
        const SizedBox(height: 8),
        ...content,
      ],
    );
  }

  Widget _buildResultHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E2022),
        ),
      ),
    );
  }

  Widget _buildNailGrid(List<Nail> nails) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.7,
      ),
      itemCount: nails.length,
      itemBuilder: (context, index) => NailCard(nail: nails[index]),
    );
  }

  Widget _buildStoreList(List<Store> stores) {
    return ListView.separated(
      padding: const EdgeInsets.all(8.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stores.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final store = stores[index];
        return StoreCard(
          storeId: store.id,
          storeData: {
            'name': store.name,
            'address': store.address,
            'img_url': store.imgUrl,
            // Add additional data if available
            'rating': store.rating,
            'review_count': store.reviewCount,
            'distance': store.distance,
          },
          isSearchResult: true,
          onBookmarkChanged: () {
            // Optional: refresh search results if needed
            // _refreshSearch();
          },
        );
      },
    );
  }
}

enum SearchCategory {
  all('Tất cả'),
  nails('Mẫu Nail'),
  stores('Cửa Hàng');

  final String displayName;
  const SearchCategory(this.displayName);
}

class SearchResult {
  final List<Nail> nails;
  final List<Store> stores;
  final String? query;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  SearchResult({
    this.nails = const [],
    this.stores = const [],
    this.query,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
  });

  factory SearchResult.loading() {
    return SearchResult(isLoading: true);
  }

  factory SearchResult.error(String message) {
    return SearchResult(hasError: true, errorMessage: message);
  }

  factory SearchResult.empty() {
    return SearchResult();
  }

  bool get isEmpty => nails.isEmpty && stores.isEmpty && !isLoading && !hasError;
}