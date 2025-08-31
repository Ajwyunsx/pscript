package;

import pyscript.Interpreter;

class SimpleExample {
    static function main() {
        trace("Python Interpreter for Haxe - Simple Example");
        
        var interpreter = new Interpreter();
        
        // 基本算术
        trace("=== Basic Arithmetic ===");
        var result1 = interpreter.execute("2 + 3 * 4");
        trace("2 + 3 * 4 = " + result1);
        
        // 变量
        trace("\n=== Variables ===");
        interpreter.execute("x = 10");
        interpreter.execute("y = 20");
        var result2 = interpreter.execute("x + y");
        trace("x = 10, y = 20, x + y = " + result2);
        
        // 字符串
        trace("\n=== Strings ===");
        interpreter.execute("name = 'Haxe'");
        interpreter.execute("greeting = 'Hello, ' + name + '!'");
        var greeting = interpreter.getGlobal("greeting");
        trace("greeting = " + greeting);
        
        // 函数调用
        trace("\n=== Function Calls ===");
        interpreter.execute("print('Hello from Python!')");
        interpreter.execute("print('Length of name:', len(name))");
        
        // 自定义函数
        trace("\n=== Custom Functions ===");
        interpreter.registerFunction("haxe_multiply", function(args:Array<Dynamic>):Dynamic {
            return args[0] * args[1] * 100;
        });
        
        var result3 = interpreter.execute("haxe_multiply(3, 4)");
        trace("haxe_multiply(3, 4) = " + result3);
        
        trace("\nExample completed successfully!");
    }
}