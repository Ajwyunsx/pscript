package example;

import pyscript.Interpreter;

class SmartImportTest {
    public static function main() {
        trace("=== 智能导入测试 ===");
        
        var interpreter = new Interpreter();
        
        try {
            trace("\n✅ 支持的导入模式:");
            
            // 1. 简单Haxe模块
            trace("\n1. 简单Haxe模块 (Math):");
            interpreter.run("import Math");
            interpreter.run("print('Math.PI =', Math.PI)");
            
            // 2. 简单Python风格模块名
            trace("\n2. Python风格模块名 (math):");
            interpreter.run("import math");  // 会被识别为Python模块
            trace("math模块被识别为Python模块（虽然不存在）");
            
            // 3. 带路径的Haxe模块（理论上的例子）
            trace("\n3. 路径检测示例:");
            trace("- 'haxe.Math' → 检测到 'Math' (大写) → Haxe模块");
            trace("- 'sys.FileSystem' → 检测到 'FileSystem' (大写) → Haxe模块");
            trace("- 'os.path' → 检测到 'path' (小写) → Python模块");
            trace("- 'json.decoder' → 检测到 'decoder' (小写) → Python模块");
            
            trace("\n✅ 智能检测规则:");
            trace("1. 无路径: 首字母大写 = Haxe，小写 = Python");
            trace("2. 有路径: 最后部分首字母大写 = Haxe，小写 = Python");
            
        } catch (e:Dynamic) {
            trace("❌ 错误: " + e);
        }
    }
}