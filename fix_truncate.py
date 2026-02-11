path = r'c:\Users\HomePC\Desktop\AK\Projects\MyPersonal\NBCCStrategyGames\flutter_apps\jigsaw_puzzle_game\lib\main.dart'
with open(path, 'r', encoding='utf-8-sig') as f:
    lines = f.readlines()

# Find the line "}\n" that closes the class after the new build method
# The new code ends with "  }\n}\n" (closing build method + closing class)
# Find the FIRST occurrence of the pattern "  }\n}\n" after line 1200
found_idx = None
for i in range(1200, len(lines)):
    if lines[i].rstrip() == '}' and i > 0 and lines[i-1].rstrip() == '  }':
        found_idx = i
        break

if found_idx is not None:
    print(f'Found class closing at line {found_idx + 1}')
    # Keep lines 0..found_idx (inclusive)
    trimmed = lines[:found_idx + 1]
    # Make sure last line ends with newline
    if not trimmed[-1].endswith('\n'):
        trimmed[-1] = trimmed[-1] + '\n'
    with open(path, 'w', encoding='utf-8') as f:
        f.writelines(trimmed)
    print(f'Trimmed to {len(trimmed)} lines')
else:
    print('Could not find class closing pattern')
    # Print lines around 1230 for debugging
    for i in range(1225, min(1240, len(lines))):
        print(f'{i+1}: {lines[i].rstrip()!r}')
