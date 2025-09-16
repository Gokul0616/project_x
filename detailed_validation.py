#!/usr/bin/env python3

import re

def detailed_bracket_analysis(file_path):
    """Detailed analysis of bracket matching with line numbers"""
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    # Stack to track opening brackets
    stack = []
    bracket_pairs = {'(': ')', '[': ']', '{': '}'}
    
    for line_num, line in enumerate(lines, 1):
        # Skip comments
        line_clean = re.sub(r'//.*$', '', line)
        line_clean = re.sub(r'/\*.*?\*/', '', line_clean)
        
        for char_pos, char in enumerate(line_clean):
            if char in bracket_pairs:
                # Opening bracket
                stack.append((char, line_num, char_pos))
            elif char in bracket_pairs.values():
                # Closing bracket
                if not stack:
                    print(f"ERROR: Unmatched closing '{char}' at line {line_num}:{char_pos}")
                    continue
                
                opening_char, opening_line, opening_pos = stack.pop()
                expected_closing = bracket_pairs[opening_char]
                
                if char != expected_closing:
                    print(f"ERROR: Mismatched bracket at line {line_num}:{char_pos}")
                    print(f"  Found: '{char}', Expected: '{expected_closing}'")
                    print(f"  Opening '{opening_char}' was at line {opening_line}:{opening_pos}")
    
    # Check for unmatched opening brackets
    if stack:
        print(f"ERROR: {len(stack)} unmatched opening brackets:")
        for char, line_num, char_pos in stack:
            print(f"  '{char}' at line {line_num}:{char_pos}")
            print(f"    Content: {lines[line_num-1].strip()}")
    else:
        print("SUCCESS: All brackets are properly matched!")

if __name__ == "__main__":
    detailed_bracket_analysis("/app/lib/widgets/tweet_card.dart")