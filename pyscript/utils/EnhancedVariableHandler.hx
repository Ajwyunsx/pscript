package pyscript;

/**
 * 增强的变量处理器，用于安全处理变量访问和赋值
 */
class EnhancedVariableHandler {
    private var variables:Map<String, SafeValue>;
    private var globals:Map<String, SafeValue>;
    
    public function new() {
        variables = new Map<String, SafeValue>();
        globals = new Map<String, SafeValue>();
    }
    
    /**
     * 获取变量值
     */
    public function getVariable(name:String):SafeValue {
        try {
            if (variables.exists(name)) {
                return variables.get(name);
            }
            if (globals.exists(name)) {
                return globals.get(name);
            }
            
            // 如果变量不存在，创建新的安全值
            trace('Warning: 变量 "${name}" 未定义，创建新对象');
            var newValue = new SafeValue({});
            variables.set(name, newValue);
            return newValue;
        } catch (e:Dynamic) {
            trace('Error: 获取变量 "${name}" 失败: ${e}');
            return new SafeValue({});
        }
    }
    
    /**
     * 设置变量值
     */
    public function setVariable(name:String, value:Dynamic):Void {
        try {
            var safeValue = new SafeValue(value);
            variables.set(name, safeValue);
            trace('Success: 设置变量 ${name} = ${safeValue}');
        } catch (e:Dynamic) {
            trace('Error: 设置变量 "${name}" 失败: ${e}');
            variables.set(name, new SafeValue({}));
        }
    }
    
    /**
     * 设置全局变量值
     */
    public function setGlobal(name:String, value:Dynamic):Void {
        try {
            var safeValue = new SafeValue(value);
            globals.set(name, safeValue);
            trace('Success: 设置全局变量 ${name} = ${safeValue}');
        } catch (e:Dynamic) {
            trace('Error: 设置全局变量 "${name}" 失败: ${e}');
            globals.set(name, new SafeValue({}));
        }
    }
    
    /**
     * 检查变量是否存在
     */
    public function hasVariable(name:String):Bool {
        return variables.exists(name) || globals.exists(name);
    }
    
    /**
     * 清除所有变量
     */
    public function clearVariables():Void {
        variables = new Map<String, SafeValue>();
    }
    
    /**
     * 清除所有全局变量
     */
    public function clearGlobals():Void {
        globals = new Map<String, SafeValue>();
    }
}
