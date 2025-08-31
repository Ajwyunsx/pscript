# PyScript Examples

This folder contains examples demonstrating the PyScript interpreter capabilities.

## Features Demonstrated

### 1. Smart Haxe Module Import
- Import Haxe standard library modules using Python syntax
- **Smart detection rules**:
  - No path: `Math` (uppercase) = Haxe, `math` (lowercase) = Python
  - With path: `haxe.Math` → detects `Math` (uppercase) = Haxe
  - With path: `os.path` → detects `path` (lowercase) = Python
- Support for dot-separated module paths
- Access to Haxe functions and constants

### 2. Complete Python Class System
- Class definition with `class ClassName:`
- Constructor methods with `__init__(self, ...)`
- Multi-line method bodies with proper indentation
- Instance methods with `self` parameter
- Property assignment `self.property = value`
- Method calls with return values `instance.method()`

### 3. Function Definition and Calling
- Function definition with `def function_name(params):`
- Multi-parameter support with proper binding
- Local scope and return values
- Print statements and expressions

### 4. Parent Object Support
- Create interpreter with parent object: `new Interpreter(parentObj)`
- Access parent via getter/setter: `interpreter.parent`
- Dynamic parent modification at runtime

## Available Examples

### Core Examples
- **FinalTest.hx** - Complete functionality demonstration
- **SmartImportTest.hx** - Smart module import system
- **ParentTest.hx** - Parent object support

### Specialized Examples  
- **HaxeModuleExample.hx** - Haxe module usage examples
- **FlixelExample.hx** - Game development with Flixel modules

## Running Examples

```bash
# Complete functionality test
haxe -main example.FinalTest -cp . -neko final_test.n && neko final_test.n

# Smart import test
haxe -main example.SmartImportTest -cp . -neko smart_test.n && neko smart_test.n

# Parent object test
haxe -main example.ParentTest -cp . -neko parent_test.n && neko parent_test.n

# Haxe module examples
haxe -main example.HaxeModuleExample -cp . -neko haxe_test.n && neko haxe_test.n

# Flixel game development example
haxe -main example.FlixelExample -cp . -neko flixel_test.n && neko flixel_test.n
```

## Example Code

```python
# Smart Haxe module import
import Math              # Detected as Haxe module
import haxe.Math         # Detected as Haxe module (last part uppercase)
import os.path           # Detected as Python module (last part lowercase)

print('Math.PI =', Math.PI)

# Complete class system
class Calculator:
    def __init__(self, name):
        self.name = name
        self.result = 0
    
    def add(self, x, y):
        self.result = x + y
        return self.result
    
    def show_result(self):
        print(self.name, 'result:', self.result)

calc = Calculator('MyCalc')
result = calc.add(10, 5)
calc.show_result()  # Output: MyCalc result: 15
```

## Haxe Integration

```haxe
// Create interpreter with parent object
var parentObj = { name: "MyApp", version: "1.0" };
var interpreter = new Interpreter(parentObj);

// Access parent from Haxe
trace("Parent: " + interpreter.parent.name);

// Modify parent dynamically
interpreter.parent = newParentObj;