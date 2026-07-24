import 'package:flutter/material.dart';
import 'package:linkedfarm/Models/course_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:audioplayers/audioplayers.dart';

class LessonPlayerScreen extends StatefulWidget {
  final Course course;
  final Lesson initialLesson;

  const LessonPlayerScreen({super.key, required this.course, required this.initialLesson});

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  late Lesson _currentLesson;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _currentLesson = widget.initialLesson;
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // 1. Dispose old controllers
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    await _audioPlayer.stop();
    setState(() {
      _chewieController = null;
      _videoPlayerController = null;
      _isPlayingAudio = false;
    });

    // 2. Setup Video
    if (_currentLesson.videoUrl != null && _currentLesson.videoUrl!.isNotEmpty) {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(_currentLesson.videoUrl!));
      await _videoPlayerController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.green,
          handleColor: Colors.greenAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white,
        ),
      );
      setState(() {});
    } 
    // 3. Setup Audio
    else if (_currentLesson.audioUrl != null && _currentLesson.audioUrl!.isNotEmpty) {
      await _audioPlayer.setSourceUrl(_currentLesson.audioUrl!);
      setState(() {
        _isPlayingAudio = true;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _switchLesson(Lesson lesson) {
    if (lesson == _currentLesson) return;
    setState(() {
      _currentLesson = lesson;
    });
    _initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildPlayerArea(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                         decoration: BoxDecoration(color: Colors.teal[50], borderRadius: BorderRadius.circular(4)),
                         child: Text(_currentLesson.moduleTitle.toUpperCase(), 
                            style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.bold, fontSize: 10)),
                       ),
                       const SizedBox(width: 8),
                       Text(_currentLesson.duration, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                     ],
                   ),
                   const SizedBox(height: 12),
                   Text(_currentLesson.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                   const Divider(height: 40),
                   MarkdownBody(
                     data: _currentLesson.content,
                     styleSheet: MarkdownStyleSheet(
                       p: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                       h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                     ),
                   ),
                   const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildBaseNavigation(),
        ],
      ),
    );
  }

  Widget _buildPlayerArea() {
    final bool hasVideo = _chewieController != null && _videoPlayerController != null && _videoPlayerController!.value.isInitialized;
    
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: hasVideo 
          ? Chewie(controller: _chewieController!)
          : _isPlayingAudio 
            ? _buildAudioUI()
            : _buildPlaceholderUI(),
      ),
    );
  }

  Widget _buildAudioUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.audiotrack_rounded, color: Colors.greenAccent, size: 60),
        const SizedBox(height: 12),
        const Text("Playing Audio Lesson", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        StreamBuilder<Duration>(
          stream: _audioPlayer.onPositionChanged,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            return Slider(
              value: position.inSeconds.toDouble(),
              max: 300, // Should be duration from metadata
              onChanged: (v) => _audioPlayer.seek(Duration(seconds: v.toInt())),
              activeColor: Colors.greenAccent,
            );
          }
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: () => _audioPlayer.resume(), icon: const Icon(Icons.play_arrow, color: Colors.white)),
            IconButton(onPressed: () => _audioPlayer.pause(), icon: const Icon(Icons.pause, color: Colors.white)),
          ],
        )
      ],
    );
  }

  Widget _buildPlaceholderUI() {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.course.thumbnailUrl.startsWith('http')
            ? Image.network(widget.course.thumbnailUrl, fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.5))
            : Image.asset(widget.course.thumbnailUrl, fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.5)),
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.text_snippet_rounded, color: Colors.white, size: 60),
            SizedBox(height: 8),
            Text("Text-based Lesson", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildBaseNavigation() {
    final index = widget.course.lessons.indexOf(_currentLesson);
    final total = widget.course.lessons.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: index > 0 ? () => _switchLesson(widget.course.lessons[index - 1]) : null,
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            label: const Text("Previous"),
          ),
          Text("Lesson ${index + 1} of $total", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ElevatedButton(
            onPressed: index < total - 1 ? () => _switchLesson(widget.course.lessons[index + 1]) : () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: index < total - 1 ? Colors.teal[700] : Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: Text(index < total - 1 ? "Next Lesson" : "Finish Course"),
          ),
        ],
      ),
    );
  }
}
