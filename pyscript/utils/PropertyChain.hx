package pyscript.utils;

import pyscript.core.Interpreter;

/**
 * 属性链处理器
 * 用于处理复杂的属性访问链，如 obj.attr1.attr2.method()
 */
class PropertyChain {
    private var interpreter:Interpreter;
    
    /**
     * 构造函数
     */
    public function new(interpreter:Interpreter) {
        this.interpreter = interpreter;
    }
    
    /**
     * 解析并执行属性链
     * @param chain 属性链字符串，如 "obj.attr1.attr2.method"
     * @param args 调用方法的参数
     * @return 执行结果
     */
    public function execute(chain:String, ?args:Array<Dynamic>):Dynamic {
        if (args == null) args = [];
        
        var parts = chain.split(".");
        if (parts.length == 0) return null;
        
        // 获取起始对象
        var current = interpreter.getVariable(parts[0]);
        
        // 遍历属性链
        for (i in 1...parts.length) {
            var part = parts[i];
            
            // 检查是否是方法调用
            if (part.endsWith("()")) {
                var methodName = part.substring(0, part.length - 2);
                current = callMethod(current, methodName, args);
            } else {
                current = getProperty(current, part);
            }
        }
        
        return current;
    }
    
    /**
     * 获取对象的属性
     */
    private function getProperty(obj:Dynamic, prop:String):Dynamic {
        if (obj == null) throw "Cannot access property '" + prop + "' of null";
        
        if (Std.isOfType(obj, Dynamic)) {
            return Reflect.field(obj, prop);
        } else {
            throw "Cannot access property of non-object: " + obj;
        }
    }
    
    /**
     * 调用对象的方法
     */
    private function callMethod(obj:Dynamic, methodName:String, args:Array<Dynamic>):Dynamic {
        if (obj == null) throw "Cannot call method '" + methodName + "' of null";
        
        var method = getProperty(obj, methodName);
        
        if (Reflect.isFunction(method)) {
            return Reflect.callMethod(obj, method, args);
        } else {
            throw "Not a method: " + methodName;
        }
    }
    
    /**
     * 检查属性链是否存在
     */
    public function exists(chain:String):Bool {
        try {
            var parts = chain.split(".");
            if (parts.length == 0) return false;
            
            var current = interpreter.getVariable(parts[0]);
            
            for (i in 1...parts.length) {
                var part = parts[i];
                
                if (part.endsWith("()")) {
                    var methodName = part.substring(0, part.length - 2);
                    current = getProperty(current, methodName);
                } else {
                    current = getProperty(current, part);
                }
                
                if (current == null) return false;
            }
            
            return true;
        } catch (e:Dynamic) {
            return false;
        }
    }
    
    /**
     * 设置属性链的值
     */
    public function setValue(chain:String, value:Dynamic):Void {
        var parts = chain.split(".");
        if (parts.length < 2) throw "Invalid property chain";
        
        var current = interpreter.getVariable(parts[0]);
        
        // 遍历到倒数第二个属性
        for (i in 1...parts.length - 1) {
            current = getProperty(current, parts[i]);
        }
        
        // 设置最后一个属性的值
        var lastPart = parts[parts.length - 1];
        if (Std.isOfType(current, Dynamic)) {
            Reflect.setField(current, lastPart, value);
        } else {
            throw "Cannot set property of non-object: " + current;
        }
    }
    
    /**
     * 获取属性链的值
     */
    public function getValue(chain:String):Dynamic {
        return execute(chain);
    }
}
