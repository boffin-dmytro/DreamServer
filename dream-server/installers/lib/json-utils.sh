#!/bin/bash
# ============================================================================
# Dream Server Installer — JSON/YAML Utilities
# ============================================================================
# Part of: installers/lib/
# Purpose: Safe JSON/YAML parsing with error handling
#
# Expects: (nothing — can be sourced independently)
# Provides: safe_json_parse(), safe_yaml_parse(), validate_json_file()
#
# Modder notes:
#   Add new parsing utilities here.
# ============================================================================

# Safely parse JSON with error handling
# Usage: safe_json_parse <json_string> [jq_filter]
# Returns: 0 on success, 1 on parse error
safe_json_parse() {
    local json_string="$1"
    local jq_filter="${2:-.}"
    
    if [[ -z "$json_string" ]]; then
        echo "ERROR: Empty JSON string" >&2
        return 1
    fi
    
    # Try to parse with jq
    if command -v jq &>/dev/null; then
        echo "$json_string" | jq -e "$jq_filter" 2>/dev/null
        return $?
    fi
    
    # Fallback to Python
    python3 - "$json_string" "$jq_filter" <<'PY' 2>/dev/null
import json
import sys

try:
    data = json.loads(sys.argv[1])
    filter_expr = sys.argv[2]
    
    # Simple filter support (just key access for now)
    if filter_expr != ".":
        keys = filter_expr.strip(".").split(".")
        for key in keys:
            if key:
                data = data.get(key, None)
                if data is None:
                    sys.exit(1)
    
    print(json.dumps(data) if isinstance(data, (dict, list)) else data)
    sys.exit(0)
except (json.JSONDecodeError, KeyError, TypeError) as e:
    print(f"JSON parse error: {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# Validate a JSON file
# Usage: validate_json_file <file_path>
# Returns: 0 if valid, 1 if invalid
validate_json_file() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        echo "ERROR: File not found: $file_path" >&2
        return 1
    fi
    
    if command -v jq &>/dev/null; then
        jq empty "$file_path" 2>/dev/null
        return $?
    fi
    
    # Fallback to Python
    python3 - "$file_path" <<'PY' 2>/dev/null
import json
import sys
from pathlib import Path

try:
    data = json.loads(Path(sys.argv[1]).read_text())
    sys.exit(0)
except (json.JSONDecodeError, FileNotFoundError) as e:
    print(f"JSON validation error: {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# Safely parse YAML with error handling
# Usage: safe_yaml_parse <yaml_file>
# Returns: 0 on success, 1 on parse error
safe_yaml_parse() {
    local yaml_file="$1"
    
    if [[ ! -f "$yaml_file" ]]; then
        echo "ERROR: File not found: $yaml_file" >&2
        return 1
    fi
    
    python3 - "$yaml_file" <<'PY' 2>/dev/null
import sys
from pathlib import Path

try:
    import yaml
    data = yaml.safe_load(Path(sys.argv[1]).read_text())
    import json
    print(json.dumps(data))
    sys.exit(0)
except ImportError:
    print("ERROR: PyYAML not available", file=sys.stderr)
    sys.exit(1)
except yaml.YAMLError as e:
    print(f"YAML parse error: {e}", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# Get a value from JSON file with error handling
# Usage: json_get <file_path> <key_path>
# Example: json_get config.json ".database.host"
json_get() {
    local file_path="$1"
    local key_path="$2"
    
    if [[ ! -f "$file_path" ]]; then
        echo "ERROR: File not found: $file_path" >&2
        return 1
    fi
    
    if command -v jq &>/dev/null; then
        jq -r "$key_path" "$file_path" 2>/dev/null || return 1
    else
        python3 - "$file_path" "$key_path" <<'PY' 2>/dev/null
import json
import sys
from pathlib import Path

try:
    data = json.loads(Path(sys.argv[1]).read_text())
    keys = sys.argv[2].strip(".").split(".")
    
    for key in keys:
        if key:
            data = data.get(key, None)
            if data is None:
                sys.exit(1)
    
    print(data)
    sys.exit(0)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PY
    fi
}
