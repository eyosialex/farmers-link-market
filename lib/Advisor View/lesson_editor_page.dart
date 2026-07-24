import 'package:flutter/material.dart';
import 'package:linkedfarm/Models/course_model.dart';
import 'package:linkedfarm/Services/learning_service.dart';
import 'package:linkedfarm/Farmers%20View/Cloudnary_Store.dart';
import 'package:file_picker/file_picker.dart';
import 'package:linkedfarm/Services/io_compatibility.dart' if (dart.library.html) 'package:linkedfarm/Services/web_compatibility.dart';

class LessonEditorPage extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  const LessonEditorPage({super.key, required this.courseId, required this.courseTitle});

  @override
  State<LessonEditorPage> createState() => _LessonEditorPageState();
}

class _LessonEditorPageState extends State<LessonEditorPage> {
  final LearningService _learningService = LearningService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _lessonTitleController = TextEditingController();
  final TextEditingController _lessonContentController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  
  String _moduleTitle = 'Module 1';
  String? _videoUrl;
  String? _audioUrl;
  bool _isUploading = false;
  bool _isSaving = false;
  String _uploadProgress = '';

  Future<void> _pickAndUploadMedia(bool isVideo) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: isVideo ? FileType.video : FileType.audio,
    );

    if (result != null) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 'Uploading to Cloudinary...';
      });

      try {
        final file = File(result.files.single.path!);
        final url = await _cloudinaryService.uploadFile(
          file, 
          folder: isVideo ? 'course_videos' : 'course_audio'
        );

        if (url != null) {
          setState(() {
            if (isVideo) {
              _videoUrl = url;
              _audioUrl = null;
            } else {
              _audioUrl = url;
              _videoUrl = null;
            }
            _uploadProgress = 'Upload successful!';
          });
        }
      } catch (e) {
        setState(() => _uploadProgress = 'Upload failed: $e');
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _addLesson() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final lesson = Lesson(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _lessonTitleController.text.trim(),
        content: _lessonContentController.text.trim(),
        duration: _durationController.text.trim().isEmpty ? "5:00" : _durationController.text.trim(),
        videoUrl: _videoUrl,
        audioUrl: _audioUrl,
        moduleTitle: _moduleTitle,
        isCompleted: false,
      );

      await _learningService.addLessonToCourse(widget.courseId, lesson);
      
      // Clear forms
      _lessonTitleController.clear();
      _lessonContentController.clear();
      _durationController.clear();
      setState(() {
        _videoUrl = null;
        _audioUrl = null;
        _uploadProgress = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lesson added!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add lesson: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Building: ${widget.courseTitle}"),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Current Lessons List
          Expanded(
            child: StreamBuilder<List<Course>>(
              stream: _learningService.streamAllCourses(), // Simplified for now, or filter by courseId
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final course = snapshot.data!.firstWhere((c) => c.id == widget.courseId);
                final lessons = course.lessons;

                if (lessons.isEmpty) {
                  return const Center(child: Text("No lessons yet. Add your first one below!"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final l = lessons[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal[100],
                          child: Text("${index + 1}"),
                        ),
                        title: Text(l.title),
                        subtitle: Text("${l.moduleTitle} • ${l.duration}"),
                        trailing: Icon(
                          l.videoUrl != null ? Icons.videocam : (l.audioUrl != null ? Icons.audiotrack : Icons.text_snippet),
                          color: Colors.teal,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 2. Add Lesson Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Add New Lesson", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lessonTitleController,
                      decoration: const InputDecoration(labelText: "Lesson Title", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Title required" : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _moduleTitle == 'Module 1' ? null : TextEditingController(text: _moduleTitle),
                            decoration: const InputDecoration(labelText: "Module Name", border: OutlineInputBorder()),
                            onChanged: (v) => _moduleTitle = v,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            decoration: const InputDecoration(labelText: "Duration (e.g. 10:00)", border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Media Pickers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMediaButton(
                          icon: Icons.video_call_rounded,
                          label: "Video",
                          isActive: _videoUrl != null,
                          onPressed: () => _pickAndUploadMedia(true),
                        ),
                        _buildMediaButton(
                          icon: Icons.audio_file_rounded,
                          label: "Audio",
                          isActive: _audioUrl != null,
                          onPressed: () => _pickAndUploadMedia(false),
                        ),
                      ],
                    ),
                    
                    if (_isUploading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 4),
                      Text(_uploadProgress, style: const TextStyle(fontSize: 12, color: Colors.blue)),
                    ] else if (_videoUrl != null || _audioUrl != null) ...[
                      const SizedBox(height: 8),
                      Text("✅ Media Uploaded Successfully", style: TextStyle(color: Colors.green[700], fontSize: 13, fontWeight: FontWeight.bold)),
                    ],

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving || _isUploading ? null : _addLesson,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800], foregroundColor: Colors.white),
                        child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Add Lesson"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton({required IconData icon, required String label, required bool isActive, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: isActive ? Colors.green[100] : Colors.grey[200],
            child: Icon(icon, color: isActive ? Colors.green[800] : Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: isActive ? Colors.green[800] : Colors.grey[600])),
        ],
      ),
    );
  }
}
