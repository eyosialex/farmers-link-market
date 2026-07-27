import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/Advisor%20View/advice_model.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdviceFeedScreen extends StatelessWidget {
  const AdviceFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.expertAdviceTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('advice_posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("${l10n.errorTitle}: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.article_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text(l10n.noAdvice, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final advice = AdviceModel.fromFirestore(doc);
              return _buildAdviceCard(context, advice);
            },
          );
        },
      ),
    );
  }

  Widget _buildAdviceCard(BuildContext context, AdviceModel advice) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category and Author
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green[50], // Light green header
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(advice.category),
                  backgroundColor: Colors.green[100],
                  labelStyle: TextStyle(color: Colors.green[800], fontSize: 12),
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  l10n.byAuthor(advice.authorName),
                  style: TextStyle(color: Colors.grey[700], fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  advice.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Content Preview (truncating if too long)
                Text(
                  advice.content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
                ),
                const SizedBox(height: 12),

                // Footer: Date and "Read More"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(advice.timestamp),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                             _showAdviceDetails(context, advice);
                          },
                          child: Text(l10n.readMore),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAdviceDetails(BuildContext context, AdviceModel advice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Full screen height allowed
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (modalContext, scrollController) {
          final l10n = AppLocalizations.of(modalContext)!;
          final locale = Localizations.localeOf(modalContext);
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  advice.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green[100],
                      radius: 16,
                      child: const Icon(Icons.person, size: 20, color: Colors.green),
                    ),
                    const SizedBox(width: 8),
                    Text(advice.authorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text("•", style: TextStyle(color: Colors.grey[400])),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat.yMMMd(locale.toString()).format(advice.timestamp),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                
                Text(
                  advice.content,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(l10n.gotIt),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
