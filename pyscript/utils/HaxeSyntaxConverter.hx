package pyscript.utils;

/**
 * Haxe语法兼容转换器
 * 将Haxe语法转换为Python语法
 */
class HaxeSyntaxConverter {
    
    /**
     * 转换Haxe代码为Python代码
     * @param haxeCode Haxe代码
     * @return 转换后的Python代码
     */
    public static function convertHaxeToPython(haxeCode:String):String {
        var pythonCode = haxeCode;
        
        // 1. 转换变量声明
        pythonCode = convertVariableDeclarations(pythonCode);
        
        // 2. 转换函数声明
        pythonCode = convertFunctionDeclarations(pythonCode);
        
        // 3. 转换类声明
        pythonCode = convertClassDeclarations(pythonCode);
        
        // 4. 转换构造函数调用
        pythonCode = convertConstructorCalls(pythonCode);
        
        // 5. 转换方法调用
        pythonCode = convertMethodCalls(pythonCode);
        
        // 6. 转换属性访问
        pythonCode = convertPropertyAccess(pythonCode);
        
        // 7. 转换类型注解
        pythonCode = convertTypeAnnotations(pythonCode);
        
        // 8. 转换注释
        pythonCode = convertComments(pythonCode);
        
        // 9. 转换字符串
        pythonCode = convertStrings(pythonCode);
        
        // 10. 转换数组字面量
        pythonCode = convertArrayLiterals(pythonCode);
        
        // 11. 转换对象字面量
        pythonCode = convertObjectLiterals(pythonCode);
        
        // 12. 转换十六进制数值
        pythonCode = convertHexNumbers(pythonCode);
        
        // 13. 转换链式方法调用
        pythonCode = convertChainedMethodCalls(pythonCode);
        
        return pythonCode;
    }
    
    /**
     * 转换变量声明
     * var x:Int = 10; -> x = 10
     */
    private static function convertVariableDeclarations(code:String):String {
        // 转换 var 声明
        var varPattern = ~/var\s+(\w+)(?:\s*:\s*\w+)?(?:\s*=\s*(.+))?;/g;
        code = varPattern.replace(code, function(re:EReg):String {
            var varName = re.matched(1);
            var value = re.matched(2);
            if (value != null) {
                return varName + " = " + value;
            } else {
                return varName + " = None";
            }
        });
        
        // 转换常量声明
        var constPattern = ~/final\s+(\w+)(?:\s*:\s*\w+)?(?:\s*=\s*(.+))?;/g;
        code = constPattern.replace(code, function(re:EReg):String {
            var varName = re.matched(1);
            var value = re.matched(2);
            if (value != null) {
                return varName + " = " + value;
            } else {
                return varName + " = None";
            }
        });
        
        return code;
    }
    
    /**
     * 转换函数声明
     * function test(x:Int, y:String):Void { ... } -> def test(x, y): ...
     */
    private static function convertFunctionDeclarations(code:String):String {
        var funcPattern = ~/function\s+(\w+)\s*\(([^)]*)\)(?:\s*:\s*\w+)?\s*\{/g;
        code = funcPattern.replace(code, function(re:EReg):String {
            var funcName = re.matched(1);
            var params = re.matched(2);
            
            // 处理参数类型
            var cleanParams = convertParameters(params);
            
            return "def " + funcName + "(" + cleanParams + "):";
        });
        
        return code;
    }
    
    /**
     * 转换参数列表
     */
    private static function convertParameters(params:String):String {
        if (params == null || StringTools.trim(params) == "") {
            return "";
        }
        
        var paramList = params.split(",");
        var cleanParams = [];
        
        for (param in paramList) {
            param = StringTools.trim(param);
            // 移除类型注解
            var colonIndex = param.indexOf(":");
            if (colonIndex != -1) {
                param = param.substring(0, colonIndex);
                param = StringTools.trim(param);
            }
            // 移除默认值中的类型
            var eqIndex = param.indexOf("=");
            if (eqIndex != -1) {
                var paramName = param.substring(0, eqIndex);
                paramName = StringTools.trim(paramName);
                var defaultValue = param.substring(eqIndex + 1);
                defaultValue = StringTools.trim(defaultValue);
                // 清理默认值
                defaultValue = cleanDefaultValue(defaultValue);
                param = paramName + " = " + defaultValue;
            }
            cleanParams.push(param);
        }
        
        return cleanParams.join(", ");
    }
    
    /**
     * 清理默认值
     */
    private static function cleanDefaultValue(value:String):String {
        value = StringTools.trim(value);
        
        // 移除类型转换
        if (StringTools.startsWith(value, "cast(")) {
            value = value.substring(5, value.length - 1);
        }
        
        // 转换 null 为 None
        if (value == "null") {
            return "None";
        }
        
        // 转换布尔值
        if (value == "true") return "True";
        if (value == "false") return "False";
        
        return value;
    }
    
    /**
     * 转换类声明
     * class MyClass { ... } -> class MyClass: ...
     */
    private static function convertClassDeclarations(code:String):String {
        var classPattern = ~/class\s+(\w+)(?:\s+extends\s+(\w+))?\s*\{/g;
        code = classPattern.replace(code, function(re) {
            var className = re.matched(1);
            var parentClass = re.matched(2);
            
            if (parentClass != null) {
                return "class " + className + "(" + parentClass + "):";
            } else {
                return "class " + className + ":";
            }
        });
        
        return code;
    }
    
    /**
     * 转换构造函数调用
     * new MyClass(x, y) -> MyClass(x, y)
     */
    private static function convertConstructorCalls(code:String):String {
        var newPattern = ~/new\s+(\w+)\s*\(([^)]*)\)/g;
        code = newPattern.replace(code, function(re:EReg):String {
            var className = re.matched(1);
            var args = re.matched(2);
            
            // 处理参数
            if (args != null && StringTools.trim(args) != "") {
                var argList:Array<String> = args.split(",");
                var cleanArgs:Array<String> = [];
                
                for (arg in argList) {
                    arg = StringTools.trim(arg);
                    // 移除参数类型
                    var colonIndex = arg.indexOf(":");
                    if (colonIndex != -1) {
                        arg = arg.substring(0, colonIndex);
                        arg = StringTools.trim(arg);
                    }
                    cleanArgs.push(arg);
                }
                
                return className + "(" + cleanArgs.join(", ") + ")";
            } else {
                return className + "()";
            }
        });
        
        return code;
    }
    
    /**
     * 转换方法调用
     * obj.method(x, y) 保持不变，但需要处理Haxe特有的方法名
     */
    private static function convertMethodCalls(code:String):String {
        // Haxe方法名转换
        var methodMap = [
            "toString" => "__str__",
            "charAt" => "get_char",
            "indexOf" => "find",
            "lastIndexOf" => "rfind",
            "substring" => "slice",
            "toUpperCase" => "upper",
            "toLowerCase" => "lower",
            "split" => "split",
            "join" => "join",
            "push" => "append",
            "pop" => "pop",
            "shift" => "pop(0)",
            "unshift" => "insert(0, ",
            "splice" => "del",
            "slice" => "slice",
            "concat" => "+",
            "reverse" => "reverse",
            "sort" => "sort",
            "length" => "len"
        ];
        
        for (haxeMethod => pythonMethod in methodMap) {
            var pattern = new EReg("\\." + haxeMethod + "\\s*\\(", "g");
            code = pattern.replace(code, "." + pythonMethod + "(");
        }
        
        return code;
    }
    
    /**
     * 转换属性访问
     * obj.property 保持不变，但需要处理Haxe特有的属性名
     */
    private static function convertPropertyAccess(code:String):String {
        // Haxe属性名转换
        var propertyMap = [
            "length" => "__len__",
            "toString" => "__str__"
        ];
        
        for (haxeProperty => pythonProperty in propertyMap) {
            var pattern = new EReg("\\." + haxeProperty + "\\b", "g");
            code = pattern.replace(code, "." + pythonProperty);
        }
        
        return code;
    }
    
    /**
     * 转换类型注解
     * 移除所有类型注解
     */
    private static function convertTypeAnnotations(code:String):String {
        // 移除函数参数类型
        var paramTypePattern = ~/\s*:\s*\w+(?:<\w+>)?(?:\[\])?\s*(?=[,)])/g;
        code = paramTypePattern.replace(code, "");
        
        // 移除返回类型
        var returnTypePattern = ~/\s*:\s*\w+(?:<\w+>)?(?:\[\])?\s*(?=\s*[{;])/g;
        code = returnTypePattern.replace(code, "");
        
        return code;
    }
    
    /**
     * 转换注释
     * // 注释 -> # 注释
     * /* 多行注释 * / -> """多行注释"""
     */
    private static function convertComments(code:String):String {
        // 转换单行注释
        var singleLinePattern = ~/\/\/(.*)$/gm;
        code = singleLinePattern.replace(code, "#$1");
        
        // 转换多行注释
        var multiLinePattern = ~/\/\*(.*?)\*\//gs;
        code = multiLinePattern.replace(code, function(re:EReg):String {
            var content = re.matched(1);
            var lines:Array<String> = content.split("\n");
            var pythonLines:Array<String> = [];
            
            for (line in lines) {
                line = StringTools.trim(line);
                if (line != "") {
                    pythonLines.push("# " + line);
                }
            }
            
            return pythonLines.join("\n");
        });
        
        return code;
    }
    
    /**
     * 转换字符串
     * '字符串' 和 "字符串" 保持不变，但处理转义字符
     */
    private static function convertStrings(code:String):String {
        // Haxe字符串插值 ${expr} -> f"{expr}"
        var interpPattern = ~/\$\{([^}]+)\}/g;
        code = interpPattern.replace(code, function(re:EReg):String {
            var expr = re.matched(1);
            return "{" + expr + "}";
        });
        
        // 将单引号字符串转换为双引号
        var singleQuotePattern = ~/'([^']*)'/g;
        code = singleQuotePattern.replace(code, function(re:EReg):String {
            var content = re.matched(1);
            return '"' + content + '"';
        });
        
        return code;
    }
    
    /**
     * 转换数组字面量
     * [1, 2, 3] 保持不变
     * [] -> []
     */
    private static function convertArrayLiterals(code:String):String {
        // Haxe数组字面量已经与Python兼容
        return code;
    }
    
    /**
     * 转换对象字面量
     * { key: value } -> { "key": value }
     */
    private static function convertObjectLiterals(code:String):String {
        var objectPattern = ~/\{\s*(\w+)\s*:\s*([^,}]+)\s*(?:,\s*(\w+)\s*:\s*([^,}]+)\s*)*\}/g;
        code = objectPattern.replace(code, function(re:EReg):String {
            var result = "{ ";
            var pairs:Array<String> = [];
            
            // 处理键值对 - 这里需要更复杂的逻辑，暂时简化处理
            for (i in 1...5) {
                var key = re.matched(i);
                if (key != null) {
                    var value = re.matched(i + 1);
                    if (value != null) {
                        pairs.push('"' + key + '": ' + value);
                    }
                }
            }
            
            result += pairs.join(", ");
            result += " }";
            return result;
        });
        
        return code;
    }
    
    /**
     * 检测代码是否为Haxe语法
     */
    public static function isHaxeSyntax(code:String):Bool {
        // 检查是否包含Haxe特有的语法元素
        var haxeIndicators = [
            ~/var\s+\w+/,
            ~/function\s+\w+/,
            ~/class\s+\w+\s*\{/,
            ~/new\s+\w+\s*\(/,
            ~/:\s*\w+\s*=/,
            ~/:\s*\w+\s*[;,)]/
        ];
        
        for (pattern in haxeIndicators) {
            if (pattern.match(code)) {
                return true;
            }
        }
        
        return false;
    }
    
    /**
     * 转换十六进制数值
     * 0xFF0000 -> 0xFF0000 (Python也支持十六进制)
     * 但需要确保格式正确
     */
    private static function convertHexNumbers(code:String):String {
        // Haxe和Python的十六进制格式基本相同，但确保大小写一致
        var hexPattern = ~/0x([0-9a-fA-F]+)/g;
        var result = code;
        while (hexPattern.match(result)) {
            var hexValue = hexPattern.matched(1);
            var replacement = "0x" + hexValue.toUpperCase();
            result = hexPattern.replace(result, replacement);
        }
        
        // 特殊处理：确保十六进制数值在方法调用中作为整数传递
        // 例如：game.camGame.flash(0xffffff, 1) 中的 0xffffff 需要转换为整数
        var methodCallPattern = ~/\.([a-zA-Z]+)\s*\(([^)]*)\)/g;
        result = methodCallPattern.replace(result, function(re:EReg):String {
            var methodName = re.matched(1);
            var args = re.matched(2);
            
            // 处理参数，将十六进制数值转换为整数
            var processedArgs = processMethodArgumentsWithTypeConversion(args);
            
            return "." + methodName + "(" + processedArgs + ")";
        });
        
        return result;
    }
    
    /**
     * 转换链式方法调用
     * 支持 game.camGame.flash(0xFF0000, 1) 这种语法
     */
    private static function convertChainedMethodCalls(code:String):String {
        // 处理特殊的游戏引擎方法调用
        var gameMethodMap = [
            "flash" => "flash",  // 保持方法名不变
            "shake" => "shake",
            "fade" => "fade",
            "zoom" => "zoom"
        ];
        
        // 匹配链式调用模式: object.property.method(args)
        var chainPattern = ~/(\w+(?:\.\w+)*\.\w+)\s*\(([^)]*)\)/g;
        code = chainPattern.replace(code, function(re:EReg):String {
            var fullChain = re.matched(1);
            var args = re.matched(2);
            
            // 处理参数，确保十六进制数值正确转换
            var processedArgs = processMethodArguments(args);
            
            return fullChain + "(" + processedArgs + ")";
        });
        
        return code;
    }
    
    /**
     * 处理方法参数
     * 确保参数格式正确转换
     */
    private static function processMethodArguments(args:String):String {
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
            // 处理浮点数
            else if (~/^\d+\.\d+$/.match(arg)) {
                processedArgs.push(arg);
            }
            // 处理整数
            else if (~/^\d+$/.match(arg)) {
                processedArgs.push(arg);
            }
            // 处理字符串
            else if (~/^["'].*["']$/.match(arg)) {
                processedArgs.push(arg);
            }
            // 处理变量名或表达式
            else {
                processedArgs.push(arg);
            }
        }
        
        return processedArgs.join(", ");
    }
    
    /**
     * 处理方法参数并进行类型转换
     * 特别处理十六进制数值，确保它们在Python中作为整数正确传递
     */
    private static function processMethodArgumentsWithTypeConversion(args:String):String {
        if (args == null || StringTools.trim(args) == "") {
            return "";
        }
        
        var argList = args.split(",");
        var processedArgs = [];
        
        for (arg in argList) {
            arg = StringTools.trim(arg);
            
            // 处理十六进制数值，转换为整数
            if (~/^0x([0-9a-fA-F]+)$/.match(arg)) {
                var hexValue = arg.substr(2); // 移除0x前缀
                var intValue = Std.parseInt("0x" + hexValue);
                processedArgs.push(Std.string(intValue));
            }
            // 处理浮点数
            else if (~/^\d+\.\d+$/.match(arg)) {
                processedArgs.push(arg);
            }
            // 处理整数
            else if (~/^\d+$/.match(arg)) {
                processedArgs.push(arg);
            }
            // 处理字符串
            else if (~/^["'].*["']$/.match(arg)) {
                processedArgs.push(arg);
            }
            // 处理变量名或表达式
            else {
                processedArgs.push(arg);
            }
        }
        
        return processedArgs.join(", ");
    }

    /**
     * 智能转换代码（自动检测语法类型）
     */
    public static function smartConvert(code:String):String {
        if (isHaxeSyntax(code)) {
            return convertHaxeToPython(code);
        } else {
            return code; // 已经是Python语法
        }
    }
}