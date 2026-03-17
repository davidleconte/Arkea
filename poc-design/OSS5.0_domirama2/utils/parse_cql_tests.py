#!/usr/bin/env python3
"""
Parse CQL test file and extract individual tests with their descriptions and queries.
"""

import json
import re
import sys


def parse_cql_tests(cql_file_path, code_si, contrat):
    """
    Parse a CQL test file and extract individual tests.

    Args:
        cql_file_path: Path to the CQL file
        code_si: Code SI to replace in queries
        contrat: Contrat to replace in queries

    Returns:
        List of test dictionaries with description, expected, and query
    """
    tests = []

    with open(cql_file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Pattern to match test sections
    # Format: -- Test X : Description
    #         -- Additional comments
    #         SELECT ...
    test_pattern = r"--\s*={3,}\s*\n--\s*Test\s+(\d+)\s*:\s*(.+?)\s*\n--\s*={3,}\s*\n(.*?)(?=SELECT)SELECT\s+(.*?)(?=\n--\s*={3,}|\Z)"

    matches = re.finditer(test_pattern, content, re.DOTALL | re.MULTILINE)

    for match in matches:
        test_num = int(match.group(1))
        test_title = match.group(2).strip()
        comments = match.group(3).strip()
        query_body = match.group(4).strip()

        # Reconstruct full SELECT query
        query = f"SELECT {query_body}"

        # Extract expected result from comments
        expected = ""
        if "Trouve" in comments or "trouve" in comments:
            expected_match = re.search(r'(?:Trouve|trouve)\s+["\']?([^"\']+)["\']?', comments)
            if expected_match:
                expected = expected_match.group(1)
        elif "Pour" in comments:
            expected = comments.split("\n")[0].replace("--", "").strip()
        else:
            # Use first meaningful line of comments
            for line in comments.split("\n"):
                line = line.replace("--", "").strip()
                if line and len(line) > 10:
                    expected = line
                    break

        # Replace placeholders in query
        query = query.replace("code_si = '1'", f"code_si = '{code_si}'")
        query = query.replace("code_si = '01'", f"code_si = '{code_si}'")
        query = query.replace("contrat = '5913101072'", f"contrat = '{contrat}'")
        query = query.replace("contrat = '1234567890'", f"contrat = '{contrat}'")

        # Clean up query (remove trailing semicolon if present, we'll add it)
        query = query.rstrip(";").strip()

        tests.append(
            {
                "test_number": test_num,
                "title": test_title,
                "description": comments.replace("--", "").strip(),
                "expected": expected,
                "query": query,
            }
        )

    return tests


if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: parse_cql_tests.py <cql_file> <code_si> <contrat>", file=sys.stderr)
        sys.exit(1)

    cql_file = sys.argv[1]
    code_si = sys.argv[2]
    contrat = sys.argv[3]

    try:
        tests = parse_cql_tests(cql_file, code_si, contrat)
        print(json.dumps(tests, indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"Error parsing CQL file: {e}", file=sys.stderr)
        sys.exit(1)
