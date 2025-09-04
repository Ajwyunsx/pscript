package pyscript.utils;

import pyscript.core.Interpreter;

/**
 * 变量管理助手类，用于安全地处理变量的获取和设置
 */
class VariableHandler {
    private var interpreter:Interpreter;
    private var variables:Map<String, Dynamic>;
    private var globals:Map<String, Dynamic>;

    public function new(interpreter:Interpreter, variables:Map<String, Dynamic>, globals:Map<String, Dynamic>) {
        this.interpreter = interpreter;
        this.variables = variables;
        this.globals = globals;
    }

    /**
     * 安全地获取变量值
     * @param name 变量名
     * @return Dynamic 变量值或空对象
     */
    public function getVariable(name:String):Dynamic {
        try {
            // 验证变量名
            if (!isValidVariableName(name)) {
                throw "无效的变量名";
            }

            // 检查局部变量
            if (variables.exists(name)) {
                var value = variables.get(name);
                trace('Get local variable ${name} = ${safeToString(value)}');
                return ensureNonNull(value);
            }

            // 检查全局变量
            if (globals.exists(name)) {
                var value = globals.get(name);
                trace('Get global variable ${name} = ${safeToString(value)}');
                return ensureNonNull(value);
            }

            // 如果变量不存在，创建一个新的空对象
            return createDefaultVariable(name);
        } catch (e:Dynamic) {
            trace('Variable access error (${name}): ${e}');
            return createEmptyObject();
        }
    }

    /**
     * 安全地设置变量值
     * @param name 变量名
     * @param value 要设置的值
     */
    public function setVariable(name:String, value:Dynamic):Void {
        try {
            // 验证变量名
            if (!isValidVariableName(name)) {
                throw "无效的变量名";
            }

            // 确保值不为null
            value = ensureNonNull(value);

            // 设置变量
            variables.set(name, value);
            trace('Set variable ${name} = ${safeToString(value)}');
        } catch (e:Dynamic) {
            trace('Variable set error (${name}): ${e}');
            // 设置失败时使用空对象
            variables.set(name, createEmptyObject());
        }
    }

    /**
     * 检查变量名是否有效
     */
    private function isValidVariableName(name:String):Bool {
        return name != null && name.length > 0;
    }

    /**
     * 确保返回值不为null
     */
    private function ensureNonNull(value:Dynamic):Dynamic {
        if (value == null) {
            return createEmptyObject();
        }
        return value;
    }

    /**
     * 创建默认变量
     */
    private function createDefaultVariable(name:String):Dynamic {
        var defaultValue = createEmptyObject();
        variables.set(name, defaultValue);
        trace('Warning: Variable "${name}" undefined, creating new object as default value');
        return defaultValue;
    }

    /**
     * 创建空对象
     */
    private function createEmptyObject():Dynamic {
        return {
            isEmptyObject: true,
            toString: function() return "EmptyObject"
        };
    }

    /**
     * 安全地转换为字符串
     */
    private function safeToString(value:Dynamic):String {
        if (value == null) return "null";
        try {
            return Std.string(value);
        } catch (e:Dynamic) {
            return "Object cannot be converted to string";
        }
    }
}
