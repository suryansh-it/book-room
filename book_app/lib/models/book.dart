// Model to map book data from the API
class Book {
  final int id; // Unique identifier for the book
  final String title; // Title of the book
  final String author; // Author of the book
  final String description; // Short description or synopsis of the book

  // Constructor to initialize Book object
  Book(
      {required this.id,
      required this.title,
      required this.author,
      required this.description});

  // Factory method to create a Book object from a JSON response
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'], // Map 'id' from JSON to id
      title: json['title'], // Map 'title' from JSON to title
      author: json['author'], // Map 'author' from JSON to author
      description:
          json['description'], // Map 'description' from JSON to description
    );
  }
}
