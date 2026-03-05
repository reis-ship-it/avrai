import re
import os

def fix_file(filepath, issues):
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    modified = False
    
    for issue in issues:
        line_idx = issue['line'] - 1
        error = issue['error']
        
        if line_idx >= len(lines):
            continue
            
        line = lines[line_idx]
        new_line = line
        
        if error == 'withOpacity':
            new_line = new_line.replace('.withOpacity(', '.withValues(alpha: ')
        elif error == 'value':
            new_line = re.sub(r'\.value(?!\w)', r'.toARGB32()', new_line)
        elif error == 'activeColor':
            new_line = re.sub(r'\bactiveColor\b', 'activeThumbColor', new_line)
        elif error == 'GooglePlaceIdFinderService':
            new_line = re.sub(r'\bGooglePlaceIdFinderService\b', 'GooglePlaceIdFinderServiceNew', new_line)
                
        if new_line != line:
            lines[line_idx] = new_line
            modified = True
                
    if modified:
        with open(filepath, 'w') as f:
            f.writelines(lines)
        print(f"Fixed {filepath}")

def main():
    file_issues = {}
    
    with open('analyzer_output.txt', 'r') as f:
        for line in f:
            line = line.strip()
            match = re.search(r'(?:info|warning|error)\s+-\s+(.*?):(\d+):(\d+)\s+-\s+(.*)', line)
            if match:
                filepath = match.group(1).strip()
                line_num = int(match.group(2))
                col_num = int(match.group(3))
                msg = match.group(4)
                
                error_type = None
                if "'withOpacity' is deprecated" in msg:
                    error_type = 'withOpacity'
                elif "'value' is deprecated" in msg:
                    error_type = 'value'
                elif "'activeColor' is deprecated" in msg:
                    error_type = 'activeColor'
                elif "'GooglePlaceIdFinderService' is deprecated" in msg:
                    error_type = 'GooglePlaceIdFinderService'
                    
                if error_type:
                    if filepath not in file_issues:
                        file_issues[filepath] = []
                    file_issues[filepath].append({
                        'line': line_num,
                        'col': col_num,
                        'error': error_type
                    })
                    
    for filepath, issues in file_issues.items():
        if os.path.exists(filepath):
            fix_file(filepath, issues)
        else:
            print(f"File not found: {filepath}")
            
if __name__ == '__main__':
    main()
