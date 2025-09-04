package pyscript.utils;

/**
 * 安全比较工具类
 * 提供类型安全的比较操作，避免Haxe Python目标中的比较问题
 */
class SafeComparison {
    /**
     * 安全的相等比较
     */
    public static function safeEquals(a:Dynamic, b:Dynamic):Bool {
        // 处理null值
        if (a == null && b == null) return true;
        if (a == null || b == null) return false;
        
        // 相同类型直接比较
        if (Type.typeof(a) == Type.typeof(b)) {
            return a == b;
        }
        
        // 不同类型尝试转换为数字比较
        try {
            var numA = Std.parseFloat(Std.string(a));
            var numB = Std.parseFloat(Std.string(b));
            if (!Math.isNaN(numA) && !Math.isNaN(numB)) {
                return numA == numB;
            }
        } catch (e:Dynamic) {}
        
        // 最后尝试字符串比较
        return Std.string(a) == Std.string(b);
    }
    
    /**
     * 安全的不等比较
     */
    public static function safeNotEquals(a:Dynamic, b:Dynamic):Bool {
        return !safeEquals(a, b);
    }
    
    /**
     * 安全的大于比较
     */
    public static function safeGreaterThan(a:Dynamic, b:Dynamic):Bool {
        if (a == null || b == null) return false;
        
        // 如果都是字符串，直接比较
        if (Std.isOfType(a, String) && Std.isOfType(b, String)) {
            return cast(a, String) > cast(b, String);
        }
        
        // 尝试数字比较
        try {
            var numA = toNumber(a);
            var numB = toNumber(b);
            return numA > numB;
        } catch (e:Dynamic) {}
        
        return false;
    }
    
    /**
     * 安全的小于比较
     */
    public static function safeLessThan(a:Dynamic, b:Dynamic):Bool {
        if (a == null || b == null) return false;
        
        // 如果都是字符串，直接比较
        if (Std.isOfType(a, String) && Std.isOfType(b, String)) {
            return cast(a, String) < cast(b, String);
        }
        
        // 尝试数字比较
        try {
            var numA = toNumber(a);
            var numB = toNumber(b);
            return numA < numB;
        } catch (e:Dynamic) {}
        
        return false;
    }
    
    /**
     * 安全的大于等于比较
     */
    public static function safeGreaterThanOrEqual(a:Dynamic, b:Dynamic):Bool {
        return safeGreaterThan(a, b) || safeEquals(a, b);
    }
    
    /**
     * 安全的小于等于比较
     */
    public static function safeLessThanOrEqual(a:Dynamic, b:Dynamic):Bool {
        return safeLessThan(a, b) || safeEquals(a, b);
    }
    
    /**
     * 安全的三向比较
     */
    public static function safeCompare(a:Dynamic, b:Dynamic):Int {
        if (a == null && b == null) return 0;
        if (a == null) return -1;
        if (b == null) return 1;
        
        // 尝试数字比较
        try {
            var numA = toNumber(a);
            var numB = toNumber(b);
            if (numA < numB) return -1;
            if (numA > numB) return 1;
            return 0;
        } catch (e:Dynamic) {}
        
        // 尝试字符串比较
        try {
            var strA = Std.string(a);
            var strB = Std.string(b);
            if (strA < strB) return -1;
            if (strA > strB) return 1;
            return 0;
        } catch (e:Dynamic) {}
        
        return 0;
    }
    
    /**
     * 安全的长度检查
     */
    public static function safeLength(obj:Dynamic):Int {
        if (obj == null) return 0;
        
        try {
            // 字符串
            if (Std.isOfType(obj, String)) {
                return cast(obj, String).length;
            }
            // 数组
            if (Std.isOfType(obj, Array)) {
                return cast(obj, Array<Dynamic>).length;
            }
            // 字典
            if (Reflect.isObject(obj) && !Std.isOfType(obj, String) && !Std.isOfType(obj, Array)) {
                var fields = Reflect.fields(obj);
                return fields.length;
            }
        } catch (e:Dynamic) {}
        
        return 0;
    }
    
    /**
     * 安全的真值检查
     */
    public static function safeIsTruthy(value:Dynamic):Bool {
        if (value == null) return false;
        if (Std.isOfType(value, Bool)) return value;
        if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) return value != 0;
        if (Std.isOfType(value, String)) return cast(value, String).length > 0;
        if (Std.isOfType(value, Array)) return cast(value, Array<Dynamic>).length > 0;
        
        // 对于对象，检查是否有属性
        if (Reflect.isObject(value)) {
            var fields = Reflect.fields(value);
            return fields.length > 0;
        }
        
        return true;
    }
    
    /**
     * 安全的数字转换
     */
    private static function toNumber(value:Dynamic):Float {
        if (Std.isOfType(value, Float)) return value;
        if (Std.isOfType(value, Int)) return value;
        if (Std.isOfType(value, Bool)) return value ? 1 : 0;
        if (Std.isOfType(value, String)) {
            var num = Std.parseFloat(value);
            return Math.isNaN(num) ? 0 : num;
        }
        return 0;
    }
}