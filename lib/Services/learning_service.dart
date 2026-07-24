import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/Models/course_model.dart';

class LearningService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'courses';

  // GET ALL COURSES (LIVE FROM FIRESTORE)
  Stream<List<Course>> streamAllCourses() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Course.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // GET SPECIFIC ADVISOR'S COURSES
  Stream<List<Course>> streamCoursesByAdvisor(String advisorId) {
    return _firestore
        .collection(_collection)
        .where('instructorId', isEqualTo: advisorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Course.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<List<Course>> getFreeCourses() async {
    final snapshot = await _firestore.collection(_collection).where('isPremium', isEqualTo: false).get();
    return snapshot.docs.map((doc) => Course.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<Course>> getPremiumCourses() async {
    final snapshot = await _firestore.collection(_collection).where('isPremium', isEqualTo: true).get();
    return snapshot.docs.map((doc) => Course.fromMap(doc.data(), doc.id)).toList();
  }

  // CREATE A NEW COURSE
  Future<String> createCourse(Course course) async {
    DocumentReference docRef = await _firestore.collection(_collection).add(course.toMap());
    return docRef.id;
  }

  // ADD LESSON TO EXISTING COURSE
  Future<void> addLessonToCourse(String courseId, Lesson lesson) async {
    await _firestore.collection(_collection).doc(courseId).update({
      'lessons': FieldValue.arrayUnion([lesson.toMap()])
    });
  }

  // DELETE COURSE
  Future<void> deleteCourse(String courseId) async {
    await _firestore.collection(_collection).doc(courseId).delete();
  }

  // INITIAL SEED DATA (Static list for reference or initial migration)
  static final List<Course> staticCourses = [
    // ... kept for fallback if needed, or implement a seed method
  ];
}
