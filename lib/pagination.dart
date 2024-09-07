import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

import 'model/movie_model.dart';


// Main Page Widget
class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  double? _deviceHeight;
  double? _deviceWidth;
  String? _selectedMoviePosterURL;
  String _searchCategory = 'Popular';
  String _searchText = '';
  final TextEditingController _searchTextFieldController = TextEditingController();
  List<MovieModel> _filteredMovies = [];
  List<MovieModel> _movies = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  final int _limit = 5; // Number of items to fetch per page
  final ScrollController _scrollController = ScrollController(); // Initialize ScrollController
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchMovies(); // Initial fetch when app opens

    // Infinite Scroll Listener
    _scrollController.addListener(() {
      if (_isLoading) return;
      final scrollOffset = _scrollController.offset;
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      if (scrollOffset >= maxScrollExtent) {
        _fetchMovies(); // Fetch more movies when scrolled to the bottom
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose ScrollController
    super.dispose();
  }

  // Fetch movies from API
  Future<void> _fetchMovies() async {
    if (_isLoading || !_hasMore) return; // Prevent multiple calls if already loading or no more data

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('https://freetestapi.com/api/v1/movies?page=$_page&limit=$_limit'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<MovieModel> fetchedMovies = data.map((movieJson) => MovieModel.fromJson(movieJson)).toList();

        setState(() {
          _isLoading = false;
          _hasMore = fetchedMovies.length == _limit; // Check if more movies are available
          _movies.addAll(fetchedMovies);
          _filteredMovies = _filterMovies(); // Initially filter movies after fetch
          _page++;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        throw Exception('Failed to load movies');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching movies: $e');
    }
  }

  // Filter movies based on search category and text
  List<MovieModel> _filterMovies() {
    List<MovieModel> filteredMovies = _movies;

    if (_searchText.isNotEmpty) {
      filteredMovies = filteredMovies.where((movie) {
        return movie.title.toLowerCase().contains(_searchText.toLowerCase());
      }).toList();
    }

    switch (_searchCategory) {
      case 'By Year':
        filteredMovies.sort((a, b) => _isAscending ? a.year.compareTo(b.year) : b.year.compareTo(a.year)); // Sort by year
        break;
      case 'By Language':
        filteredMovies.sort((a, b) => _isAscending ? a.language.compareTo(b.language) : b.language.compareTo(a.language)); // Sort by language
        break;
      case 'By Rating':
        filteredMovies.sort((a, b) => _isAscending ? a.rating.compareTo(b.rating) : b.rating.compareTo(a.rating)); // Sort by rating
        break;
      case 'None':
        break;
      default:
        break;
    }

    return filteredMovies;
  }

  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery.of(context).size.height;
    _deviceWidth = MediaQuery.of(context).size.width;

    _searchTextFieldController.text = _searchText;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Container(
        height: _deviceHeight,
        width: _deviceWidth,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _backgroundWidget(),
            _foregroundWidgets(),
          ],
        ),
      ),
    );
  }

  // Background widget displaying the movie poster
  Widget _backgroundWidget() {
    if (_selectedMoviePosterURL != null) {
      return Container(
        height: _deviceHeight,
        width: _deviceWidth,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(_selectedMoviePosterURL!),
            fit: BoxFit.cover,
            invertColors: true,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
        ),
      );
    } else {
      return Container(
        height: _deviceHeight,
        width: _deviceWidth,
        color: Colors.black,
      );
    }
  }

  // Foreground widget for the search, dropdown, and movie list
  Widget _foregroundWidgets() {
    return Container(
      padding: EdgeInsets.fromLTRB(0, _deviceHeight! * 0.02, 0, 0),
      width: _deviceWidth! * 0.90,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _topBarWidget(),
          Container(
            height: _deviceHeight! * 0.83,
            padding: EdgeInsets.symmetric(vertical: _deviceHeight! * 0.01),
            child: _moviesListViewWidget(),
          ),
        ],
      ),
    );
  }

  // Top bar containing search, category dropdown, and sorting buttons
  Widget _topBarWidget() {
    return Container(
      height: _deviceHeight! * 0.08,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _searchFieldWidget(),
          _categorySelectionWidget(),
          _sortingButtonWidget(),
        ],
      ),
    );
  }

  // Search field widget
  Widget _searchFieldWidget() {
    return Container(
      width: _deviceWidth! * 0.50,
      height: _deviceHeight! * 0.05,
      child: TextField(
        controller: _searchTextFieldController,
        onChanged: (input) {
          setState(() {
            _searchText = input; // Update search text
            _filteredMovies = _filterMovies(); // Filter movies
          });
        },
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.white24),
          hintStyle: TextStyle(color: Colors.white54),
          hintText: 'Search...',
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Movie list view widget
  Widget _moviesListViewWidget() {
    if (_isLoading && _filteredMovies.isEmpty) {
      return ListView.builder(
        controller: _scrollController,
        itemCount: 5, // Number of shimmer placeholders
        itemBuilder: (context, index) {
          return _shimmerMovieTile();
        },
      );
    }

    if (_filteredMovies.isEmpty) {
      return Center(
        child: Text(
          'No movies found',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredMovies.length + 1, // Add extra item for the loading indicator
      itemBuilder: (context, index) {
        if (index < _filteredMovies.length) {
          return _movieTile(_filteredMovies[index]);
        } else if (_isLoading) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else {
          return SizedBox.shrink(); // Empty widget if no more movies
        }
      },
    );
  }

  // Shimmer effect for movie tile
  Widget _shimmerMovieTile() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            Container(
              width: 100.0,
              height: 150.0,
              color: Colors.white,
            ),
            SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20.0,
                    color: Colors.white,
                  ),
                  SizedBox(height: 5.0),
                  Container(
                    height: 15.0,
                    color: Colors.white,
                  ),
                  SizedBox(height: 5.0),
                  Container(
                    height: 15.0,
                    color: Colors.white,
                  ),
                  SizedBox(height: 5.0),
                  Container(
                    height: 15.0,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Movie tile widget for each movie
  Widget _movieTile(MovieModel movie) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMoviePosterURL = movie.poster; // Set selected movie poster
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            Image.network(movie.poster, height: 150.0, width: 100.0, fit: BoxFit.cover),
            SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: TextStyle(color: Colors.white, fontSize: 18.0),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5.0),
                  Text(
                    '${movie.year} | ${movie.genre.join(', ')}',
                    style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5.0),
                  Text(
                    'Director: ${movie.director}',
                    style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5.0),
                  Text(
                    'Rating: ${movie.rating}',
                    style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Category selection dropdown
  Widget _categorySelectionWidget() {
    return DropdownButton<String>(
      value: _searchCategory,
      dropdownColor: Colors.black54,
      icon: Icon(Icons.arrow_drop_down, color: Colors.white),
      items: ['Popular', 'By Year', 'By Language', 'By Rating'].map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category, style: TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: (String? newCategory) {
        setState(() {
          _searchCategory = newCategory!;
          _filteredMovies = _filterMovies(); // Filter movies by category
        });
      },
    );
  }

  // Sorting button widget
  Widget _sortingButtonWidget() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isAscending = !_isAscending; // Toggle sorting order
          _filteredMovies = _filterMovies(); // Filter movies based on new sorting order
        });
      },
      child: Icon(
        _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
        color: Colors.white,
      ),
    );
  }
}
