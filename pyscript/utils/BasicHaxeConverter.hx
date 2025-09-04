package pyscript.utils;

/**
 * 基础Haxe语法转换器
 * 使用简单的字符串替换
 */
class BasicHaxeConverter {
    
    /**
     * 转换Haxe代码为Python代码
     */
    public static function convertToPython(haxeCode:String):String {
        var pythonCode = haxeCode;
        
        // 1. 转换变量声明
        pythonCode = pythonCode.split("var ").join("");
        
        // 2. 转换函数声明
        pythonCode = pythonCode.split("function ").join("def ");
        
        // 3. 转换类型注解
        pythonCode = pythonCode.split(":Int").join("");
        pythonCode = pythonCode.split(":String").join("");
        pythonCode = pythonCode.split(":Void").join("");
        pythonCode = pythonCode.split(":Bool").join("");
        pythonCode = pythonCode.split(":Float").join("");
        
        // 4. 转换花括号为Python缩进块
        pythonCode = pythonCode.split("{").join("");
        pythonCode = pythonCode.split("}").join("");
        
        // 5. 转换构造函数调用
        pythonCode = pythonCode.split("new ").join("");
        
        // 6. 转换注释
        pythonCode = pythonCode.split("//").join("#");
        
        // 7. 转换结尾分号
        pythonCode = pythonCode.split(";").join("");
        
        // 8. 转换布尔值和null
        pythonCode = pythonCode.split("true").join("True");
        pythonCode = pythonCode.split("false").join("False");
        pythonCode = pythonCode.split("null").join("None");
        
        return pythonCode;
    }
    
    /**
     * 检测是否为Haxe语法
     */
    public static function isHaxeSyntax(code:String):Bool {
        return code.indexOf("var ") != -1 || 
               code.indexOf("function ") != -1 || 
               code.indexOf("new ") != -1 ||
               code.indexOf(":Int") != -1 ||
               code.indexOf(":String") != -1 ||
               code.indexOf(":Void") != -1;
    }
    
    /**
     * 智能转换
     */
    public static function smartConvert(code:String):String {
        if (isHaxeSyntax(code)) {
            return convertToPython(code);
        } else {
            return code;
        }
    }
}