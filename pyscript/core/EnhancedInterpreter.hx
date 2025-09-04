package pyscript.core;

/**
 * 增强的解释器类，修复了已知问题
 */
class EnhancedInterpreter extends Interpreter {
    // 保护的重要变量列表
    private var protectedVariables:Map<String, Bool>;
    
    public function new() {
        super();
        protectedVariables = new Map<String, Bool>();
        
        // 默认保护一些重要变量
        protectedVariables.set("game", true);
        protectedVariables.set("PlayState", true);
        protectedVariables.set("FlxG", true);
    }
    
    /**
     * 设置受保护的变量
     */
    public function protectVariable(name:String):Void {
        protectedVariables.set(name, true);
    }
    
    /**
     * 取消保护变量
     */
    public function unprotectVariable(name:String):Void {
        protectedVariables.remove(name);
    }
    
    /**
     * 重写赋值方法，防止覆盖受保护的变量
     */
    override private function evaluateAssignment(node:ASTNode):Dynamic {
        var value = evaluate(node.value);
        
        // 检查是否是受保护的变量
        if (protectedVariables.exists(node.name) && globals.exists(node.name)) {
            var existingValue = globals.get(node.name);
            var existingType = Type.typeof(existingValue);
            var newType = Type.typeof(value);
            
            // 不允许将对象类型改为基本类型
            if (existingType == TObject && (newType == TClass(String) || newType == TInt || newType == TFloat)) {
                throw new AttributeError('Cannot overwrite protected variable "' + node.name + '" with a primitive value');
            }
        }
        
        setVariable(node.name, value);
        return value;
    }
    
    /**
     * 增强的属性访问，提供更好的错误信息
     */
    override private function evaluatePropertyAccess(node:ASTNode):Dynamic {
        try {
            return super.evaluatePropertyAccess(node);
        } catch (e:AttributeError) {
            // 提供更详细的错误信息
            var obj = evaluate(node.object);
            if (obj != null) {
                var objType = getTypeName(obj);
                throw new AttributeError("'" + objType + "' object has no attribute '" + node.attr + "'");
            }
            throw e;
        }
    }
    
    /**
     * 获取类型名称的辅助方法
     */
    private function getTypeName(obj:Dynamic):String {
        if (obj == null) return "NoneType";
        
        var type = Type.typeof(obj);
        return switch(type) {
            case TBool: "bool";
            case TInt: "int";
            case TFloat: "float";
            case TClass(String): "str";
            case TClass(Array): "list";
            case TClass(Dynamic): "object";
            case TFunction: "function";
            case TObject: "object";
            case TEnum(_): "enum";
            case TUnknown: "unknown";
            default: Std.string(type);
        }
    }
    
    /**
     * 增强的函数定义，避免变量覆盖
     */
    override private function evaluateFunctionDef(node:ASTNode):Dynamic {
        var func = new PythonFunction(node.name, node.parameters, node.body, node.decorators);
        functions.set(node.name, func);
        
        // 检查是否覆盖了受保护的变量
        if (protectedVariables.exists(node.name) && globals.exists(node.name)) {
            var existingValue = globals.get(node.name);
            if (!Std.isOfType(existingValue, PythonFunction)) {
                // 不覆盖受保护的变量，但函数仍然可以通过 callFunc 调用
                return func;
            }
        }
        
        globals.set(node.name, func);
        return func;
    }
}