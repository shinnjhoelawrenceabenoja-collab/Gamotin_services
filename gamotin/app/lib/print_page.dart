import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'api.dart';

const paperSizes = [
  'A3 (297×420 mm)', 'A4 (210×297 mm)', 'A5 (148×210 mm)', 'A6 (105×148 mm)',
  'B4 (250×353 mm)', 'B5 (176×250 mm)',
  'Short / Letter (8.5×11 in)', 'Long / Folio (8.5×13 in)', 'Legal (8.5×14 in)',
  'Tabloid / Ledger (11×17 in)', 'Statement (5.5×8.5 in)',
  '3R (3.5×5 in)', '4R (4×6 in)', '5R (5×7 in)', '6R (6×8 in)', '8R (8×10 in)',
  'Other (write it in the notes)',
];
const paperTypes = [
  'Plain / Normal Bond', 'Photo Paper – Glossy', 'Photo Paper – Matte', 'Matte Paper',
  'Cardstock', 'Sticker Paper', 'Sintra / Board', 'Canvas', 'Recycled Paper', 'Other (write it in the notes)',
];
const _imgExt = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'};
bool _isImage(PlatformFile f) => _imgExt.contains((f.extension ?? '').toLowerCase());

class PrintPage extends StatefulWidget {
  const PrintPage({super.key});
  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  final List<PlatformFile> _files = [];
  int _copies = 1;
  String _color = 'bw', _size = paperSizes[1], _type = paperTypes[0];
  bool _duplex = false, _busy = false;
  final _pages = TextEditingController(), _notes = TextEditingController();

  bool get _hasDocs => _files.any((f) => !_isImage(f));

  Future<void> _pick(FileType type) async {
    final r = await FilePicker.platform.pickFiles(allowMultiple: true, type: type);
    if (r == null) return;
    setState(() {
      for (final f in r.files) {
        if (f.path != null && !_files.any((x) => x.path == f.path)) _files.add(f);
      }
    });
  }

  Future<void> _send() async {
    if (_files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one photo or file')));
      return;
    }
    setState(() => _busy = true);
    try {
      await Api.submitOrder({
        'copies': '$_copies',
        'color': _color,
        'paper_size': _size,
        'paper_type': _type,
        'duplex': '$_duplex',
        'page_range': _hasDocs ? _pages.text : '',
        'notes': _notes.text,
      }, _files);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order sent! We will notify you when it is done.')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _section(String t, Widget child) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Printing')),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'How printing works\n'
                '1. Add your photos or files and choose your print options.\n'
                '2. Tap “Send to print”. We receive your order right away.\n'
                '3. We print it and contact you using your registered number.\n'
                '4. You get a notification when it is finished and ready for pickup.',
              ),
            ),
          ),
          _section('Photos / Files', Column(children: [
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                  onPressed: () => _pick(FileType.image),
                  icon: const Icon(Icons.photo_library), label: const Text('Add photos'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                  onPressed: () => _pick(FileType.any),
                  icon: const Icon(Icons.attach_file), label: const Text('Add files'))),
            ]),
            for (var i = 0; i < _files.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _isImage(_files[i])
                    ? ClipRRect(borderRadius: BorderRadius.circular(6),
                        child: Image.file(File(_files[i].path!), width: 48, height: 48, fit: BoxFit.cover,
                            cacheWidth: 120, errorBuilder: (_, __, ___) => const Icon(Icons.image)))
                    : const Icon(Icons.description, size: 40),
                title: Text(_files[i].name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${(_files[i].size / 1024).toStringAsFixed(0)} KB'),
                trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _files.removeAt(i))),
              ),
            if (_files.isNotEmpty) Align(alignment: Alignment.centerLeft, child: Text('${_files.length} item(s) selected')),
          ])),
          _section('Number of copies', Row(children: [
            IconButton.filledTonal(onPressed: _copies > 1 ? () => setState(() => _copies--) : null, icon: const Icon(Icons.remove)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('$_copies', style: Theme.of(context).textTheme.headlineSmall)),
            IconButton.filledTonal(onPressed: () => setState(() => _copies++), icon: const Icon(Icons.add)),
          ])),
          if (_hasDocs)
            _section('Pages to print (optional, for PDF/Docs)', TextField(
              controller: _pages,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. 1-3, 5, 8-10  (blank = all pages)'),
            )),
          _section('Print type', SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'bw', label: Text('Black & White'), icon: Icon(Icons.contrast)),
              ButtonSegment(value: 'color', label: Text('Colored'), icon: Icon(Icons.palette)),
            ],
            selected: {_color},
            onSelectionChanged: (s) => setState(() => _color = s.first),
          )),
          _section('Paper size', DropdownButtonFormField<String>(
            value: _size, isExpanded: true, decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [for (final s in paperSizes) DropdownMenuItem(value: s, child: Text(s))],
            onChanged: (v) => setState(() => _size = v!),
          )),
          _section('Paper type', DropdownButtonFormField<String>(
            value: _type, isExpanded: true, decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [for (final s in paperTypes) DropdownMenuItem(value: s, child: Text(s))],
            onChanged: (v) => setState(() => _type = v!),
          )),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _duplex,
            onChanged: (v) => setState(() => _duplex = v ?? false),
            title: const Text('Back to back (print on both sides)'),
          ),
          _section('Description / Opinions', TextField(
            controller: _notes, maxLines: 4,
            decoration: const InputDecoration(border: OutlineInputBorder(),
                hintText: 'Tell us how you want it printed: cropping, borders, which photo is which size, special requests, feedback…'),
          )),
        ]),
        bottomSheet: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(width: double.infinity, height: 52,
                child: FilledButton.icon(
                    onPressed: _busy ? null : _send,
                    icon: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    label: Text(_busy ? 'Uploading…' : 'Send to print'))),
          ),
        ),
      );
}
