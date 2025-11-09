import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_streaming_text_markdown/flutter_streaming_text_markdown.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// AdaptiveMarkdownMessage
/// Renders streaming markdown for in-progress messages, and rich selectable markdown for finalized ones.
/// Supports code block copy, LaTeX, and quick replies.
class AdaptiveMarkdownMessage extends StatelessWidget {
  final String text;
  final bool isStreaming;
  final bool selectable;
  final List<String>? quickReplies;
  final void Function(String)? onQuickReply;
  final bool isSystem;
  final Color? backgroundColor;

  const AdaptiveMarkdownMessage({
    super.key,
    required this.text,
    this.isStreaming = false,
    this.selectable = false,
    this.quickReplies,
    this.onQuickReply,
    this.isSystem = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ??
        (isSystem
            ? theme.colorScheme.surfaceVariant
            : theme.colorScheme.surface);
    final border = isSystem
        ? Border.all(color: theme.colorScheme.primary.withOpacity(0.2))
        : null;
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: border,
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isStreaming)
            StreamingTextMarkdown(
              data: text,
              selectable: selectable,
              codeBlockBuilder: (context, code, language) =>
                  _CodeBlockWithCopy(code: code, language: language),
              onTapLink: (text, href) => _launchUrl(context, href),
              style: theme.textTheme.bodyMedium,
            )
          else
            GptMarkdown(
              text,
              selectable: selectable,
              codeBlockBuilder: (context, code, language) =>
                  _CodeBlockWithCopy(code: code, language: language),
              onTapLink: (text, href) => _launchUrl(context, href),
            ),
          if (quickReplies != null && quickReplies!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8,
                children: quickReplies!
                    .map((reply) => ActionChip(
                          label: Text(reply),
                          onPressed: () => onQuickReply?.call(reply),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _launchUrl(BuildContext context, String? url) {
    if (url == null) return;
    // TODO: Integrate with url_launcher or custom link handler
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open link: $url')),
    );
  }
}

class _CodeBlockWithCopy extends StatelessWidget {
  final String code;
  final String? language;
  const _CodeBlockWithCopy({required this.code, this.language});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
            tooltip: 'Copy code',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied!')),
              );
            },
          ),
        ),
      ],
    );
  }
}
