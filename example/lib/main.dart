import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_cast_video/flutter_cast_video.dart';

String duration2String(Duration? dur, {showLive = 'Live'}) {
  Duration duration = dur ?? Duration();
  if (duration.inSeconds < 0) return showLive;
  return duration.toString().split('.').first.padLeft(8, "0");
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: CastSample());
  }
}

// ─────────────────────────────────────────────
// Uses Listener (not GestureDetector) so pointer
// events fire WITHOUT consuming the touch —
// meaning the native platform view still gets it too.
// ─────────────────────────────────────────────
class TappableNativeView extends StatefulWidget {
  final Widget child;
  final Color color;
  final void Function() onTapDetected;

  const TappableNativeView({
    Key? key,
    required this.child,
    required this.color,
    required this.onTapDetected,
  }) : super(key: key);

  @override
  State<TappableNativeView> createState() => _TappableNativeViewState();
}

class _TappableNativeViewState extends State<TappableNativeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _highlighted = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 120),
      reverseDuration: Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _animController.forward();
    setState(() => _highlighted = true);
    widget.onTapDetected();
  }

  void _onPointerUp(PointerUpEvent event) {
    _animController.reverse();
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) setState(() => _highlighted = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      // HitTestBehavior.translucent: Listener fires AND
      // the native view underneath still receives the touch
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _highlighted
                ? widget.color.withOpacity(0.2)
                : Colors.transparent,
            border: Border.all(
              color: _highlighted
                  ? widget.color.withOpacity(0.9)
                  : widget.color.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: _highlighted
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.45),
                      blurRadius: 14,
                      spreadRadius: 3,
                    )
                  ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Main app
// ─────────────────────────────────────────────
class CastSample extends StatefulWidget {
  static const _iconSize = 36.0;

  @override
  _CastSampleState createState() => _CastSampleState();
}

class _CastSampleState extends State<CastSample> {
  late ChromeCastController _controller;
  AppState _state = AppState.idle;
  bool _playing = false;
  Map<dynamic, dynamic> _mediaInfo = {};
  final List<String> _logs = ['App started.'];

  void _log(String message, {bool isError = false}) {
    final time = TimeOfDay.now().format(context);
    setState(() =>
        _logs.insert(0, '${isError ? "❌" : "→"} [$time] $message'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plugin example app'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          TappableNativeView(
            color: Colors.white,
            onTapDetected: () =>
                _log('Tap detected: AirPlay (AppBar)'),
            child: AirPlayButton(
              size: CastSample._iconSize,
              color: Colors.white,
              activeColor: Colors.amber,
              onRoutesOpening: () => _log('AirPlay: picker opening ✓'),
              onRoutesClosed: () => _log('AirPlay: picker closed'),
            ),
          ),
          SizedBox(width: 4),
          TappableNativeView(
            color: Colors.white,
            onTapDetected: () =>
                _log('Tap detected: ChromeCast (AppBar)'),
            child: ChromeCastButton(
              size: CastSample._iconSize,
              color: Colors.white,
              onButtonCreated: _onButtonCreated,
              onSessionStarted: _onSessionStarted,
              onSessionEnded: () {
                _log('ChromeCast: session ended');
                setState(() => _state = AppState.idle);
              },
              onRequestCompleted: _onRequestCompleted,
              onRequestFailed: _onRequestFailed,
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: Center(child: _handleState())),
          _statusLog(),
        ],
      ),
    );
  }

  Widget _statusLog() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border(top: BorderSide(color: Colors.grey.shade700)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle),
                ),
                SizedBox(width: 6),
                Text('Debug Log',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _logs
                    ..clear()
                    ..add('Log cleared')),
                  child: Text('clear',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11)),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade800, height: 1),
          Expanded(
            child: ListView.builder(
              padding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: _logs.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(
                  _logs[i],
                  style: TextStyle(
                    color: _logs[i].startsWith('❌')
                        ? Colors.redAccent
                        : Colors.white70,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    resetTimer();
    super.dispose();
  }

  Widget _handleState() {
    switch (_state) {
      case AppState.idle:
        resetTimer();
        return _idleView();
      case AppState.connected:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 16),
            Text('Connected — loading media...'),
          ],
        );
      case AppState.mediaLoaded:
        startTimer();
        return _mediaControls();
      case AppState.error:
        resetTimer();
        return _errorView();
      default:
        return Container();
    }
  }

  Widget _idleView() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cast, size: 72, color: Colors.deepPurple.shade200),
          SizedBox(height: 20),
          Text('No Cast Device Connected',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            'Tap a button below. The ring will glow when Flutter detects your tap.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          SizedBox(height: 36),
          _scanRow(
            label: 'ChromeCast',
            color: Colors.deepPurple,
            onTap: () =>
                _log('Tap detected: ChromeCast (body)'),
            child: ChromeCastButton(
              size: 36,
              color: Colors.deepPurple,
              onButtonCreated: _onButtonCreated,
              onSessionStarted: _onSessionStarted,
              onSessionEnded: () {
                _log('ChromeCast: session ended');
                setState(() => _state = AppState.idle);
              },
              onRequestCompleted: _onRequestCompleted,
              onRequestFailed: _onRequestFailed,
            ),
          ),
          SizedBox(height: 20),
          _scanRow(
            label: 'AirPlay',
            color: Colors.blue.shade700,
            onTap: () => _log('Tap detected: AirPlay (body)'),
            child: AirPlayButton(
              size: 36,
              color: Colors.blue.shade700,
              activeColor: Colors.amber,
              onRoutesOpening: () =>
                  _log('AirPlay: picker opening ✓'),
              onRoutesClosed: () => _log('AirPlay: picker closed'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanRow({
    required String label,
    required Color color,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Scan for $label',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color)),
          SizedBox(width: 16),
          TappableNativeView(
            color: color,
            onTapDetected: onTap,
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 60, color: Colors.red),
        SizedBox(height: 16),
        Text('An error occurred', style: TextStyle(fontSize: 18)),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            _log('Retrying...');
            setState(() => _state = AppState.idle);
          },
          child: Text('Try Again'),
        ),
      ],
    );
  }

  Duration? position, duration;

  Widget _mediaControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cast_connected, size: 48, color: Colors.deepPurple),
        SizedBox(height: 8),
        Text('Casting',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundIconButton(
              icon: Icons.replay_10,
              onPressed: () {
                _log('Seeking -10s');
                _controller.seek(relative: true, interval: -10.0);
              },
            ),
            _RoundIconButton(
              icon: _playing ? Icons.pause : Icons.play_arrow,
              onPressed: _playPause,
            ),
            _RoundIconButton(
              icon: Icons.forward_10,
              onPressed: () {
                _log('Seeking +10s');
                _controller.seek(relative: true, interval: 10.0);
              },
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
            duration2String(position) +
                ' / ' +
                duration2String(duration),
            style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(jsonEncode(_mediaInfo),
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center),
        ),
        SizedBox(height: 16),
        TextButton.icon(
          icon: Icon(Icons.cast, color: Colors.red),
          label:
              Text('Disconnect', style: TextStyle(color: Colors.red)),
          onPressed: () {
            _log('Manually disconnected');
            setState(() => _state = AppState.idle);
          },
        ),
      ],
    );
  }

  Timer? _timer;

  Future<void> _monitor() async {
    var dur = await _controller.duration(),
        pos = await _controller.position();
    if (duration == null || duration!.inSeconds != dur.inSeconds)
      setState(() => duration = dur);
    if (position == null || position!.inSeconds != pos.inSeconds)
      setState(() => position = pos);
  }

  void resetTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void startTimer() {
    if (_timer?.isActive ?? false) return;
    resetTimer();
    _timer =
        Timer.periodic(Duration(seconds: 1), (_) => _monitor());
  }

  Future<void> _playPause() async {
    final playing = await _controller.isPlaying();
    if (playing == null) {
      _log('isPlaying() returned null', isError: true);
      return;
    }
    _log(playing ? 'Pausing...' : 'Playing...');
    if (playing)
      await _controller.pause();
    else
      await _controller.play();
    setState(() => _playing = !playing);
  }

  Future<void> _onButtonCreated(
      ChromeCastController controller) async {
    _log('ChromeCast: button created ✓ — adding session listener...');
    _controller = controller;
    await _controller.addSessionListener();
    _log('ChromeCast: session listener added ✓');
  }

  Future<void> _onSessionStarted() async {
    _log('ChromeCast: session started ✓ — loading media...');
    setState(() => _state = AppState.connected);
    await _controller.loadMedia(
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      title: "TestTitle",
      subtitle: "test Sub title",
      image:
          "https://smaller-pictures.appspot.com/images/dreamstime_xxl_65780868_small.jpg",
    );
  }

  Future<void> _onRequestCompleted() async {
    _log('ChromeCast: media request completed ✓');
    final playing = await _controller.isPlaying();
    if (playing == null) {
      _log('isPlaying() returned null after load', isError: true);
      return;
    }
    final mediaInfo = await _controller.getMediaInfo();
    _log('Media info: ${jsonEncode(mediaInfo)}');
    setState(() {
      _state = AppState.mediaLoaded;
      _playing = playing;
      if (mediaInfo != null) _mediaInfo = mediaInfo;
    });
  }

  Future<void> _onRequestFailed(String? error) async {
    _log('ChromeCast ERROR: $error', isError: true);
    setState(() => _state = AppState.error);
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  _RoundIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Icon(icon, color: Colors.white),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(16.0),
        backgroundColor: Colors.deepPurple,
        shape: CircleBorder(),
      ),
      onPressed: onPressed,
    );
  }
}

enum AppState { idle, connected, mediaLoaded, error }
