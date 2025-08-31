package example;

import pyscript.Interpreter;

class FinalTest {
    public static function main() {
        trace("=== 最终测试 ===");
        
        var interpreter = new Interpreter();
        
        try {
            // 1. 测试Haxe模块导入
            trace("\n1. Haxe模块导入:");
            interpreter.run("import Math");
            interpreter.run("print('Math.PI =', Math.PI)");
            
            // 2. 测试简单函数
            trace("\n2. 函数定义和调用:");
            interpreter.run("def greet(name, age): print('Hello', name, 'age', age)");
            interpreter.run("greet('Bob', 25)");
            
            // 3. 测试完整类系统
            trace("\n3. 类定义和使用:");
            interpreter.run("class Calculator:\ndef __init__(self, name):\n    self.name = name\n    self.result = 0\ndef add(self, x, y):\n    self.result = x + y\n    return self.result\ndef show_result(self):\n    print(self.name, 'result:', self.result)");
            
            interpreter.run("calc = Calculator('MyCalc')");
            interpreter.run("result = calc.add(10, 5)");
            interpreter.run("print('计算结果:', result)");
            interpreter.run("calc.show_result()");
            
            trace("\n✅ 核心功能测试完成！");
            
        } catch (e:Dynamic) {
            trace("❌ 错误: " + e);
        }
    }
}