package;

import pyscript.PScript;

/**
 * 全面测试Python解释器的所有特性
 */
class AllFeaturesTest {
    public static function main() {
        trace("=== Python解释器全面特性测试 ===\n");
        
        testBasicSyntax();
        testDataTypes();
        testOperators();
        testControlFlow();
        testFunctions();
        testImports();
        testBuiltins();
        testCollections();
        testObjectAccess();
        
        trace("\n=== 所有测试完成 ===");
    }
    
    /**
     * 测试基本语法
     */
    static function testBasicSyntax() {
        trace("\n--- 测试基本语法 ---");
        
        var script = new PScript("
# 这是Python注释
x = 10
y = 20
z = x + y
");
        
        script.execute();
        trace('x = ${script.getVar("x")}'); // 应该是10
        trace('y = ${script.getVar("y")}'); // 应该是20
        trace('z = ${script.getVar("z")}'); // 应该是30
    }
    
    /**
     * 测试数据类型
     */
    static function testDataTypes() {
        trace("\n--- 测试数据类型 ---");
        
        var script = new PScript("
# 整数
int_val = 42
# 浮点数
float_val = 3.14
# 字符串
string_val = 'Hello, World!'
string_val2 = \"Double quotes\"
# 布尔值
bool_true = True
bool_false = False
# 空值
none_val = None
");
        
        script.execute();
        trace('整数: ${script.getVar("int_val")}');
        trace('浮点数: ${script.getVar("float_val")}');
        trace('字符串1: ${script.getVar("string_val")}');
        trace('字符串2: ${script.getVar("string_val2")}');
        trace('布尔真: ${script.getVar("bool_true")}');
        trace('布尔假: ${script.getVar("bool_false")}');
        trace('空值: ${script.getVar("none_val")}');
    }
    
    /**
     * 测试运算符
     */
    static function testOperators() {
        trace("\n--- 测试运算符 ---");
        
        var script = new PScript("
# 算术运算符
add = 5 + 3
sub = 5 - 3
mul = 5 * 3
div = 10 / 3
mod = 10 % 3
floor_div = 10 // 3
power = 2 ** 3

# 比较运算符
eq = 5 == 5
neq = 5 != 3
lt = 5 < 10
gt = 5 > 3
lte = 5 <= 5
gte = 5 >= 5

# 逻辑运算符
and_op = True and False
or_op = True or False
not_op = not True
");
        
        script.execute();
        trace('加法: ${script.getVar("add")}'); // 8
        trace('减法: ${script.getVar("sub")}'); // 2
        trace('乘法: ${script.getVar("mul")}'); // 15
        trace('除法: ${script.getVar("div")}'); // 3.333...
        trace('取模: ${script.getVar("mod")}'); // 1
        trace('整除: ${script.getVar("floor_div")}'); // 3
        trace('幂运算: ${script.getVar("power")}'); // 8
        
        trace('等于: ${script.getVar("eq")}'); // true
        trace('不等于: ${script.getVar("neq")}'); // true
        trace('小于: ${script.getVar("lt")}'); // true
        trace('大于: ${script.getVar("gt")}'); // true
        trace('小于等于: ${script.getVar("lte")}'); // true
        trace('大于等于: ${script.getVar("gte")}'); // true
        
        trace('与: ${script.getVar("and_op")}'); // false
        trace('或: ${script.getVar("or_op")}'); // true
        trace('非: ${script.getVar("not_op")}'); // false
    }
    
    /**
     * 测试控制流
     */
    static function testControlFlow() {
        trace("\n--- 测试控制流 ---");
        
        var script = new PScript("
# if-elif-else语句
x = 10
if x > 20:
    result = 'x大于20'
elif x > 5:
    result = 'x大于5但不大于20'
else:
    result = 'x不大于5'

# while循环
i = 0
sum_while = 0
while i < 5:
    sum_while += i
    i += 1

# for循环
sum_for = 0
for j in range(5):
    sum_for += j
");
        
        script.execute();
        trace('if结果: ${script.getVar("result")}'); // x大于5但不大于20
        trace('while循环和: ${script.getVar("sum_while")}'); // 0+1+2+3+4=10
        trace('for循环和: ${script.getVar("sum_for")}'); // 0+1+2+3+4=10
    }
    
    /**
     * 测试函数
     */
    static function testFunctions() {
        trace("\n--- 测试函数 ---");
        
        var script = new PScript("
# 函数定义
def add(a, b):
    return a + b

# 函数调用
result = add(5, 3)

# 嵌套函数
def outer(x):
    def inner(y):
        return x + y
    return inner

# 闭包
closure = outer(10)
closure_result = closure(5)

# 递归函数
def factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n-1)

fact5 = factorial(5)
");
        
        script.execute();
        trace('函数结果: ${script.getVar("result")}'); // 8
        trace('闭包结果: ${script.getVar("closure_result")}'); // 15
        trace('阶乘结果: ${script.getVar("fact5")}'); // 120
        
        // 直接调用函数
        var addResult = script.callFunc("add", [10, 20]);
        trace('直接调用add函数: $addResult'); // 30
    }
    
    /**
     * 测试导入功能
     */
    static function testImports() {
        trace("\n--- 测试导入功能 ---");
        
        // 创建一个模块文件
        var moduleScript = new PScript("
# 模块变量
module_var = 'Hello from module'

# 模块函数
def module_func(name):
    return 'Hello, ' + name + '!'
");
        
        // 注册模块
        PScript.registerModule("test_module", moduleScript);
        
        // 确保Interpreter能够处理模块导入
        var interpreter = new pyscript.Interpreter();
        interpreter.setVariable("test_module", moduleScript.getInterpreter().getVariable("module_var"));
        
        var script = new PScript("
# 导入模块
import test_module

# 使用模块变量
imported_var = test_module.module_var

# 调用模块函数
imported_func_result = test_module.module_func('Python')

# from import语法
from test_module import module_func
direct_func_result = module_func('Haxe')
");
        
        script.execute();
        trace('导入变量: ${script.getVar("imported_var")}'); // Hello from module
        trace('导入函数结果: ${script.getVar("imported_func_result")}'); // Hello, Python!
        trace('直接导入函数结果: ${script.getVar("direct_func_result")}'); // Hello, Haxe!
    }
    
    /**
     * 测试内置函数
     */
    static function testBuiltins() {
        trace("\n--- 测试内置函数 ---");
        
        var script = new PScript("
# len函数
list_len = len([1, 2, 3, 4, 5])
str_len = len('Hello')

# str函数
num_str = str(42)
bool_str = str(True)

# int函数
int_from_str = int('123')
int_from_float = int(45.67)

# range函数
range_list = list(range(5))
");
        
        script.execute();
        trace('列表长度: ${script.getVar("list_len")}'); // 5
        trace('字符串长度: ${script.getVar("str_len")}'); // 5
        trace('数字转字符串: ${script.getVar("num_str")}'); // "42"
        trace('布尔转字符串: ${script.getVar("bool_str")}'); // "True"
        trace('字符串转整数: ${script.getVar("int_from_str")}'); // 123
        trace('浮点转整数: ${script.getVar("int_from_float")}'); // 45
        trace('range列表: ${script.getVar("range_list")}'); // [0,1,2,3,4]
    }
    
    /**
     * 测试集合类型
     */
    static function testCollections() {
        trace("\n--- 测试集合类型 ---");
        
        var script = new PScript("
# 列表
list1 = [1, 2, 3, 4, 5]
list2 = ['a', 'b', 'c']

# 列表操作
list1.append(6)
list2.extend(['d', 'e'])
list1_popped = list1.pop()
list2.remove('b')

# 列表索引
first_item = list1[0]
last_item = list2[-1]

# 字典
dict1 = {'name': 'Python', 'version': 3.9}
dict2 = {}
dict2['key'] = 'value'

# 字典操作
dict1_name = dict1['name']
dict_keys = list(dict1.keys())
dict_values = list(dict1.values())
");
        
        script.execute();
        trace('列表1: ${script.getVar("list1")}'); // [1,2,3,4,5]
        trace('列表2: ${script.getVar("list2")}'); // ['a','c','d','e']
        trace('弹出元素: ${script.getVar("list1_popped")}'); // 6
        trace('首个元素: ${script.getVar("first_item")}'); // 1
        trace('最后元素: ${script.getVar("last_item")}'); // 'e'
        
        trace('字典1: ${script.getVar("dict1")}'); // {name:Python, version:3.9}
        trace('字典2: ${script.getVar("dict2")}'); // {key:value}
        trace('字典name: ${script.getVar("dict1_name")}'); // Python
        trace('字典键: ${script.getVar("dict_keys")}'); // ['name','version']
        trace('字典值: ${script.getVar("dict_values")}'); // ['Python',3.9]
    }
    
    /**
     * 测试对象访问
     */
    static function testObjectAccess() {
        trace("\n--- 测试对象访问 ---");
        
        // 创建一个Haxe对象
        var testObj = {
            name: "HaxeObject",
            value: 100,
            nested: {
                prop: "NestedProperty"
            },
            method: function(x:Int) {
                return x * 2;
            }
        };
        
        var script = new PScript("
# 访问对象属性
obj_name = test_obj.name
obj_value = test_obj.value
nested_prop = test_obj.nested.prop

# 调用对象方法
method_result = test_obj.method(21)
");
        
        script.setVar("test_obj", testObj);
        script.execute();
        
        trace('对象名称: ${script.getVar("obj_name")}'); // HaxeObject
        trace('对象值: ${script.getVar("obj_value")}'); // 100
        trace('嵌套属性: ${script.getVar("nested_prop")}'); // NestedProperty
        trace('方法结果: ${script.getVar("method_result")}'); // 42
    }
}