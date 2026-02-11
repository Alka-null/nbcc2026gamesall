import re

path = r'c:\Users\HomePC\Desktop\AK\Projects\MyPersonal\NBCCStrategyGames\flutter_apps\jigsaw_puzzle_game\lib\main.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Fix double-encoded right single quotation mark: â€™ -> ' (U+2019)
text = text.replace('\u00e2\u20ac\u2122', '\u2019')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

# Verify
with open(path, 'r', encoding='utf-8') as f:
    text2 = f.read()

print('Has right quote:', '\u2019' in text2)
for m in re.finditer(r'up!', text2):
    start = max(0, m.start()-15)
    segment = text2[start:m.end()+5]
    print(f'Time check: {repr(segment)}')
print('Lines:', text2.count(chr(10)) + 1)

# Check no more garbled chars (chars in U+0080 to U+00FF that shouldn't be there)
suspect = set()
for c in text2:
    if 0x80 <= ord(c) <= 0xFF:
        suspect.add(f'U+{ord(c):04X} ({c!r})')
if suspect:
    print('Suspect chars:', suspect)
else:
    print('No suspect chars - file looks clean')
print('Done')
