import 'package:epub_audio/features/audio/presentation/screens/audiobook_player_screen.dart';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/reader/presentation/screens/reader_screen.dart';
import 'package:epub_audio/features/session/presentation/controllers/book_session_controller.dart';
import 'package:epub_audio/features/text_content/data/parsers/text_document_parser.dart';
import 'package:epub_audio/features/text_content/domain/entities/text_document.dart';
import 'package:epub_audio/features/text_content/presentation/screens/text_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Quick Paste Bottom Sheet Modal allowing users to paste text and instantly read, listen, or edit.
class QuickPasteModal extends StatefulWidget {
  const QuickPasteModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const QuickPasteModal(),
    );
  }

  @override
  State<QuickPasteModal> createState() => _QuickPasteModalState();
}

class _QuickPasteModalState extends State<QuickPasteModal> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextDocumentParser _parser = TextDocumentParser();
  bool _isLoadingClipboard = true;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get _cardBorder => _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get _textPrimary => _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  Color get _textSecondary => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _fetchClipboard();
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _fetchClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data != null && data.text != null && data.text!.isNotEmpty) {
        _textController.text = data.text!;
        final lines = data.text!.trim().split('\n');
        final firstLine = lines.first.replaceAll(RegExp(r'[#>*_\-]'), '').trim();
        _titleController.text = firstLine.isNotEmpty && firstLine.length <= 40
            ? firstLine
            : 'Pasted Document (${DateTime.now().month}/${DateTime.now().day})';
      } else {
        _titleController.text = 'Pasted Text';
      }
    } catch (_) {
      _titleController.text = 'Pasted Text';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingClipboard = false;
        });
      }
    }
  }

  int get _wordCount {
    final text = _textController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  Future<TextDocument> _saveDoc() async {
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Pasted Text';
    final doc = TextDocument(
      id: 'paste_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      content: _textController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      source: 'clipboard',
    );
    await HiveStorageService().saveTextDocument(doc);
    return doc;
  }

  Future<void> _handleRead() async {
    if (_textController.text.trim().isEmpty) return;
    Navigator.pop(context);
    final doc = await _saveDoc();
    final book = _parser.parseDocument(doc);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => ReaderScreen(book: book)),
      );
    }
  }

  Future<void> _handleListen() async {
    if (_textController.text.trim().isEmpty) return;
    Navigator.pop(context);
    final doc = await _saveDoc();
    final book = _parser.parseDocument(doc);
    final session = BookSessionController(book: book);
    session.playAudio();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => AudiobookPlayerScreen(session: session)),
      );
    }
  }

  void _handleEditInWriter() {
    final content = _textController.text;
    final title = _titleController.text;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => TextEditorScreen(
          initialContent: content,
          initialTitle: title,
          source: 'clipboard',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = TextDocumentParser.detectLanguageFromText(_textController.text);

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.content_paste_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Paste & Read',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Convert clipboard text into speech & reading',
                        style: TextStyle(fontSize: 12.5, color: _textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoadingClipboard)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Title Field
              TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Document Title',
                  labelStyle: TextStyle(color: _textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _cardBorder),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Content Area
              TextField(
                controller: _textController,
                maxLines: 6,
                style: TextStyle(fontSize: 14, color: _textPrimary, height: 1.5),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Paste or type text here...',
                  hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _cardBorder),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 10),

              // Info & Language Chips
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_wordCount words',
                      style: TextStyle(fontSize: 11.5, color: _textSecondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Language: ${lang.toUpperCase()}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _handleEditInWriter,
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: const Text('Open in Writer', style: TextStyle(fontSize: 12.5)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Bottom Actions (Read & Listen)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _textController.text.trim().isNotEmpty ? _handleRead : null,
                      icon: const Icon(Icons.auto_stories_rounded, size: 18),
                      label: const Text('Read', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _textController.text.trim().isNotEmpty ? _handleListen : null,
                      icon: const Icon(Icons.headphones_rounded, size: 18),
                      label: const Text('Listen', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
