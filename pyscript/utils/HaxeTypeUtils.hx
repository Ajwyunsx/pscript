package pyscript.utils;

/**
 * Haxe类型显式赋予工具类
 * 用于在Python脚本中显式指定Haxe类型
 */
class HaxeTypeUtils {
    /**
     * 将Python对象转换为指定类型的Haxe对象
     * @param obj Python对象
     * @param typeName 目标类型名称
     * @return 转换后的Haxe对象
     */
    public static function toHaxeType(obj:Dynamic, typeName:String):Dynamic {
        try {
            switch (typeName.toLowerCase()) {
                case "int":
                    return Std.int(obj);
                case "float":
                    return Std.parseFloat(obj);
                case "bool":
                    return obj == true || obj == 1 || obj == "true" || obj == "1";
                case "string":
                    return Std.string(obj);
                case "array":
                    if (Std.isOfType(obj, Array)) {
                        return obj;
                    } else {
                        return [obj];
                    }
                default:
                    // 尝试获取指定类型的类
                    var cls = Type.resolveClass(typeName);
                    if (cls != null) {
                        // 如果对象已经是该类型的实例，直接返回
                        if (Std.isOfType(obj, cls)) {
                            return obj;
                        }
                        // 否则尝试创建新实例
                        return Type.createInstance(cls, []);
                    }
                    return obj;
            }
        } catch (e:Dynamic) {
            trace("类型转换错误: " + e);
            return obj;
        }
    }
    
    /**
     * 检查对象是否为指定类型
     * @param obj 要检查的对象
     * @param typeName 类型名称
     * @return 是否为指定类型
     */
    public static function isHaxeType(obj:Dynamic, typeName:String):Bool {
        try {
            switch (typeName.toLowerCase()) {
                case "int":
                    return Std.isOfType(obj, Int);
                case "float":
                    return Std.isOfType(obj, Float);
                case "bool":
                    return Std.isOfType(obj, Bool);
                case "string":
                    return Std.isOfType(obj, String);
                case "array":
                    return Std.isOfType(obj, Array);
                default:
                    var cls = Type.resolveClass(typeName);
                    if (cls != null) {
                        return Std.isOfType(obj, cls);
                    }
                    return false;
            }
        } catch (e:Dynamic) {
            return false;
        }
    }
    
    /**
     * 获取对象的类型名称
     * @param obj 要获取类型的对象
     * @return 类型名称
     */
    public static function getTypeName(obj:Dynamic):String {
        if (obj == null) return "null";
        
        if (Std.isOfType(obj, Int)) return "Int";
        if (Std.isOfType(obj, Float)) return "Float";
        if (Std.isOfType(obj, Bool)) return "Bool";
        if (Std.isOfType(obj, String)) return "String";
        if (Std.isOfType(obj, Array)) return "Array";
        
        var className = Type.getClassName(Type.getClass(obj));
        if (className != null) return className;
        
        return "Dynamic";
    }
}