package test;

import pyscript.Interpreter;

class TestInterpreter {
    
    public static function main() {
        trace("Running Python Interpreter Tests...");
        
        var test = new TestInterpreter();
        
        try {
            test.testBasicArithmetic();
            test.testVariables();
            test.testFunctions();
            
            trace("🎉 All tests passed!");
        } catch (e:Dynamic) {
            trace("❌ Test failed: " + e);
        }
    }
    
    public function new() {}
    
    private function testBasicArithmetic() {
        trace("Testing basic arithmetic...");
        
        var interpreter = new Interpreter();
        
        interpreter.run("result1 = 2 + 3");
        assertEqual(interpreter.getVariable("result1"), 5);
        
        interpreter.run("result2 = 10 - 4");
        assertEqual(interpreter.getVariable("result2"), 6);
        
        interpreter.run("result3 = 3 * 4");
        assertEqual(interpreter.getVariable("result3"), 12);
        
        interpreter.run("result4 = 15 / 3");
        assertEqual(interpreter.getVariable("result4"), 5);
        
        interpreter.run("result5 = 17 % 5");
        assertEqual(interpreter.getVariable("result5"), 2);
        
        interpreter.run("result6 = 2 ** 3");
        assertEqual(interpreter.getVariable("result6"), 8);
        
        trace("✓ Basic arithmetic tests passed");
    }
    
    private function testVariables() {
        trace("Testing variables...");
        
        var interpreter = new Interpreter();
        
        interpreter.run("x = 10");
        assertEqual(interpreter.getVariable("x"), 10);
        
        interpreter.run("y = x + 5");
        assertEqual(interpreter.getVariable("y"), 15);
        
        interpreter.run("z = y * 2");
        assertEqual(interpreter.getVariable("z"), 30);
        
        trace("✓ Variable tests passed");
    }
    
    private function testFunctions() {
        trace("Testing functions...");
        
        var interpreter = new Interpreter();
        
        // 定义函数
        interpreter.run("def add(a, b):\n    return a + b");
        
        // 调用函数
        interpreter.run("result = add(3, 5)");
        assertEqual(interpreter.getVariable("result"), 8);
        
        // 测试另一个函数
        interpreter.run("def multiply(x, y):\n    return x * y");
        interpreter.run("product = multiply(4, 6)");
        assertEqual(interpreter.getVariable("product"), 24);
        
        // 测试嵌套函数调用
        interpreter.run("nested = add(multiply(2, 3), 4)");
        assertEqual(interpreter.getVariable("nested"), 10);
        
        trace("✓ Function tests passed");
    }
    
    private function assertEqual(actual:Dynamic, expected:Dynamic) {
        if (actual != expected) {
            throw "Assertion failed: expected " + expected + " got " + actual;
        }
    }
}