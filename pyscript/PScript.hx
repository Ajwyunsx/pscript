package pyscript;

import pyscript.Interpreter;

/**
 * Python脚本解析器
 * 类似于LScript，但用于Python脚本
 */
class PScript {
    private var interpreter:Interpreter;
    private var scriptContent:String;
    
    // 模块注册表
    private static var modules:Map<String, PScript> = new Map<String, PScript>();
    
    public var parent:Dynamic;
    
    public function new(?scriptContent:String) {
        interpreter = new Interpreter();
        
        if (scriptContent != null) {
            this.scriptContent = scriptContent;
        }
    }
    
    /**
     * 从文件路径加载Python脚本
     */
    public static function fromFile(path:String):PScript {
        #if openfl
        var content = openfl.Assets.getText(path);
        #else
        var content = sys.io.File.getContent(path);
        #end
        return new PScript(content);
    }
    
    /**
     * 从字符串创建Python脚本
     */
    public static function fromString(content:String):PScript {
        return new PScript(content);
    }
    
    /**
     * 设置变量到Python环境中
     */
    public function setVar(name:String, value:Dynamic):Void {
        interpreter.setVariable(name, value);
    }
    
    /**
     * 获取Python环境中的变量
     */
    public function getVar(name:String):Dynamic {
        return interpreter.getVariable(name);
    }
    
    /**
     * 执行Python脚本
     */
    public function execute():Void {
        if (scriptContent != null) {
            try {
                interpreter.run(scriptContent);
            } catch (e:pyscript.Interpreter.ReturnException) {
                // 顶层return语句，忽略
            }
        }
    }
    
    /**
     * 调用Python函数
     */
    public function callFunc(funcName:String, ?args:Array<Dynamic>):Dynamic {
        if (args == null) args = [];
        
        // 构建函数调用代码
        var argsStr = "";
        for (i in 0...args.length) {
            if (i > 0) argsStr += ", ";
            // 将参数设置到临时变量中
            var argName = "__arg" + i;
            interpreter.setVariable(argName, args[i]);
            argsStr += argName;
        }
        
        var callCode = "__result = " + funcName + "(" + argsStr + ")";
        interpreter.run(callCode);
        
        return interpreter.getVariable("__result");
    }
    
    /**
     * 检查函数是否存在
     */
    public function hasFunc(funcName:String):Bool {
        var func = interpreter.getVariable(funcName);
        return func != null;
    }
    
    /**
     * 运行单行Python代码
     */
    public function run(code:String):Dynamic {
        return interpreter.run(code);
    }
    
    /**
     * 清除所有变量
     */
    public function clear():Void {
        interpreter = new Interpreter();
    }
    
    /**
     * 获取所有变量名
     */
    public function getVarNames():Array<String> {
        // 这需要在Interpreter中添加支持
        return [];
    }
    
    /**
     * 获取解释器实例
     */
    public function getInterpreter():Interpreter {
        return interpreter;
    }
    
    /**
     * 注册模块
     */
    public static function registerModule(name:String, script:PScript):Void {
        modules.set(name, script);
    }
    
    /**
     * 获取已注册模块
     */
    public static function getModule(name:String):PScript {
        return modules.get(name);
    }
}