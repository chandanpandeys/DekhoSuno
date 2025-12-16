import 'package:flutter/material.dart';

class ActivityLogEntry {
  final DateTime timestamp;
  final String icon;
  final String source;
  final String message;
  final Duration? duration;

  ActivityLogEntry({
    required this.timestamp,
    required this.icon,
    required this.source,
    required this.message,
    this.duration,
  });

  String get formattedTime {
    return "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}";
  }

  String get formattedDuration {
    if (duration == null) return '';
    return '(${duration!.inMilliseconds / 1000}s)';
  }
}

class ActivityLogWidget extends StatefulWidget {
  final List<ActivityLogEntry> entries;
  final double? height;

  const ActivityLogWidget({
    super.key,
    required this.entries,
    this.height,
  });

  @override
  State<ActivityLogWidget> createState() => _ActivityLogWidgetState();
}

class _ActivityLogWidgetState extends State<ActivityLogWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(ActivityLogWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entries.length > oldWidget.entries.length) {
      // Auto-scroll to bottom when new entry is added
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text(
                  '🤖 Activity Log',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.entries.length} events',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          Expanded(
            child: widget.entries.isEmpty
                ? Center(
                    child: Text(
                      'No activity yet...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.entries.length,
                    itemBuilder: (context, index) {
                      final entry = widget.entries[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.formattedTime,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.icon,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '${entry.source} ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.tealAccent,
                                      ),
                                    ),
                                    TextSpan(text: entry.message),
                                    if (entry.duration != null)
                                      TextSpan(
                                        text: ' ${entry.formattedDuration}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class GeminiStatusBadge extends StatelessWidget {
  final bool isProcessing;
  final String? statusText;

  const GeminiStatusBadge({
    super.key,
    required this.isProcessing,
    this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isProcessing
            ? Colors.purple.withOpacity(0.2)
            : Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isProcessing ? Colors.purpleAccent : Colors.greenAccent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isProcessing)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.purpleAccent),
              ),
            )
          else
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
          const SizedBox(width: 6),
          Text(
            statusText ?? (isProcessing ? '✨ Gemini Analyzing...' : '✅ Ready'),
            style: TextStyle(
              color: isProcessing ? Colors.purpleAccent : Colors.greenAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
