import 'dart:convert';
import 'dart:html' as html;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/document.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

const _kCategoryAll = 'All';
const _kCategoryLease = 'lease';
const _kCategoryReceipt = 'receipt';
const _kCategoryAgreement = 'agreement';
const _kCategoryOther = 'other';

class DocumentsListScreen extends StatefulWidget {
  final int propertyId;
  final String propertyName;
  final int? unitId;
  final int? tenantId;
  final int? tenancyId;

  const DocumentsListScreen({
    super.key,
    required this.propertyId,
    required this.propertyName,
    this.unitId,
    this.tenantId,
    this.tenancyId,
  });

  @override
  State<DocumentsListScreen> createState() => _DocumentsListScreenState();
}

class _DocumentsListScreenState extends State<DocumentsListScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  String _category = _kCategoryAll;
  Future<List<DocumentItem>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  Future<List<DocumentItem>> _fetch() async {
    final response = await _api.get('/documents', query: {
      'propertyId': widget.propertyId,
      if (widget.unitId != null) 'unitId': widget.unitId,
      if (widget.tenantId != null) 'tenantId': widget.tenantId,
      if (widget.tenancyId != null) 'tenancyId': widget.tenancyId,
      if (_category != _kCategoryAll) 'type': _category,
      if (_searchController.text.trim().isNotEmpty) 'search': _searchController.text.trim(),
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to load documents (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => DocumentItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _openAddSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddDocumentSheet(),
    );

    if (!mounted || result == null) return;
    if (result == 'upload') {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => UploadDocumentSheet(
          propertyId: widget.propertyId,
          tenancyId: widget.tenancyId,
          tenantId: widget.tenantId,
          unitId: widget.unitId,
        ),
      );
      if (ok == true) _reload();
    } else if (result == 'lease') {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => GenerateLeaseSheet(propertyId: widget.propertyId),
      );
      if (ok == true) _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Documents — ${widget.propertyName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.kodiGreen,
        foregroundColor: AppColors.white,
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Document'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _reload(),
                decoration: InputDecoration(
                  hintText: 'Search by title or description...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _reload();
                          },
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                children: const [
                  _kCategoryAll,
                  _kCategoryLease,
                  _kCategoryReceipt,
                  _kCategoryAgreement,
                  _kCategoryOther,
                ]
                    .map(
                      (cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_categoryLabel(cat)),
                          selected: _category == cat,
                          selectedColor:
                              AppColors.kodiGreen.withValues(alpha: 0.14),
                          onSelected: (_) {
                            setState(() => _category = cat);
                            _reload();
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _reload(),
                child: FutureBuilder<List<DocumentItem>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _ErrorState(
                        message: snapshot.error.toString(),
                        onRetry: _reload,
                      );
                    }
                    final items = snapshot.data ?? const [];
                    if (items.isEmpty) {
                      return _EmptyDocumentsState(onAdd: _openAddSheet);
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => _DocumentCard(
                        document: items[index],
                        onTap: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DocumentDetailScreen(document: items[index]),
                            ),
                          );
                          if (changed == true) _reload();
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _categoryLabel(String value) {
  switch (value) {
    case _kCategoryAll:
      return 'All';
    case _kCategoryLease:
      return 'Leases';
    case _kCategoryReceipt:
      return 'Receipts';
    case _kCategoryAgreement:
      return 'Agreements';
    case _kCategoryOther:
      return 'Other';
    default:
      return value;
  }
}

IconData _iconForType(String type) {
  switch (type) {
    case 'lease':
      return Icons.assignment_outlined;
    case 'receipt':
      return Icons.receipt_long_outlined;
    case 'agreement':
      return Icons.handshake_outlined;
    default:
      return Icons.description_outlined;
  }
}

Color _colorForType(String type) {
  switch (type) {
    case 'lease':
      return AppColors.kodiBlue;
    case 'receipt':
      return AppColors.kodiGreen;
    case 'agreement':
      return AppColors.kodiOrange;
    default:
      return AppColors.muted;
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentItem document;
  final VoidCallback onTap;

  const _DocumentCard({required this.document, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(document.type);
    final df = DateFormat('d MMM yyyy');
    final subtitleParts = <String>[
      if (document.tenantName != null) document.tenantName!,
      if (document.unitNumber != null) 'Unit ${document.unitNumber}',
    ];

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForType(document.type), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (document.generated)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Generated',
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitleParts.join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.caption,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          _categoryLabel(document.type),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        const Text(
                          '  •  ',
                          style:
                              TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                        Text(
                          df.format(document.createdAt),
                          style: AppStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddDocumentSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.successSoft,
                child: Icon(Icons.upload_file_outlined,
                    color: AppColors.kodiGreen),
              ),
              title: const Text('Upload Document',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('PDF, image, or scanned file'),
              onTap: () => Navigator.pop(context, 'upload'),
            ),
            const Divider(height: 1, color: AppColors.border),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE6EEFB),
                child: Icon(Icons.note_add_outlined, color: AppColors.kodiBlue),
              ),
              title: const Text('Generate Lease',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Auto-fill tenant, rent, and duration'),
              onTap: () => Navigator.pop(context, 'lease'),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class UploadDocumentSheet extends StatefulWidget {
  final int propertyId;
  final int? unitId;
  final int? tenantId;
  final int? tenancyId;

  const UploadDocumentSheet({
    super.key,
    required this.propertyId,
    this.unitId,
    this.tenantId,
    this.tenancyId,
  });

  @override
  State<UploadDocumentSheet> createState() => _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends State<UploadDocumentSheet> {
  final ApiService _api = ApiService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _type = _kCategoryOther;
  PlatformFile? _file;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    setState(() {
      _file = picked;
      if (_titleController.text.isEmpty) {
        _titleController.text = picked.name.replaceAll(RegExp(r'\.[^.]+$'), '');
      }
    });
  }

  Future<void> _submit() async {
    if (_file == null || _file!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a file first')),
      );
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title for this document')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final mime = _mimeFromExtension(_file!.extension);
      final streamed = await _api.uploadMultipart(
        '/documents/upload',
        fileBytes: _file!.bytes!,
        fileName: _file!.name,
        fieldName: 'file',
        mimeType: mime,
        fields: {
          'property_id': widget.propertyId.toString(),
          if (widget.unitId != null) 'unit_id': widget.unitId.toString(),
          if (widget.tenantId != null) 'tenant_id': widget.tenantId.toString(),
          if (widget.tenancyId != null)
            'tenancy_id': widget.tenancyId.toString(),
          'type': _type,
          'title': _titleController.text.trim(),
          if (_descriptionController.text.trim().isNotEmpty)
            'description': _descriptionController.text.trim(),
        },
      );
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode >= 400) {
        final msg = _parseError(body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        setState(() => _submitting = false);
        return;
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Document',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.textDark)),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: _kCategoryLease, child: Text('Lease')),
                DropdownMenuItem(value: _kCategoryReceipt, child: Text('Receipt')),
                DropdownMenuItem(value: _kCategoryAgreement, child: Text('Agreement')),
                DropdownMenuItem(value: _kCategoryOther, child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _type = value ?? _kCategoryOther),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _submitting ? null : _pickFile,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(_file == null ? 'Pick file (PDF or image)' : _file!.name),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(_submitting ? 'Uploading...' : 'Upload Document'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GenerateLeaseSheet extends StatefulWidget {
  final int propertyId;
  const GenerateLeaseSheet({super.key, required this.propertyId});

  @override
  State<GenerateLeaseSheet> createState() => _GenerateLeaseSheetState();
}

class _GenerateLeaseSheetState extends State<GenerateLeaseSheet> {
  final ApiService _api = ApiService();
  final TextEditingController _clausesController = TextEditingController();
  Future<List<_TenancyOption>>? _tenanciesFuture;
  _TenancyOption? _selected;
  DateTime? _endDate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tenanciesFuture = _loadTenancies();
  }

  @override
  void dispose() {
    _clausesController.dispose();
    super.dispose();
  }

  Future<List<_TenancyOption>> _loadTenancies() async {
    final response = await _api.get('/tenancies',
        query: {'propertyId': widget.propertyId});
    if (response.statusCode != 200) {
      throw Exception('Could not load tenancies (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => _TenancyOption.fromJson(item as Map<String, dynamic>))
        .where((tenancy) => tenancy.status == 'active')
        .toList();
  }

  Future<void> _submit() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a tenancy first')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final clauses = _clausesController.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      final response = await _api.post('/documents/generate-lease', {
        'tenancy_id': _selected!.id,
        'terms': {
          if (_endDate != null)
            'end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
          if (clauses.isNotEmpty) 'clauses': clauses,
        },
      });

      if (response.statusCode >= 400) {
        final msg = _parseError(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        setState(() => _submitting = false);
        return;
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate lease: $e')),
      );
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Generate Lease',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.textDark)),
            const SizedBox(height: 18),
            FutureBuilder<List<_TenancyOption>>(
              future: _tenanciesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text(snapshot.error.toString(),
                      style: const TextStyle(color: AppColors.danger));
                }
                final tenancies = snapshot.data ?? const [];
                if (tenancies.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No active tenancies for this property yet. Add a tenant first.',
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  );
                }
                return DropdownButtonFormField<_TenancyOption>(
                  value: _selected,
                  decoration: const InputDecoration(labelText: 'Tenancy'),
                  isExpanded: true,
                  items: tenancies
                      .map((tenancy) => DropdownMenuItem(
                            value: tenancy,
                            child: Text(
                              '${tenancy.tenantName} • Unit ${tenancy.unitNumber}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selected = value),
                );
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ??
                      DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'End date (optional)'),
                child: Text(
                  _endDate == null
                      ? 'Pick an end date'
                      : DateFormat('d MMM yyyy').format(_endDate!),
                  style: TextStyle(
                    color: _endDate == null
                        ? AppColors.textLight
                        : AppColors.textDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _clausesController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Custom clauses (one per line, optional)',
                hintText: 'Leave empty to use standard KodiPay terms',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(_submitting ? 'Generating...' : 'Generate Lease PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentDetailScreen extends StatefulWidget {
  final DocumentItem document;
  const DocumentDetailScreen({super.key, required this.document});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final ApiService _api = ApiService();
  bool _deleting = false;

  void _openInNewTab() {
    html.window.open(widget.document.fileUrl, '_blank');
  }

  Future<void> _share() async {
    final df = DateFormat('d MMM yyyy');
    final text = '${widget.document.title} (${_categoryLabel(widget.document.type)})\n'
        '${df.format(widget.document.createdAt)}\n'
        '${widget.document.fileUrl}';
    await Share.share(text, subject: widget.document.title);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: const Text(
            'This will remove the document from KodiPay. The file in storage is kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      final response = await _api.delete('/documents/${widget.document.id}');
      if (response.statusCode >= 400) {
        final msg = _parseError(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        setState(() => _deleting = false);
        return;
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
      setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final color = _colorForType(doc.type);
    final df = DateFormat('d MMM yyyy, h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(_iconForType(doc.type), color: color, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_categoryLabel(doc.type)} • ${df.format(doc.createdAt)}',
                              style: AppStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (doc.description != null && doc.description!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(doc.description!, style: AppStyles.bodyMedium),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _MetaCard(items: [
              if (doc.propertyName != null)
                _MetaItem('Property', doc.propertyName!),
              if (doc.unitNumber != null) _MetaItem('Unit', doc.unitNumber!),
              if (doc.tenantName != null) _MetaItem('Tenant', doc.tenantName!),
              if (doc.startsOn != null)
                _MetaItem('Starts on', DateFormat('d MMM yyyy').format(doc.startsOn!)),
              if (doc.expiresOn != null)
                _MetaItem('Expires on', DateFormat('d MMM yyyy').format(doc.expiresOn!)),
              if (doc.metadata['amount'] != null)
                _MetaItem('Amount', 'KSh ${doc.metadata['amount']}'),
              if (doc.metadata['transaction_ref'] != null)
                _MetaItem('Reference', doc.metadata['transaction_ref'].toString()),
              if (doc.metadata['method'] != null)
                _MetaItem('Method', doc.metadata['method'].toString()),
            ]),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openInNewTab,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _deleting ? null : _delete,
                icon: _deleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded,
                        color: AppColors.danger),
                label: Text(
                  _deleting ? 'Deleting...' : 'Delete document',
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaItem {
  final String label;
  final String value;
  const _MetaItem(this.label, this.value);
}

class _MetaCard extends StatelessWidget {
  final List<_MetaItem> items;
  const _MetaCard({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 16, color: AppColors.border),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(items[i].label,
                      style: AppStyles.caption),
                ),
                Expanded(
                  flex: 3,
                  child: Text(items[i].value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyDocumentsState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyDocumentsState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.folder_open_rounded,
            size: 72, color: AppColors.muted),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'No documents yet',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Upload leases, receipts, or generate a lease from a tenancy.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Document'),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.error_outline_rounded,
            size: 56, color: AppColors.danger),
        const SizedBox(height: 14),
        Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: AppStyles.bodyMedium),
        ),
        const SizedBox(height: 14),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

class _TenancyOption {
  final int id;
  final String tenantName;
  final String unitNumber;
  final String status;

  const _TenancyOption({
    required this.id,
    required this.tenantName,
    required this.unitNumber,
    required this.status,
  });

  factory _TenancyOption.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name'] ?? '';
    final lastName = json['last_name'] ?? '';
    return _TenancyOption(
      id: json['id'] as int,
      tenantName: '$firstName $lastName'.trim(),
      unitNumber: (json['unit_number'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
    );
  }
}

String _mimeFromExtension(String? ext) {
  switch (ext?.toLowerCase()) {
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'webp':
      return 'image/webp';
    default:
      return 'application/octet-stream';
  }
}

String _parseError(String body) {
  try {
    final data = jsonDecode(body);
    if (data is Map && data['error'] is String) return data['error'] as String;
  } catch (_) {}
  return 'Request failed';
}
