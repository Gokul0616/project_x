#!/usr/bin/env python3

import re

def validate_dart_brackets(file_path):
    """Basic validation of bracket matching in Dart file"""
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Remove comments and strings to avoid false positives
    content = re.sub(r'//.*$', '', content, flags=re.MULTILINE)
    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
    content = re.sub(r'"(?:[^"\\]|\\.)*"', '', content)
    content = re.sub(r"'(?:[^'\\]|\\.)*'", '', content)
    
    # Count brackets
    brackets = {'(': 0, '[': 0, '{': 0}
    closing = {')': '(', ']': '[', '}': '{'}
    
    for char in content:
        if char in brackets:
            brackets[char] += 1
        elif char in closing:
            opening = closing[char]
            brackets[opening] -= 1
            if brackets[opening] < 0:
                return False, f"Unmatched closing {char}"
    
    # Check if all brackets are matched
    for bracket, count in brackets.items():
        if count != 0:
            return False, f"Unmatched {bracket}: {count} extra"
    
    return True, "Brackets are properly matched"

def check_class_definitions(file_path):
    """Check for duplicate class definitions"""
    with open(file_path, 'r') as f:
        content = f.read()
    
    class_pattern = r'class\s+(\w+)\s*(?:extends|implements|with|\{)'
    classes = re.findall(class_pattern, content)
    
    seen_classes = set()
    duplicates = []
    
    for class_name in classes:
        if class_name in seen_classes:
            duplicates.append(class_name)
        else:
            seen_classes.add(class_name)
    
    if duplicates:
        return False, f"Duplicate class definitions: {', '.join(duplicates)}"
    
    return True, f"Found classes: {', '.join(seen_classes)}"

if __name__ == "__main__":
    file_path = "/app/lib/widgets/tweet_card.dart"
    
    print("Validating brackets...")
    is_valid, message = validate_dart_brackets(file_path)
    print(f"Brackets: {'✓' if is_valid else '✗'} {message}")
    
    print("\nValidating class definitions...")
    is_valid, message = check_class_definitions(file_path)
    print(f"Classes: {'✓' if is_valid else '✗'} {message}")