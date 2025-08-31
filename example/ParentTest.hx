package example;

import pyscript.Interpreter;

class ParentTest {
    public static function main() {
        trace("=== Parent属性测试 ===");
        
        // 创建一个父对象
        var parentObj = {
            name: "ParentObject",
            value: 42,
            getMessage: function() return "Hello from parent!"
        };
        
        try {
            // 创建带parent的解释器
            var interpreter = new Interpreter(parentObj);
            
            trace("解释器创建完成，parent: " + interpreter.parent.name);
            
            // 测试基本功能
            interpreter.run("import Math");
            interpreter.run("print('Math.PI =', Math.PI)");
            
            // 测试类功能
            interpreter.run("class Test:\ndef __init__(self, name): self.name = name\ndef greet(self): print('Hello from', self.name)");
            interpreter.run("test = Test('PyScript')");
            interpreter.run("test.greet()");
            
            // 修改parent
            var newParent = {
                name: "NewParent",
                version: "1.0"
            };
            
            interpreter.parent = newParent;
            trace("Parent已更新为: " + interpreter.parent.name + " v" + interpreter.parent.version);
            
            trace("\n✅ Parent属性功能正常工作！");
            
        } catch (e:Dynamic) {
            trace("❌ 错误: " + e);
        }
    }
}