import 'package:chennai_assist/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('paragraphs, headings and bullet lists are recognised like on the website', () {
    final blocks = parseProse('''
How renting works
Landlords ask for a big advance. Negotiate it.

Rough rent ranges (2026)
- 1 BHK: Rs 10k to 22k
- 2 BHK: Rs 16k to 40k

Just one line.
''');

    expect(blocks[0], isA<ProseHeading>().having((b) => b.text, 'text', 'How renting works'));
    expect((blocks[0] as ProseHeading).rest, startsWith('Landlords ask'));
    expect(blocks[1], isA<ProseHeading>().having((b) => b.rest, 'rest', ''));
    expect(blocks[2], isA<ProseList>().having((b) => b.items, 'items', ['1 BHK: Rs 10k to 22k', '2 BHK: Rs 16k to 40k']));
    expect(blocks[3], isA<ProsePara>().having((b) => b.text, 'text', 'Just one line.'));
  });

  test('a long first line is a paragraph, not a heading', () {
    final blocks = parseProse('This first line is clearly much longer than sixty characters in total\nand continues');
    expect(blocks.single, isA<ProsePara>());
  });
}
