import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:linkedfarm/Models/course_model.dart';
import 'package:linkedfarm/Services/learning_service.dart';
import 'package:linkedfarm/Advisor%20View/course_editor_page.dart'; // Will create next

class ManageCoursesScreen extends StatelessWidget {
  const ManageCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final LearningService _learningService = LearningService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text("Manage My Courses", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Course>>(
        stream: _learningService.streamCoursesByAdvisor(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data ?? [];

          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_rounded, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text("No courses created yet.", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseEditorPage())),
                    icon: const Icon(Icons.add),
                    label: const Text("Create First Course"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], foregroundColor: Colors.white),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Statistics Header
              _buildStatsHeader(courses),

              // Course List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return _buildCourseCard(context, course);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseEditorPage())),
        backgroundColor: Colors.teal[700],
        child: const Icon(Icons.add_task_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsHeader(List<Course> courses) {
    int totalLessons = 0;
    int totalStudents = 0;
    for (var c in courses) {
      totalLessons += c.lessons.length;
      totalStudents += c.studentCount;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.teal[800],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHeaderStat("Courses", courses.length.toString(), Icons.menu_book_rounded),
          _buildHeaderStat("Lessons", totalLessons.toString(), Icons.play_lesson_rounded),
          _buildHeaderStat("Students", totalStudents.toString(), Icons.group_rounded),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          // Future: Navigate to Lesson Manager for this course
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: (course.thumbnailUrl.startsWith('http'))
                    ? Image.network(course.thumbnailUrl, width: 80, height: 80, fit: BoxFit.cover)
                    : Image.asset('assets/advice.jpg', width: 80, height: 80, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${course.category} • ${course.lessons.length} Lessons",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: course.isPremium ? Colors.amber[100] : Colors.green[100],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        course.isPremium ? "PREMIUM" : "FREE",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: course.isPremium ? Colors.amber[900] : Colors.green[900]),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                   IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, course.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String courseId) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Course"),
        content: const Text("Are you sure? This will permanently remove the course and all its lessons."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await LearningService().deleteCourse(courseId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
