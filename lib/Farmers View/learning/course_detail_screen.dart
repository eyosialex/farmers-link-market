import 'package:flutter/material.dart';
import 'package:linkedfarm/Models/course_model.dart';
import 'package:linkedfarm/Farmers%20View/learning/lesson_player_screen.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildCourseMeta(),
                   const SizedBox(height: 24),
                   _buildInstructorSection(),
                   const SizedBox(height: 32),
                   _buildSyllabusSection(context),
                   const SizedBox(height: 100), // Spacer for fab
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startCourse(context),
        label: const Text("Start Learning", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.play_circle_fill),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.green[800],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(course.thumbnailUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            Center(
              child: Icon(Icons.play_circle_outline, color: Colors.white.withOpacity(0.8), size: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseMeta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(4)),
              child: Text(course.category, style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const Spacer(),
            Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(course.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Text(course.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2)),
        const SizedBox(height: 12),
        Text(course.description, style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.people, "${course.studentCount}", "Students"),
            _buildStatItem(Icons.schedule, "4.5 Hours", "Duration"),
            _buildStatItem(Icons.bar_chart, course.difficulty, "Level"),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[400], size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildInstructorSection() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.green[100],
          child: const Icon(Icons.person, color: Colors.green),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Instructor", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(course.instructorName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildSyllabusSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Course Curriculum", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        // Group lessons by module
        ...course.lessons.map((lesson) => _buildLessonTile(context, lesson)).toList(),
      ],
    );
  }

  Widget _buildLessonTile(BuildContext context, Lesson lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: Colors.green[50],
          child: Text(lesson.id.split('-').last, style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(lesson.duration, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
        onTap: () {
           Navigator.push(context, MaterialPageRoute(builder: (context) => LessonPlayerScreen(course: course, initialLesson: lesson)));
        },
      ),
    );
  }

  void _startCourse(BuildContext context) {
    if (course.lessons.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => LessonPlayerScreen(course: course, initialLesson: course.lessons.first)));
    }
  }
}
