import 'package:flutter/material.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:linkedfarm/Services/learning_service.dart';
import 'package:linkedfarm/Models/course_model.dart';
import 'package:linkedfarm/Farmers%20View/learning/course_detail_screen.dart';

class LearningCenterTab extends StatelessWidget {
  const LearningCenterTab({super.key});

  @override
  Widget build(BuildContext context) {
    final learningService = LearningService();
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Course>>(
      stream: learningService.streamAllCourses(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final allCourses = snapshot.data!;
        final freeCourses = allCourses.where((c) => !c.isPremium).toList();
        final premiumCourses = allCourses.where((c) => c.isPremium).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(l10n),
              const SizedBox(height: 24),
              _buildSectionTitle(l10n.freeCourses, "Knowledge for all"),
              const SizedBox(height: 16),
              SizedBox(
                height: 240,
                child: freeCourses.isEmpty 
                  ? Center(child: Text("No free courses available", style: TextStyle(color: Colors.grey[400])))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: freeCourses.length,
                      itemBuilder: (context, index) => _buildCourseCard(context, freeCourses[index]),
                    ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(l10n.premiumLearning, "Advanced Mastery"),
              const SizedBox(height: 16),
              premiumCourses.isEmpty
                ? Center(child: Text("No premium courses available", style: TextStyle(color: Colors.grey[400])))
                : Column(
                    children: premiumCourses.map((c) => _buildPremiumCard(context, c)).toList(),
                  ),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green[800],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("LEARN & GROW", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text(l10n.learnHeroTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.1)),
                const SizedBox(height: 8),
                Text(l10n.learnHeroSub, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.auto_stories_rounded, size: 70, color: Colors.white.withOpacity(0.2)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailScreen(course: course))),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: course.thumbnailUrl.startsWith('http') 
                  ? Image.network(course.thumbnailUrl, height: 110, width: double.infinity, fit: BoxFit.cover)
                  : Image.asset(course.thumbnailUrl, height: 110, width: double.infinity, fit: BoxFit.cover, 
                      errorBuilder: (_, __, ___) => Image.asset('assets/advice.jpg', height: 110, width: double.infinity, fit: BoxFit.cover)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.category, style: TextStyle(color: Colors.green[700], fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(course.rating.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text("${course.studentCount} students", style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context, Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: course.thumbnailUrl.startsWith('http')
              ? Image.network(course.thumbnailUrl, width: 80, height: 80, fit: BoxFit.cover)
              : Image.asset(course.thumbnailUrl, width: 80, height: 80, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset('assets/advice.jpg', width: 80, height: 80, fit: BoxFit.cover)),
        ),
        title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("${course.lessons.length} Modules • ${course.difficulty}", style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(course.instructorName, style: TextStyle(fontSize: 11, color: Colors.blue[700])),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.workspace_premium, color: Colors.amber),
            Text(course.price > 0 ? "\$${course.price}" : "FREE", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailScreen(course: course))),
      ),
    );
  }
}
