import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String category;
  final String thumbnailUrl;
  final bool isPremium;
  final List<Lesson> lessons;
  final String difficulty;
  final String instructorName;
  final String instructorId; // Added to track ownership
  final double rating;
  final int studentCount;
  final List<String> syllabusHighlights;
  final double price;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.thumbnailUrl,
    required this.isPremium,
    required this.lessons,
    required this.difficulty,
    required this.instructorName,
    required this.instructorId,
    this.rating = 4.5,
    this.studentCount = 120,
    required this.syllabusHighlights,
    this.price = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'thumbnailUrl': thumbnailUrl,
      'isPremium': isPremium,
      'difficulty': difficulty,
      'instructorName': instructorName,
      'instructorId': instructorId,
      'rating': rating,
      'studentCount': studentCount,
      'syllabusHighlights': syllabusHighlights,
      'price': price,
      'lessons': lessons.map((l) => l.toMap()).toList(),
    };
  }

  factory Course.fromMap(Map<String, dynamic> map, String id) {
    return Course(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      isPremium: map['isPremium'] ?? false,
      difficulty: map['difficulty'] ?? 'Beginner',
      instructorName: map['instructorName'] ?? '',
      instructorId: map['instructorId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      studentCount: map['studentCount'] ?? 0,
      syllabusHighlights: List<String>.from(map['syllabusHighlights'] ?? []),
      price: (map['price'] ?? 0.0).toDouble(),
      lessons: (map['lessons'] as List? ?? [])
          .map((l) => Lesson.fromMap(l as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final String content;
  final String duration;
  final String? videoUrl;
  final String? audioUrl; // Added for audio support
  final bool isCompleted;
  final String moduleTitle;

  Lesson({
    required this.id,
    required this.title,
    required this.content,
    required this.duration,
    this.videoUrl,
    this.audioUrl,
    this.isCompleted = false,
    required this.moduleTitle,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'duration': duration,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'isCompleted': isCompleted,
      'moduleTitle': moduleTitle,
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      duration: map['duration'] ?? '',
      videoUrl: map['videoUrl'],
      audioUrl: map['audioUrl'],
      isCompleted: map['isCompleted'] ?? false,
      moduleTitle: map['moduleTitle'] ?? '',
    );
  }
}
