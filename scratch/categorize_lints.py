
import re
from collections import Counter

report_path = r'c:\my projects\all-in-one-agricaltural-app\final_analysis_report.txt'

with open(report_path, 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# Pattern to match the rule name at the end of each line
# e.g., "... - file_names"
rule_pattern = re.compile(r' - ([a-z_]+)$', re.MULTILINE)
rules = rule_pattern.findall(content)

counter = Counter(rules)
print("Count | Rule Name")
print("-" * 25)
for rule, count in counter.most_common():
    print(f"{count:5} | {rule}")
