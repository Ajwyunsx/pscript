package pyscript.utils;

import pyscript.ast.ASTNode;
import pyscript.core.Interpreter;

class PropertyHandler {
    private var interpreter:Interpreter;

    public function new(interpreter:Interpreter) {
        this.interpreter = interpreter;
    }

    public function handlePropertyAccess(node:ASTNode):Dynamic {
        if (node.object == null) {
            throw "PropertyAccess: 对象为空";
        }

        // 获取基础对象
        var obj = interpreter.evaluate(node.object);
        if (obj == null) {
            throw "PropertyAccess: 无法访问空对象的属性";
        }

        // 获取并验证属性名
        var prop = getPropertyName(node.property);
        if (prop == null || prop.length == 0) {
            throw "PropertyAccess: 无效的属性名";
        }

        // 处理嵌套属性访问
        if (node.object.type == NodeType.PropertyAccess) {
            return getNestedProperty(obj, prop);
        }

        // 基本属性访问
        return Reflect.field(obj, prop);
    }

    public function handlePropertyAssignment(node:ASTNode):Dynamic {
        if (node.object == null || node.property == null || node.value == null) {
            throw "PropertyAssignment: 缺少必要的属性";
        }

        // 获取要设置的值
        var value = interpreter.evaluate(node.value);

        // 获取并验证属性名
        var prop = getPropertyName(node.property);
        if (prop == null || prop.length == 0) {
            throw "PropertyAssignment: 无效的属性名";
        }

        // 处理嵌套属性赋值
        if (node.object.type == NodeType.PropertyAccess) {
            return handleNestedAssignment(node.object, prop, value);
        }

        // 基本属性赋值
        var obj = interpreter.evaluate(node.object);
        if (obj == null) {
            throw "PropertyAssignment: 无法给空对象设置属性";
        }

        return setProperty(obj, prop, value);
    }

    private function getPropertyName(property:Dynamic):String {
        if (property == null) return null;

        try {
            if (Std.isOfType(property, String)) {
                return property;
            }
            if (Reflect.hasField(property, "name")) {
                var name = Reflect.field(property, "name");
                return name != null ? name : null;
            }
            if (Reflect.hasField(property, "value")) {
                var value = Reflect.field(property, "value");
                return value != null ? Std.string(value) : null;
            }
            return Std.string(property);
        } catch (e:Dynamic) {
            throw "获取属性名失败: " + e;
        }
    }

    private function getNestedProperty(obj:Dynamic, prop:String):Dynamic {
        if (obj == null) {
            throw "PropertyAccess: 父对象为空";
        }

        if (!Reflect.hasField(obj, prop)) {
            throw 'PropertyAccess: 属性 "$prop" 不存在';
        }

        return Reflect.field(obj, prop);
    }

    private function handleNestedAssignment(objectNode:ASTNode, finalProp:String, value:Dynamic):Dynamic {
        var parentObj = interpreter.evaluate(objectNode.object);
        var parentProp = getPropertyName(objectNode.property);

        // 创建中间对象（如果需要）
        if (parentObj == null) {
            parentObj = {};
            var grandParentObj = interpreter.evaluate(objectNode.object);
            if (grandParentObj != null) {
                setProperty(grandParentObj, parentProp, parentObj, true);
            }
        }

        // 设置最终属性
        return setProperty(parentObj, finalProp, value);
    }

    private function setProperty(obj:Dynamic, prop:String, value:Dynamic, isIntermediate:Bool = false):Dynamic {
        if (obj == null) {
            throw "PropertyAssignment: 对象为空";
        }

        try {
            Reflect.setField(obj, prop, value);
            
            // 验证属性是否设置成功
            if (!Reflect.hasField(obj, prop)) {
                throw "属性设置失败";
            }

            // 只在非中间对象设置时输出调试信息
            if (!isIntermediate) {
                trace('Success: 已设置属性 ${prop} = ${Std.string(value)}');
            }
            
            return value;
        } catch (e:Dynamic) {
            throw "属性设置错误: " + e;
        }
    }
}
