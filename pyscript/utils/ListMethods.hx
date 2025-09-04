package pyscript.utils;

/**
 * 列表方法工具类
 * 提供Python风格的列表方法实现
 */
class ListMethods {
    /**
     * 向列表末尾添加元素
     */
    public static function append(list:Array<Dynamic>, value:Dynamic):Void {
        list.push(value);
    }
    
    /**
     * 扩展列表
     */
    public static function extend(list:Array<Dynamic>, other:Array<Dynamic>):Void {
        for (item in other) {
            list.push(item);
        }
    }
    
    /**
     * 在指定位置插入元素
     */
    public static function insert(list:Array<Dynamic>, index:Int, value:Dynamic):Void {
        list.insert(index, value);
    }
    
    /**
     * 移除指定值的第一个匹配项
     */
    public static function remove(list:Array<Dynamic>, value:Dynamic):Bool {
        for (i in 0...list.length) {
            if (list[i] == value) {
                list.splice(i, 1);
                return true;
            }
        }
        return false;
    }
    
    /**
     * 弹出最后一个元素
     */
    public static function pop(list:Array<Dynamic>, ?index:Int = -1):Dynamic {
        if (index == -1 || index == list.length - 1) {
            return list.pop();
        } else if (index >= 0 && index < list.length) {
            return list.splice(index, 1)[0];
        }
        return null;
    }
    
    /**
     * 清空列表
     */
    public static function clear(list:Array<Dynamic>):Void {
        list.resize(0);
    }
    
    /**
     * 查找值的索引
     */
    public static function index(list:Array<Dynamic>, value:Dynamic):Int {
        for (i in 0...list.length) {
            if (list[i] == value) {
                return i;
            }
        }
        throw "Value not found in list";
    }
    
    /**
     * 计算值的出现次数
     */
    public static function count(list:Array<Dynamic>, value:Dynamic):Int {
        var c = 0;
        for (item in list) {
            if (item == value) c++;
        }
        return c;
    }
    
    /**
     * 排序列表
     */
    public static function sort(list:Array<Dynamic>):Void {
        list.sort(function(a:Dynamic, b:Dynamic):Int {
            if (Std.isOfType(a, Float) || Std.isOfType(a, Int) || 
                Std.isOfType(b, Float) || Std.isOfType(b, Int)) {
                var numA = toNumber(a);
                var numB = toNumber(b);
                return numA < numB ? -1 : (numA > numB ? 1 : 0);
            }
            if (Std.isOfType(a, String) && Std.isOfType(b, String)) {
                return cast(a, String) < cast(b, String) ? -1 : (cast(a, String) > cast(b, String) ? 1 : 0);
            }
            return 0;
        });
    }
    
    /**
     * 反转列表
     */
    public static function reverse(list:Array<Dynamic>):Void {
        list.reverse();
    }
    
    /**
     * 复制列表
     */
    public static function copy(list:Array<Dynamic>):Array<Dynamic> {
        return list.copy();
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