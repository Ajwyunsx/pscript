# pythonScript - Python Syntax Interpreter for Haxe

pythonScript is a Python syntax interpreter written in Haxe that supports intelligent Haxe module imports, complete Python class system, and function support.

## Core Features

### Smart Module Import System
- **Standard Python syntax**: `import ModuleName`
- **Intelligent type detection**: 
  - `Math` (uppercase) → Haxe module
  - `math` (lowercase) → Python module
  - `haxe.Math` → detects last part `Math` (uppercase) → Haxe module
  - `os.path` → detects last part `path` (lowercase) → Python module

### Complete Python Class System
- Class definition: `class ClassName:`
- Constructor: `__init__(self, ...)`
- Instance methods: `def method(self, params):`
- Property assignment: `self.property = value`
- Method calls: `instance.method()`

### 🔧 Parent Object Support
- Create interpreter with parent: `new Interpreter(parentObj)`
- Dynamic parent access and modification: `interpreter.parent`

## Quick Start

### 1. Basic Usage

```haxe
import pyscript.Interpreter;

class Main {
    public static function main() {
        var interpreter = new Interpreter();
        
        // Execute Python code
        interpreter.run("print('Hello, PyScript!')");
    }
}
```

### 2. Haxe Module Import

```python
# Import Haxe Math module
import Math
print('π =', Math.PI)
print('sqrt(16) =', Math.sqrt(16))

# Import Sys module
import Sys
print('System:', Sys.systemName)
```

### 3. Python Class System

```python
# Define class
class Calculator:
    def __init__(self, name):
        self.name = name
        self.result = 0
    
    def add(self, x, y):
        self.result = x + y
        return self.result
    
    def show_result(self):
        print(self.name, 'result:', self.result)

# Use class
calc = Calculator('MyCalc')
result = calc.add(10, 5)
calc.show_result()  # Output: MyCalc result: 15
```

### 4. Function Definition and Calling

```python
# Define function
def greet(name, age):
    print('Hello', name, 'you are', age, 'years old')

# Call function
greet('Alice', 25)
```

### 5. Parent Object Support

```haxe
// Create parent object
var parentObj = { name: "MyApp", version: "1.0" };

// Create interpreter with parent
var interpreter = new Interpreter(parentObj);

// Access parent
trace("Parent: " + interpreter.parent.name);

// Dynamically modify parent
interpreter.parent = newParentObj;
```

## Project Structure

```
pyscript/
├── pyscript/           # Core interpreter code
│   ├── Interpreter.hx  # Main interpreter class
│   ├── Parser.hx       # Syntax parser
│   ├── Lexer.hx        # Lexical analyzer
│   ├── Token.hx        # Token definitions
│   └── ASTNode.hx      # Abstract syntax tree nodes
├── example/            # Example code
│   ├── FinalTest.hx           # Complete functionality demo
│   ├── SmartImportTest.hx     # Smart import system
│   ├── ParentTest.hx          # Parent object support
│   ├── HaxeModuleExample.hx   # Haxe module examples
│   └── FlixelExample.hx       # Game development example
└── README.md           # This document
```

## Running Examples

```bash
# Compile and run complete functionality demo
haxe -main example.FinalTest -cp . -neko final_test.n && neko final_test.n

# Smart import system demo
haxe -main example.SmartImportTest -cp . -neko smart_test.n && neko smart_test.n

# Parent object support demo
haxe -main example.ParentTest -cp . -neko parent_test.n && neko parent_test.n

# Haxe module usage examples
haxe -main example.HaxeModuleExample -cp . -neko haxe_test.n && neko haxe_test.n
```

## Smart Import Rules

PyScript uses intelligent detection algorithms to distinguish between Haxe and Python modules:

| Import Statement | Detection Result | Description |
|-----------------|------------------|-------------|
| `import Math` | Haxe module | First letter uppercase |
| `import math` | Python module | First letter lowercase |
| `import sys.FileSystem` | Haxe module | Last part `FileSystem` uppercase |

## Supported Python Syntax

### Currently Supported
- Class definition and instantiation
- Function definition and calling
- Variable assignment and access
- Property assignment (`obj.attr = value`)
- Method calls (`obj.method()`)
- Module imports (`import module`)
- Basic data types (int, float, string, bool)
- Arithmetic and comparison operators
- print function

### Planned Support
- List and dictionary operations
- Conditional statements (if/elif/else)
- Loop statements (for/while)
- Exception handling (try/except)
- List comprehensions
- Lambda expressions

## API Reference

### Interpreter Class

```haxe
class Interpreter {
    // Constructor
    public function new(?parent:Dynamic)
    
    // Execute Python code
    public function run(code:String):Dynamic
    
    // Parent object access
    public var parent(get, set):Dynamic
    
    // Variable operations
    public function getVariable(name:String):Dynamic
    public function setVariable(name:String, value:Dynamic):Void
    
    // Function access
    public function getFunctions():Map<String, PythonFunction>
}
```

## Use Cases

### Mathematical Computations
```python
import Math

class MathUtils:
    def __init__(self):
        self.pi = Math.PI
    
    def circle_area(self, radius):
        return self.pi * Math.pow(radius, 2)
    
    def degrees_to_radians(self, degrees):
        return degrees * self.pi / 180

utils = MathUtils()
area = utils.circle_area(5)
print('Circle area:', area)
```

## Contributing

Welcome to submit Issues and Pull Requests to improve the PyScript interpreter!

## License

This project is licensed under the MIT License.
