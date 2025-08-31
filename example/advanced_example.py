# 高级Python脚本示例
# 这个脚本展示了Python解释器支持的高级功能

# 导入模块
import math
from math import sqrt

# 类定义
class Vector:
    def __init__(self, x, y):
        self.x = x
        self.y = y
    
    def magnitude(self):
        return sqrt(self.x * self.x + self.y * self.y)
    
    def normalize(self):
        mag = self.magnitude()
        if mag > 0:
            self.x = self.x / mag
            self.y = self.y / mag
        return self

# 高阶函数
def apply_to_each(func, items):
    results = []
    for item in items:
        results.append(func(item))
    return results

# 闭包
def multiplier(factor):
    def multiply(x):
        return x * factor
    return multiply

# 递归函数
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

# 列表推导
squares = [x*x for x in range(10)]

# 字典操作
person = {
    "name": "Python",
    "age": 30,
    "skills": ["programming", "data analysis", "web development"]
}

# 使用类
v1 = Vector(3, 4)
print("Vector magnitude:", v1.magnitude())
v1.normalize()
print("Normalized vector:", v1.x, v1.y)

# 使用高阶函数
numbers = [1, 2, 3, 4, 5]
doubled = apply_to_each(lambda x: x * 2, numbers)
print("Doubled numbers:", doubled)

# 使用闭包
double = multiplier(2)
triple = multiplier(3)
print("Double 5:", double(5))
print("Triple 5:", triple(5))

# 使用递归
print("Fibonacci of 7:", fibonacci(7))

# 使用列表推导
print("Squares:", squares)

# 使用字典
print("Person:", person["name"], "is", person["age"], "years old")
print("Skills:", ", ".join(person["skills"]))

# 条件表达式
status = "adult" if person["age"] >= 18 else "minor"
print("Status:", status)

# 全局变量
global_var = 100

def modify_global():
    global global_var
    global_var += 50
    return global_var

print("Modified global:", modify_global())
print("Global variable:", global_var)

# 异常处理
try:
    result = 10 / 0
except:
    result = "Error: Division by zero"

print("Exception result:", result)

# 最终结果
print("Script completed successfully!")