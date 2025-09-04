package pyscript.core;

import pyscript.utils.Exceptions;

/**
 * Python字典实现
 * 支持点号表示法访问字典键
 */
class PythonDict {
    private var data:Map<Dynamic, Dynamic>;
    
    public function new() {
        data = new Map<Dynamic, Dynamic>();
    }
    
    // 添加点号表示法支持
    public function resolveProperty(name:String):Dynamic {
        // 首先检查是否是字典的方法
        try {
            return getProperty(name);
        } catch (e:Dynamic) {
            // 如果不是方法，尝试作为字典键
            if (data.exists(name)) {
                return data.get(name);
            }
            // 如果都不存在，抛出属性错误
            throw new AttributeError("'dict' object has no attribute '" + name + "'");
        }
    }
    
    // 添加属性赋值支持
    public function setProperty(name:String, value:Dynamic):Void {
        // 检查是否是字典的方法名
        switch (name) {
            case "get" | "keys" | "values" | "items" | "update" | "clear" | "pop":
                throw new AttributeError("'dict' object attribute '" + name + "' is read-only");
            default:
                // 将属性赋值作为字典键值对
                data.set(name, value);
        }
    }
    
    public function set(key:Dynamic, value:Dynamic):Void {
        data.set(key, value);
    }
    
    public function get(key:Dynamic):Dynamic {
        return data.get(key);
    }
    
    public function exists(key:Dynamic):Bool {
        return data.exists(key);
    }
    
    public function remove(key:Dynamic):Bool {
        return data.remove(key);
    }
    
    public function clear():Void {
        data.clear();
    }
    
    public function keys():Array<Dynamic> {
        var result = [];
        for (key in data.keys()) {
            result.push(key);
        }
        return result;
    }
    
    public function values():Array<Dynamic> {
        var result = [];
        for (value in data) {
            result.push(value);
        }
        return result;
    }
    
    public function items():Array<Array<Dynamic>> {
        var result = [];
        for (key in data.keys()) {
            result.push([key, data.get(key)]);
        }
        return result;
    }
    
    public function update(other:PythonDict):Void {
        if (other != null) {
            for (key in other.data.keys()) {
                data.set(key, other.data.get(key));
            }
        }
    }
    
    public function pop(key:Dynamic, ?defaultValue:Dynamic):Dynamic {
        if (data.exists(key)) {
            var value = data.get(key);
            data.remove(key);
            return value;
        }
        if (defaultValue != null) {
            return defaultValue;
        }
        throw "KeyError: " + key;
    }
    
    public function getProperty(name:String):Dynamic {
        switch (name) {
            case "get":
                return makeListMethod(function(args) {
                    var key = args.length > 0 ? args[0] : null;
                    var defaultValue = args.length > 1 ? args[1] : null;
                    if (exists(key)) {
                        return get(key);
                    }
                    return defaultValue;
                });
            case "keys":
                return makeListMethod(function(args) {
                    return keys();
                });
            case "values":
                return makeListMethod(function(args) {
                    return values();
                });
            case "items":
                return makeListMethod(function(args) {
                    return items();
                });
            case "update":
                return makeListMethod(function(args) {
                    if (args.length > 0 && Std.isOfType(args[0], PythonDict)) {
                        update(cast(args[0], PythonDict));
                    }
                    return null;
                });
            case "clear":
                return makeListMethod(function(args) {
                    clear();
                    return null;
                });
            case "pop":
                return makeListMethod(function(args) {
                    var key = args.length > 0 ? args[0] : null;
                    var defaultValue = args.length > 1 ? args[1] : null;
                    return pop(key, defaultValue);
                });
            default:
                throw "AttributeError: 'dict' object has no attribute '" + name + "'";
        }
    }
    
    private function makeListMethod(func:Array<Dynamic>->Dynamic):Dynamic {
        return function(?args:Array<Dynamic>) {
            if (args == null) args = [];
            return func(args);
        };
    }
}