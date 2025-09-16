#!/usr/bin/env python3
"""
Simple syntax checker for Flutter/Dart files
"""
import re
import os

def check_flutter_file_syntax(file_path):
    """Check basic Flutter/Dart syntax issues"""
    issues = []
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
            lines = content.split('\n')
    except Exception as e:
        return [f"Error reading file: {e}"]
    
    # Check for common syntax issues
    bracket_stack = []
    paren_stack = []
    brace_stack = []
    
    for i, line in enumerate(lines, 1):
        line = line.strip()
        
        # Skip comments and empty lines
        if not line or line.startswith('//'):
            continue
            
        # Count brackets, parentheses, and braces
        for char in line:
            if char == '(':
                paren_stack.append(i)
            elif char == ')':
                if paren_stack:
                    paren_stack.pop()
                else:
                    issues.append(f"Line {i}: Unmatched closing parenthesis")
            elif char == '[':
                bracket_stack.append(i)
            elif char == ']':
                if bracket_stack:
                    bracket_stack.pop()
                else:
                    issues.append(f"Line {i}: Unmatched closing bracket")
            elif char == '{':
                brace_stack.append(i)
            elif char == '}':
                if brace_stack:
                    brace_stack.pop()
                else:
                    issues.append(f"Line {i}: Unmatched closing brace")
    
    # Check for unmatched opening symbols
    if paren_stack:
        issues.append(f"Unmatched opening parentheses at lines: {paren_stack}")
    if bracket_stack:
        issues.append(f"Unmatched opening brackets at lines: {bracket_stack}")
    if brace_stack:
        issues.append(f"Unmatched opening braces at lines: {brace_stack}")
    
    # Check for other common issues
    if 'Consumer<TweetProvider>' in content and 'return Consumer<TweetProvider>' not in content:
        if content.count('Consumer<TweetProvider>') != content.count('});'):
            issues.append("Consumer widget may not be properly closed")
    
    return issues

def main():
    flutter_files = [
        '/app/lib/screens/tweet/tweet_detail_screen.dart',
        '/app/lib/providers/tweet_provider.dart',
        '/app/lib/widgets/reply_tweet_card.dart'
    ]
    
    all_issues = []
    
    for file_path in flutter_files:
        if os.path.exists(file_path):
            print(f"\nChecking: {file_path}")
            issues = check_flutter_file_syntax(file_path)
            if issues:
                print(f"Issues found:")
                for issue in issues:
                    print(f"  - {issue}")
                    all_issues.append(f"{file_path}: {issue}")
            else:
                print("  ✓ No obvious syntax issues found")
        else:
            print(f"File not found: {file_path}")
    
    if not all_issues:
        print("\n✅ All files passed basic syntax checks!")
        return True
    else:
        print(f"\n❌ Found {len(all_issues)} potential issues")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)