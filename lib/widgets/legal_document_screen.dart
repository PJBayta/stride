import 'package:flutter/material.dart';

import '../core/legal/legal_documents.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(document.title), centerTitle: true),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
          children: [
            Text(
              document.title,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            for (final paragraph in document.paragraphs) ...[
              Text(
                paragraph,
                style: text.bodyLarge?.copyWith(height: 1.55),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
