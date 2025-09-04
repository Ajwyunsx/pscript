"""
Built-in functions and types for PyScript
This module provides essential Python built-in functions.
"""

# Print function
def print(*args, sep=' ', end='\n'):
    """Print objects to the text stream"""
    text = sep.join(str(arg) for arg in args) + end
    # This will be handled by PyScript's print callback
    return text

# Type conversion functions
def int(x=0, base=10):
    """Convert to integer"""
    if isinstance(x, str):
        return int(x, base)
    return int(x)

def float(x=0.0):
    """Convert to float"""
    return float(x)

def str(x=''):
    """Convert to string"""
    return str(x)

def bool(x=False):
    """Convert to boolean"""
    return bool(x)

def list(x=None):
    """Convert to list"""
    if x is None:
        return []
    return list(x)

def dict(x=None):
    """Convert to dictionary"""
    if x is None:
        return {}
    return dict(x)

def tuple(x=None):
    """Convert to tuple"""
    if x is None:
        return ()
    return tuple(x)

def set(x=None):
    """Convert to set"""
    if x is None:
        return set()
    return set(x)

# Input/Output functions
def input(prompt=''):
    """Read a string from standard input"""
    # This will be handled by PyScript's input callback
    return input(prompt)

# Object introspection
def type(obj):
    """Return the type of an object"""
    return type(obj)

def isinstance(obj, classinfo):
    """Check if object is instance of class"""
    return isinstance(obj, classinfo)

def hasattr(obj, name):
    """Check if object has attribute"""
    return hasattr(obj, name)

def getattr(obj, name, default=None):
    """Get attribute of object"""
    return getattr(obj, name, default)

def setattr(obj, name, value):
    """Set attribute of object"""
    return setattr(obj, name, value)

def dir(obj=None):
    """List attributes of object"""
    if obj is None:
        return list(globals().keys())
    return dir(obj)

# Length and iteration
def len(obj):
    """Return length of object"""
    return len(obj)

def iter(obj):
    """Return iterator object"""
    return iter(obj)

def next(iterator, default=None):
    """Get next item from iterator"""
    return next(iterator, default)

# Mathematical operations
def abs(x):
    """Absolute value"""
    return abs(x)

def min(*args, key=None):
    """Minimum value"""
    return min(*args, key=key)

def max(*args, key=None):
    """Maximum value"""
    return max(*args, key=key)

def sum(iterable, start=0):
    """Sum of items"""
    return sum(iterable, start)

# Range function
def range(start, stop=None, step=1):
    """Generate range of numbers"""
    if stop is None:
        stop = start
        start = 0
    return range(start, stop, step)

# Other utilities
def enumerate(iterable, start=0):
    """Enumerate items"""
    return enumerate(iterable, start)

def zip(*iterables):
    """Zip iterables together"""
    return zip(*iterables)

def reversed(seq):
    """Reverse sequence"""
    return reversed(seq)

def sorted(iterable, key=None, reverse=False):
    """Return sorted list"""
    return sorted(iterable, key=key, reverse=reverse)

# Execution and evaluation
def eval(expression, globals=None, locals=None):
    """Evaluate expression"""
    return eval(expression, globals, locals)

def exec(code, globals=None, locals=None):
    """Execute code"""
    return exec(code, globals, locals)

# Hash function
def hash(obj):
    """Return hash of object"""
    return hash(obj)

# Help function
def help(obj=None):
    """Show help for object"""
    # This will be handled by PyScript's help system
    return help(obj)

# Open function (simplified)
def open(file, mode='r', encoding=None):
    """Open file"""
    # This will be handled by PyScript's file system
    return open(file, mode, encoding)