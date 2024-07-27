import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:random_photo_galary/constants.dart';
import 'package:random_photo_galary/pages/Detail_Page.dart';

// Define the SearchResult model
class SearchResult {
  final String imageUrl;

  SearchResult(this.imageUrl);
}

// Home Page
class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _results = [];
  int _page = 1;
  int _perPage = 20; // Number of items to fetch per page
  bool _isLoading = false;
  bool _hasMore = true;

  ScrollController _scrollController = ScrollController();

  // Function to fetch search results from Unsplash API
  Future<void> _performSearch(String query, {int page = 1}) async {
    if (query.isEmpty) {
      setState(() {
        _results.clear();
      });
      return;
    }

    final String apiUrl =
        '$baseurl/search/photos?client_id=$unsplashAccessKey&page=$page&per_page=$_perPage&query=$query&orientation=portrait';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        setState(() {
          if (page == 1) {
            _results = (jsonData['results'] as List)
                .map((result) => SearchResult(
                      result['urls']['regular'],
                    ))
                .toList();
          } else {
            _results.addAll((jsonData['results'] as List)
                .map((result) => SearchResult(
                      result['urls']['regular'],
                    ))
                .toList());
          }

          // Check if there are more pages to load
          _hasMore = jsonData['total_pages'] > page;
        });
      } else {
        print('Error fetching data: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during API call: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _performSearch(_searchController.text, page: 1);
    });

    // Add listener for scroll controller
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _performSearch(_searchController.text, page: _page + 1);
      setState(() {
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading more: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Container(
          width: double.infinity,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2), // changes position of shadow
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch(''); // Clear search results
                      },
                    )
                  : null,
              hintText: 'Search...',
              border: InputBorder.none,
            ),
          ),
        ),
      ),
      body: _results.isEmpty
           ? Container() // Show nothing if results are empty
           : NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollEndNotification &&
              _scrollController.position.extentAfter == 0 &&
              !_isLoading &&
              _hasMore) {
            // Call your load more logic here
            // Example:
            // _loadMore();
            print('Loading more data...');
          }
          return false;
        },
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: _results.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _results.length) {
                    final result = _results[index];
                    return GestureDetector(
                      onTap: () {
                           navigateToNextPage(result, context); // Example function to navigate to next page
                               },
                      child: GridTile(
                        child: Image.network(
                          result.imageUrl,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  } else {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildLoadMoreIndicator(),
                      ],
                    );
                  }
                },
              ),
            ),
       floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Icon(Icons.arrow_back_rounded),
      ),
           ); 
    
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

void navigateToNextPage(SearchResult result, BuildContext context){
  // Example of navigating to a new page with MaterialPageRoute
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DetailPage(result: result),
    ),
  );
}
