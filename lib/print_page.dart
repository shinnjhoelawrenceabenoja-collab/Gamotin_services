import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'api.dart';
import 'config.dart';
import 'theme.dart';

class PrintPage extends StatefulWidget {
  const PrintPage({super.key});
  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  final List<PlatformFile> _files = [];
  int _copies = 1;
  bool _color = false, _duplex = false, _busy = false;
  String _size = 'A4', _type = 'Normal Bond Paper';
  final _pages = TextEditingController();
  final _notes = TextEditingController();

  static const _docExt = ['pdf', 'doc', 'docx', 'ppt', 'pptx'];
  bool get _hasDoc =>
      _files.any((f) => _docExt.contains((f.extension ?? '').toLowerCase()));

  Future<void> _pick(FileType type) async {
    final r = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: type,
      allowedExtensions: type == FileType.custom
          ? ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt']
          : null,
    );
    if (r == null) return;
    setState(() {
      for (final f in r.files) {
        if (f.path != null && !_files.any((x) => x.path == f.path)) _files.add(f);
      }
    });
  }

  String _sz(int b) => b > 1048576
      ? '${(b / 1048576).toStringAsFixed(1)} MB'
      : '${(b / 1024).toStringAsFixed(0)} KB';

  bool _validRange(String s) => RegExp(
          r'^\s*\d+(\s*-\s*\d+)?(\s*,\s*\d+(\s*-\s*\d+)?)*\s*$')
      .hasMatch(s);

  Future<void> _submit() async {
    if (_files.isEmpty) return G.snack(context, 'Please add at least one photo or file');
    final range = _hasDoc ? _pages.text.trim() : '';
    if (range.isNotEmpty && !_validRange(range)) {
      return G.snack(context, 'Pages format example: 1-3, 5, 8-10');
    }
    setState(() => _busy = true);
    try {
      final id = await Api.createOrder(
        files: _files,
        copies: _copies,
        color: _color,
        paperSize: _size,
        paperType: _type,
        duplex: _duplex,
        pageRange: range,
        notes: _notes.text.trim(),
      );
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: G.teal, size: 48),
          title: Text('Order #$id sent!'),
          content: const Text(
              'We received your files. You will get a notification when your print is finished.'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
        ),
      );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) G.snack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _section(String t, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, color: G.navy)),
          ),
          child,
        ]),
      );

  Widget _drop(String value, List<String> items, ValueChanged<String> on) =>
      DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => on(v!),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Print'), backgroundColor: G.bg),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        // how it works
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
              gradient: G.gradient, borderRadius: BorderRadius.circular(18)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('How printing works',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            SizedBox(height: 8),
            Text(
                '1. Upload your photos or files.\n2. Choose copies, color, paper size and type.\n3. Submit. We print it and notify you when it is finished.\n4. Pick up your prints.',
                style: TextStyle(color: Colors.white, height: 1.5)),
          ]),
        ),

        _section(
          'Photos & Files (any amount)',
          Column(children: [
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => _pick(FileType.image),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Add photos')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => _pick(FileType.custom),
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Add files')),
              ),
            ]),
            ..._files.map((f) => Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                        _docExt.contains((f.extension ?? '').toLowerCase())
                            ? Icons.description_outlined
                            : Icons.image_outlined,
                        color: G.teal),
                    title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(_sz(f.size)),
                    trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _files.remove(f))),
                  ),
                )),
            if (_files.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Text('${_files.length} file(s) selected',
                    style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ),
          ]),
        ),

        _section(
          'Number of copies',
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              IconButton(
                  onPressed: _copies > 1 ? () => setState(() => _copies--) : null,
                  icon: const Icon(Icons.remove_circle_outline)),
              Expanded(
                  child: Text('$_copies',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
              IconButton(
                  onPressed: _copies < 999 ? () => setState(() => _copies++) : null,
                  icon: const Icon(Icons.add_circle_outline)),
            ]),
          ),
        ),

        if (_hasDoc)
          _section(
            'Pages to print (optional, for PDF / DOC)',
            TextField(
              controller: _pages,
              decoration: const InputDecoration(
                  hintText: 'e.g. 1-3, 5, 8-10  (blank = all pages)',
                  prefixIcon: Icon(Icons.format_list_numbered)),
            ),
          ),

        _section(
          'Print type',
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Black & White'), icon: Icon(Icons.contrast)),
              ButtonSegment(value: true, label: Text('Colored'), icon: Icon(Icons.palette_outlined)),
            ],
            selected: {_color},
            onSelectionChanged: (s) => setState(() => _color = s.first),
          ),
        ),

        _section('Paper size', _drop(_size, kPaperSizes, (v) => setState(() => _size = v))),
        _section('Paper type', _drop(_type, kPaperTypes, (v) => setState(() => _type = v))),

        Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: CheckboxListTile(
            value: _duplex,
            onChanged: (v) => setState(() => _duplex = v!),
            title: const Text('Back to back (both sides)'),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: G.teal,
          ),
        ),

        _section(
          'Notes / opinions (optional)',
          TextField(
            controller: _notes,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
                hintText: 'Tell us how you want it: borderless photo, staple, crop, brightness...'),
          ),
        ),

        FilledButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox(height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Icon(Icons.send_rounded),
          label: Text(_busy ? 'Uploading...' : 'Submit print order',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }
}
