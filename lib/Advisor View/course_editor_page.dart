import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:linkedfarm/Models/course_model.dart';
import 'package:linkedfarm/Services/learning_service.dart';
import 'package:linkedfarm/Farmers%20View/Cloudnary_Store.dart';
import 'package:file_picker/file_picker.dart';
import 'package:linkedfarm/Services/io_compatibility.dart' if (dart.library.html) 'package:linkedfarm/Services/web_compatibility.dart';
import 'package:linkedfarm/Advisor%20View/lesson_editor_page.dart'; // Will create next
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseEditorPage extends StatefulWidget {
  final Course? course; // If null, we are creating a new course
  const CourseEditorPage({super.key, this.course});

  @override
  State<CourseEditorPage> createState() => _CourseEditorPageState();
}

class _CourseEditorPageState extends State<CourseEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final LearningService _learningService = LearningService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  String _selectedCategory = 'Crop Science';
  String _selectedDifficulty = 'Beginner';
  bool _isPremium = false;
  String? _thumbnailUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  final List<String> _categories = ['Crop Science', 'Animal Health', 'Business', 'Technology', 'Sustainability'];
  final List<String> _difficulties = ['Beginner', 'Intermediate', 'Expert'];

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      _titleController.text = widget.course!.title;
      _descriptionController.text = widget.course!.description;
      _selectedCategory = widget.course!.category;
      _selectedDifficulty = widget.course!.difficulty;
      _isPremium = widget.course!.isPremium;
      _thumbnailUrl = widget.course!.thumbnailUrl;
    }
  }

  Future<void> _pickThumbnail() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() => _isUploading = true);
      try {
        final file = File(result.files.single.path!);
        final url = await _cloudinaryService.uploadImage(file, folder: 'course_thumbnails');
        if (url != null) {
          setState(() => _thumbnailUrl = url);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    if (_thumbnailUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload a thumbnail")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final newCourse = Course(
        id: widget.course?.id ?? "",
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        thumbnailUrl: _thumbnailUrl!,
        isPremium: _isPremium,
        difficulty: _selectedDifficulty,
        instructorName: user?.displayName ?? user?.email?.split('@')[0] ?? "Expert",
        instructorId: user?.uid ?? "",
        syllabusHighlights: [], // To be added later or derived
        lessons: widget.course?.lessons ?? [],
      );

      String docId;
      if (widget.course == null) {
        docId = await _learningService.createCourse(newCourse);
      } else {
        // Update logic (can implement updateCourse if needed)
        await FirebaseFirestore.instance.collection('courses').doc(widget.course!.id).update(newCourse.toMap());
        docId = widget.course!.id;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LessonEditorPage(courseId: docId, courseTitle: newCourse.title)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course == null ? "Create New Course" : "Edit Course Metadata"),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Picker
              Center(
                child: GestureDetector(
                  onTap: _isUploading ? null : _pickThumbnail,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                      image: _thumbnailUrl != null
                          ? DecorationImage(image: NetworkImage(_thumbnailUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : _thumbnailUrl == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text("Upload Course Thumbnail", style: TextStyle(color: Colors.grey)),
                                ],
                              )
                            : Container(
                                alignment: Alignment.bottomRight,
                                padding: const EdgeInsets.all(8),
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.edit, color: Colors.white),
                                ),
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Course Title", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Title required" : null,
              ),
              const SizedBox(height: 16),

              // Category & Difficulty Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDifficulty,
                      decoration: const InputDecoration(labelText: "Difficulty", border: OutlineInputBorder()),
                      items: _difficulties.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (v) => setState(() => _selectedDifficulty = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Detailed Description", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Description required" : null,
              ),
              const SizedBox(height: 16),

              // Premium Switch
              SwitchListTile(
                title: const Text("Premium Course"),
                subtitle: const Text("Require subscription to access"),
                value: _isPremium,
                onChanged: (v) => setState(() => _isPremium = v),
                activeColor: Colors.teal,
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Continue to Lessons", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
