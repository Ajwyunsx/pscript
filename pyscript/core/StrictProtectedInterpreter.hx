package pyscript.core;

/**
 * 严格保护的解释器 - 防止重要对象被转换为字符串
 */
class StrictProtectedInterpreter extends Interpreter {
    private var protectedObjects:Map<String, Bool>;
    
    public function new() {
        super();
        protectedObjects = new Map<String, Bool>();
    }
    
    /**
     * 保护对象不被转换为字符串
     */
    public function protectObject(name:String):Void {
        protectedObjects.set(name, true);
    }
    
    /**
     * 取消保护
     */
    public function unprotectObject(name:String):Void {
        protectedObjects.remove(name);
    }
    
    /**
     * 重写内置函数调用，防止 str(game) 等操作
     */
    override private function evaluateFunctionCall(node:ASTNode):Dynamic {
        var func = evaluate(node.object);
        var args = [];
        
        if (node.arguments != null) {
            for (arg in node.arguments) {
                args.push(evaluate(arg));
            }
        }
        
        // 检查是否是危险的函数调用
        if (isDangerousFunctionCall(func, args)) {
            throw new AttributeError("Cannot convert protected object to string");
        }
        
        return callFunction(func, args);
    }
    
    /**
     * 检查是否是危险的函数调用
     */
    private function isDangerousFunctionCall(func:Dynamic, args:Array<Dynamic>):Bool {
        // 检查 str() 函数
        if (Std.isOfType(func, String) && (func == "str" || func == "String")) {
            if (args.length > 0) {
                var arg = args[0];
                // 检查参数是否是受保护的对象
                for (objName in protectedObjects.keys()) {
                    if (globals.exists(objName)) {
                        var obj = globals.get(objName);
                        if (arg == obj) {
                            return true;
                        }
                    }
                }
            }
        }
        
        return false;
    }
    
    /**
     * 重写变量设置，防止覆盖受保护对象
     */
    override public function setVariable(name:String, value:Dynamic):Void {
        // 检查受保护的对象
        if (protectedObjects.exists(name) && globals.exists(name)) {
            var existing = globals.get(name);
            // 不允许将对象转换为字符串
            if (!Std.isOfType(existing, String) && Std.isOfType(value, String)) {
                throw new AttributeError("Cannot convert protected object '" + name + "' to string");
            }
        }
        
        super.setVariable(name, value);
    }
    
    /**
     * 重写赋值操作
     */
    override private function evaluateAssignment(node:ASTNode):Dynamic {
        var value = evaluate(node.value);
        
        // 检查受保护的变量
        if (protectedObjects.exists(node.name) && globals.exists(node.name)) {
            var existing = globals.get(node.name);
            if (!Std.isOfType(existing, String) && Std.isOfType(value, String)) {
                throw new AttributeError("Cannot assign string to protected object '" + node.name + "'");
            }
        }
        
        setVariable(node.name, value);
        return value;
    }
}