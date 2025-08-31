# 测试Haxe类支持的PyScript示例

# 导入Haxe类（假设存在这些类）
import FlxSprite
import FlxText
import StringTools

# 创建FlxSprite实例
sprite = FlxSprite(100, 200)
print("Created sprite at position:", sprite.x, sprite.y)

# 创建FlxText实例
text = FlxText(0, 0, 400, "Hello from PyScript!", 16)
print("Created text:", text.text)

# 使用StringTools静态方法（如果存在）
# result = StringTools.trim("  hello world  ")
# print("Trimmed string:", result)

print("Haxe class example completed!")