import 'package:epub_audio/features/audio/presentation/screens/audiobook_player_screen.dart';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/reader/presentation/screens/reader_screen.dart';
import 'package:epub_audio/features/session/presentation/controllers/book_session_controller.dart';
import 'package:epub_audio/features/text_content/data/parsers/text_document_parser.dart';
import 'package:epub_audio/features/text_content/domain/entities/text_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Direct In-App Text Writing & Editor Screen.
/// Allows writing, pasting, editing, and immediate Read / Listen actions.
class TextEditorScreen extends StatefulWidget {
  final TextDocument? existingDocument;
  final String? initialContent;
  final String? initialTitle;
  final String source;

  const TextEditorScreen({
    super.key,
    this.existingDocument,
    this.initialContent,
    this.initialTitle,
    this.source = 'direct_write',
  });

  @override
  State<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<TextEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final TextDocumentParser _parser = TextDocumentParser();
  bool _isSaving = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get _cardBg => _isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get _cardBorder => _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get _textPrimary => _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  Color get _textSecondary => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingDocument?.title ??
          widget.initialTitle ??
          'Document ${DateTime.now().month}/${DateTime.now().day}',
    );
    _contentController = TextEditingController(
      text: widget.existingDocument?.content ?? widget.initialContent ?? '',
    );
    _contentController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  int get _wordCount {
    final text = _contentController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  int get _charCount => _contentController.text.length;

  int get _readingMinutes {
    final words = _wordCount;
    if (words == 0) return 0;
    final mins = (words / 200).ceil();
    return mins < 1 ? 1 : mins;
  }

  Future<TextDocument> _saveDocument() async {
    final id = widget.existingDocument?.id ??
        'text_doc_${DateTime.now().millisecondsSinceEpoch}';
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Untitled Document';
    final content = _contentController.text.trim();

    final doc = TextDocument(
      id: id,
      title: title,
      content: content,
      createdAt: widget.existingDocument?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      source: widget.source,
    );

    await HiveStorageService().saveTextDocument(doc);
    return doc;
  }

  Future<void> _handlePasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      final current = _contentController.text;
      final newText = current.isEmpty ? data.text! : '$current\n\n${data.text!}';
      _contentController.text = newText;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pasted from clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty')),
        );
      }
    }
  }

  Future<void> _handleSaveOnly() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write or paste some text first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    await _saveDocument();
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document saved to library!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _handleReadNow() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write or paste some text first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final doc = await _saveDocument();
    final book = _parser.parseDocument(doc);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReaderScreen(book: book),
        ),
      );
    }
  }

  Future<void> _handleListenNow() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write or paste some text first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final doc = await _saveDocument();
    final book = _parser.parseDocument(doc);
    final session = BookSessionController(book: book);
    session.playAudio();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudiobookPlayerScreen(session: session),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingDocument != null ? 'Edit Document' : 'Write & Read Text',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: _textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_paste_rounded, size: 20),
            tooltip: 'Paste from Clipboard',
            color: const Color(0xFF3B82F6),
            onPressed: _handlePasteFromClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded, size: 22),
            tooltip: 'Save Document',
            color: const Color(0xFF10B981),
            onPressed: _isSaving ? null : _handleSaveOnly,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 1. Statistics Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: _cardBg,
              border: Border(bottom: BorderSide(color: _cardBorder)),
            ),
            child: Row(
              children: [
                _buildStatBadge(Icons.notes_rounded, '$_wordCount words'),
                const SizedBox(width: 12),
                _buildStatBadge(Icons.text_fields_rounded, '$_charCount chars'),
                const SizedBox(width: 12),
                _buildStatBadge(
                  Icons.schedule_rounded,
                  '~$_readingMinutes min read',
                ),
              ],
            ),
          ),

          // 2. Title and Content Editor
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Input
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Document Title...',
                      hintStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textSecondary.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Divider(color: _cardBorder),
                  const SizedBox(height: 8),

                  // Content Input
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: _textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Type, paste, or draft your text here...\n\n• Paragraphs will be separated by blank lines\n• Supports Markdown headings (# Title, ## Section)\n• Supports quotes (> note)\n• Read and listen in Malayalam, English, Hindi & 30+ languages',
                      hintStyle: TextStyle(
                        fontSize: 14.5,
                        height: 1.6,
                        color: _textSecondary.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Action Bar (Read Now & Listen Buttons)
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: _cardBg,
              border: Border(top: BorderSide(color: _cardBorder)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Read Now Button
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _handleReadNow,
                    icon: const Icon(Icons.auto_stories_rounded, size: 18),
                    label: const Text(
                      'Read',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Listen Audio Button
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _handleListenNow,
                    icon: const Icon(Icons.headphones_rounded, size: 18),
                    label: const Text(
                      'Listen',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
