package example;

import pyscript.Interpreter;

/**
 * Haxe模块导入功能示例
 * 演示如何在Python代码中导入和使用Haxe模块
 */
class HaxeModuleExample {
    public static function main() {
        trace("=== Haxe模块导入功能示例 ===");
        
        var pythonCode = "
# 示例1: 导入Math模块进行数学计算
import Math
print('Math模块导入成功')
print('圆周率 π =', Math.PI)
print('sin(π/2) =', Math.sin(Math.PI/2))
print('sqrt(16) =', Math.sqrt(16))
print('2的3次方 =', Math.pow(2, 3))

# 示例2: 使用别名导入
import Math as M
print('\\n使用别名M导入Math模块')
print('cos(0) =', M.cos(0))
print('abs(-10) =', M.abs(-10))

# 示例3: 导入Sys模块获取系统信息
import Sys
print('\\nSys模块导入成功')
print('当前系统:', Sys.systemName)

# 示例4: 定义和使用函数
def calculate_circle_area(radius):
    return Math.PI * Math.pow(radius, 2)

area = calculate_circle_area(5)
print('\\n半径为5的圆的面积:', area)

print('\\n=== 示例完成 ===')
";
        
        var interpreter = new Interpreter();
        try {
            interpreter.run(pythonCode);
        } catch (e:Dynamic) {
            trace("错误: " + e);
        }
    }
}