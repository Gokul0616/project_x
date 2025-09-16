import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../utils/app_theme.dart';
import '../screens/search/search_screen.dart';

class RichTweetText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool isClickable;
  final int? maxLines;
  final TextOverflow? overflow;

  const RichTweetText({
    super.key,
    required this.text,
    this.style,
    this.isClickable = true,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: buildTextSpan(
        context: context,
        text: text,
        style: style,
        isClickable: isClickable,
      ),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }

  static TextSpan buildTextSpan({
    required BuildContext context,
    required String text,
    TextStyle? style,
    bool isClickable = true,
  }) {
    final List<TextSpan> spans = [];
    final RegExp regex = RegExp(r'(#\w+|@\w+)');

    int lastEnd = 0;

    for (final Match match in regex.allMatches(text)) {
      // Add text before the match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: style ??
              TextStyle(
                fontSize: 14, // Match TweetCard's Twitter-like font size
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.3,
              ),
        ));
      }

      final String matchedText = match.group(0)!;
      final bool isHashtag = matchedText.startsWith('#');
      final bool isMention = matchedText.startsWith('@');

      // Add the highlighted hashtag or mention
      spans.add(TextSpan(
        text: matchedText,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.twitterBlue,
          fontWeight: FontWeight.w500,
        ),
        recognizer: isClickable
            ? (TapGestureRecognizer()
              ..onTap = () {
                if (isHashtag || isMention) {
                  _handleTap(context, matchedText);
                }
              })
            : null,
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: style ??
            TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              height: 1.3,
            ),
      ));
    }

    // If no hashtags or mentions found, return the original text
    if (spans.isEmpty) {
      return TextSpan(
        text: text,
        style: style ??
            TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              height: 1.3,
            ),
      );
    }

    return TextSpan(children: spans);
  }

  static void _handleTap(BuildContext context, String text) {
    // Navigate to search screen with the hashtag or mention as initial query
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(initialQuery: text),
      ),
    );
  }
}