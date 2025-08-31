package example;

import pyscript.Interpreter;

/**
 * Flixel游戏引擎模块导入示例
 * 演示如何在Python代码中使用Flixel相关的Haxe模块
 */
class FlixelExample {
    public static function main() {
        trace("=== Flixel模块导入示例 ===");
        
        var pythonCode = "
# Flixel游戏开发示例
print('=== Flixel游戏引擎模块导入示例 ===')

# 导入Flixel相关模块（模拟）
# 注意：实际使用时需要安装flixel库
print('模拟导入Flixel模块...')

# 示例1: 导入FlxG全局类
# import FlxG
print('FlxG模块导入成功（模拟）')

# 示例2: 导入FlxSprite精灵类
# import FlxSprite  
print('FlxSprite模块导入成功（模拟）')

# 示例3: 导入FlxState状态类
# import FlxState
print('FlxState模块导入成功（模拟）')

# 示例4: 使用Math模块进行游戏相关计算
import Math

def calculate_distance(x1, y1, x2, y2):
    dx = x2 - x1
    dy = y2 - y1
    return Math.sqrt(dx * dx + dy * dy)

def calculate_angle(x1, y1, x2, y2):
    return Math.atan2(y2 - y1, x2 - x1)

# 计算两点间距离
distance = calculate_distance(0, 0, 100, 100)
print('两点(0,0)和(100,100)之间的距离:', distance)

# 计算角度
angle = calculate_angle(0, 0, 100, 100)
print('从(0,0)到(100,100)的角度:', angle, '弧度')

# 角度转度数
degrees = angle * 180 / Math.PI
print('角度（度数）:', degrees)

# 示例5: 游戏物理计算
def apply_gravity(velocity_y, gravity, dt):
    return velocity_y + gravity * dt

def update_position(pos, velocity, dt):
    return pos + velocity * dt

# 模拟重力效果
gravity = 500  # 像素/秒²
dt = 1.0 / 60  # 60 FPS
velocity_y = 0
pos_y = 100

print('\\n=== 模拟重力效果 ===')
for i in range(5):
    velocity_y = apply_gravity(velocity_y, gravity, dt)
    pos_y = update_position(pos_y, velocity_y, dt)
    print('帧', i + 1, ': Y位置 =', pos_y, ', Y速度 =', velocity_y)

print('\\n=== Flixel示例完成 ===')
print('提示：要使用真正的Flixel模块，请先安装HaxeFlixel库')
";
        
        var interpreter = new Interpreter();
        try {
            interpreter.run(pythonCode);
        } catch (e:Dynamic) {
            trace("错误: " + e);
        }
    }
}