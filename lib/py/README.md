# Python Standard Library Modules for PyScript

This directory contains Python standard library modules that can be used with PyScript.

## Structure

- `__init__.py` - Package initialization
- `builtins.py` - Built-in functions and types
- `math.py` - Mathematical functions
- `random.py` - Random number generation
- `time.py` - Time-related functions
- `datetime.py` - Date and time handling
- `json.py` - JSON encoding/decoding
- `os.py` - Operating system interface
- `sys.py` - System-specific parameters
- `re.py` - Regular expressions
- `collections.py` - Specialized container datatypes
- `itertools.py` - Functions creating iterators
- `functools.py` - Higher-order functions and operations

## Usage

These modules will be automatically available when using PyScript with Lime projects.

```python
import math
import random
import json

# Use standard library functions
print(math.pi)
print(random.randint(1, 10))
data = json.dumps({"key": "value"})
```