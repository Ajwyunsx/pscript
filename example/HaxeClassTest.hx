import pyscript.Interpreter;

class HaxeClassTest {
    public static function main() {
        var interpreter = new Interpreter();
        
        var code = '
# 测试Haxe类导入和实例化
import Math
import StringTools

# 使用Math类的静态方法
result = Math.sqrt(16)
print("Math.sqrt(16) =", result)

# 如果有自定义的Haxe类，可以这样使用：
# import MyCustomClass
# obj = MyCustomClass(arg1, arg2)
# obj.someMethod()

print("Haxe class test completed!")
';
        
        try {
            interpreter.run(code);
            trace("Haxe class test executed successfully!");
        } catch (e:Dynamic) {
            trace("Error: " + e);
        }
    }
}