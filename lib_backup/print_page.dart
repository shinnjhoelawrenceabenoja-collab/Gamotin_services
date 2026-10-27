import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'api.dart';
import 'theme.dart';
import 'widgets.dart';

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
        'copies': '$_copies', 'color': _color, 'paper_size': _size, 'paper_type': _type,
        'duplex': '$_duplex', 'page_range': _hasDocs ? _pages.text : '', 'notes': _notes.text,
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

  Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(t, style: const TextStyle(color: soft, fontSize: 15, fontWeight: FontWeight.w500)));

  Widget _addTile(IconData i, String t, VoidCallback onTap) => Material(
        color: purpleDark, borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22), onTap: onTap,
          child: SizedBox(width: 96, height: 96,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(i, color: Colors.white, size: 34), const SizedBox(height: 6),
                Text(t, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ])),
        ),
      );

  Widget _round(IconData i, VoidCallback? onTap) => Material(
        color: purpleDark, shape: const CircleBorder(),
        child: InkWell(customBorder: const CircleBorder(), onTap: onTap,
            child: SizedBox(width: 46, height: 46, child: Icon(i, color: onTap == null ? soft : Colors.white))),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: purple,
        body: Column(children: [
          Container(
            width: double.infinity, color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 24, 16),
                child: Row(children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: grey), onPressed: () => Navigator.pop(context)),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    Text('Printing', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                    Text('New print order', style: TextStyle(fontSize: 13, color: grey)),
                  ]),
                ]),
              ),
            ),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(30, 20, 30, 40), children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: purpleDark, borderRadius: BorderRadius.circular(20)),
                child: const Text(
                  'How printing works\n'
                  '1. Add your photos or files and choose your options.\n'
                  '2. Tap “Send to print”. We receive your order right away.\n'
                  '3. We print it and contact you on your registered number.\n'
                  '4. You get a notification when it is finished.',
                  style: TextStyle(color: soft, fontSize: 12, height: 1.6),
                ),
              ),
              _label('Photos / Files'),
              Row(children: [
                _addTile(Icons.image_outlined, 'Add photos', () => _pick(FileType.image)),
                const SizedBox(width: 12),
                _addTile(Icons.description_outlined, 'Add files', () => _pick(FileType.any)),
              ]),
              for (var i = 0; i < _files.length; i++)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                  decoration: BoxDecoration(color: purpleDark, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    _isImage(_files[i])
                        ? ClipRRect(borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(_files[i].path!), width: 44, height: 44, fit: BoxFit.cover, cacheWidth: 120,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.white, size: 40)))
                        : const Icon(Icons.description, color: Colors.white, size: 40),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_files[i].name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${(_files[i].size / 1024).toStringAsFixed(0)} KB', style: const TextStyle(color: soft, fontSize: 11)),
                    ])),
                    IconButton(tooltip: 'Remove', icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _files.removeAt(i))),
                  ]),
                ),
              _label('Number of copies'),
              Row(children: [
                _round(Icons.remove, _copies > 1 ? () => setState(() => _copies--) : null),
                SizedBox(width: 76, child: Text('$_copies', textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600))),
                _round(Icons.add, () => setState(() => _copies++)),
              ]),
              if (_hasDocs) ...[
                _label('Pages to print (optional, for PDF / Docs)'),
                PillField(controller: _pages, hint: 'e.g. 1-3, 5, 8-10 (blank = all)', onPurple: true),
              ],
              _label('Print type'),
              Wrap(spacing: 10, runSpacing: 10, children: [
                Pill('Black & White', selected: _color == 'bw', onTap: () => setState(() => _color = 'bw')),
                Pill('Colored', selected: _color == 'color', onTap: () => setState(() => _color = 'color')),
              ]),
              _label('Paper size'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in paperSizes) Pill(s, selected: _size == s, onTap: () => setState(() => _size = s)),
              ]),
              _label('Paper type'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in paperTypes) Pill(s, selected: _type == s, onTap: () => setState(() => _type = s)),
              ]),
              const SizedBox(height: 14),
              Theme(
                data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.white),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading,
                  activeColor: pink, checkColor: Colors.white, value: _duplex,
                  onChanged: (v) => setState(() => _duplex = v ?? false),
                  title: const Text('Back to back (print on both sides)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
              _label('Description / Opinions'),
              PillField(controller: _notes, hint: 'Tell us how you want it printed: cropping, borders, special requests, feedback…', onPurple: true, lines: 4),
              const SizedBox(height: 26),
              BigButton(_busy ? 'Uploading…' : 'Send to print', onPressed: _busy ? null : _send,
                  loading: _busy, color: Colors.white, textColor: purpleDark),
            ]),
          ),
        ]),
      );
}
