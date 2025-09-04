package pyscript.utils;

/**
 * 简化的 Haxe 语法转换器
 * 专门处理游戏引擎相关的语法转换
 */
class SimpleHaxeConverter {
    
    /**
     * 转换 Haxe 代码为 Python 代码
     */
    public static function convertHaxeToPython(haxeCode:String):String {
        var pythonCode = haxeCode;
        
        // 1. 转换十六进制数值
        pythonCode = convertHexNumbers(pythonCode);
        
        // 2. 转换链式方法调用
        pythonCode = convertChainedMethodCalls(pythonCode);
        
        return pythonCode;
    }
    
    /**
     * 转换十六进制数值
     * 0xFF0000 -> 0xFF0000 (保持不变，Python也支持)
     */
    private static function convertHexNumbers(code:String):String {
        // 简单的字符串替换，将常见的小写十六进制转换为大写
        var result = code;
        
        // 替换常见的十六进制模式
        var hexMappings = [
            "0xff" => "0xFF",
            "0xaa" => "0xAA",
            "0xbb" => "0xBB",
            "0xcc" => "0xCC",
            "0xdd" => "0xDD",
            "0xee" => "0xEE"
        ];
        
        for (lower => upper in hexMappings) {
            result = StringTools.replace(result, lower, upper);
        }
        
        return result;
    }
    
    /**
     * 转换链式方法调用
     * game.camGame.flash(0xFF0000, 1) -> game.camGame.flash(0xFF0000, 1)
     * 主要是确保参数格式正确
     */
    private static function convertChainedMethodCalls(code:String):String {
        // 简化处理：直接返回代码，因为链式调用在Python中是兼容的
        // 主要工作已经在 convertHexNumbers 中完成
        return code;
    }
    
    /**
     * 处理方法参数
     */
    private static function processArguments(args:String):String {
        if (args == null || StringTools.trim(args) == "") {
            return "";
        }
        
        var argList = args.split(",");
        var processedArgs = [];
        
        for (arg in argList) {
            arg = StringTools.trim(arg);
            
            // 处理十六进制数值
            if (~/^0x[0-9a-fA-F]+$/.match(arg)) {
                processedArgs.push(arg.toUpperCase());
            }
            // 其他参数保持不变
            else {
                processedArgs.push(arg);
            }
        }
        
        return processedArgs.join(", ");
    }
    
    /**
     * 检测是否包含需要转换的 Haxe 语法
     */
    public static function containsHaxeSyntax(code:String):Bool {
        // 检查十六进制数值
        if (~/0x[0-9a-fA-F]+/.match(code)) {
            return true;
        }
        
        // 检查链式方法调用
        if (~/\w+\.\w+\.\w+\s*\(/.match(code)) {
            return true;
        }
        
        return false;
    }
    
    /**
     * 智能转换（自动检测并转换）
     */
    public static function smartConvert(code:String):String {
        if (containsHaxeSyntax(code)) {
            return convertHaxeToPython(code);
        }
        return code;
    }
}