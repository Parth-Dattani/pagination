// Movie Model
class MovieModel {
  final int id;
  final String title;
  final int year;
  final List<String> genre;
  final double rating;
  final String director;
  final List<String> actors;
  final String plot;
  final String poster;
  final String trailer;
  final int runtime;
  final String awards;
  final String country;
  final String language;
  final String boxOffice;
  final String production;
  final String website;

  MovieModel({
    required this.id,
    required this.title,
    required this.year,
    required this.genre,
    required this.rating,
    required this.director,
    required this.actors,
    required this.plot,
    required this.poster,
    required this.trailer,
    required this.runtime,
    required this.awards,
    required this.country,
    required this.language,
    required this.boxOffice,
    required this.production,
    required this.website,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'],
      title: json['title'],
      year: json['year'],
      genre: List<String>.from(json['genre']),
      rating: json['rating'].toDouble(),
      director: json['director'],
      actors: List<String>.from(json['actors']),
      plot: json['plot'],
      poster: json['poster'],
      trailer: json['trailer'],
      runtime: json['runtime'],
      awards: json['awards'],
      country: json['country'],
      language: json['language'],
      boxOffice: json['boxOffice'],
      production: json['production'],
      website: json['website'],
    );
  }
}