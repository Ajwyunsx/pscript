package pyscript;

import pyscript.core.Interpreter;
import pyscript.core.Lexer;
import pyscript.core.Parser;

/**
 * PyScript运行器
 * 提供简单的API来运行Python代码
 */
class PyScript {
    private var interpreter:Interpreter;
    private var lexer:Lexer;
    private var parser:Parser;
    
    /**
     * 构造函数
     */
    public function new() {
        interpreter = new Interpreter();
        lexer = new Lexer();
        parser = new Parser();
    }
    
    /**
     * 运行Python代码
     * @param code Python代码字符串
     * @return 执行结果（如果有）
     */
    public function run(code:String):Dynamic {
        try {
            // 设置源代码
            lexer.setSource(code);
            
            // 词法分析
            var tokens = lexer.tokenize();
            
            // 语法分析
            parser.setTokens(tokens);
            var ast = parser.parse();
            
            // 执行
            if (ast != null) {
                return interpreter.evaluate(ast);
            }
            
            return null;
        } catch (e:Dynamic) {
            trace("PyScript错误: " + e);
            return null;
        }
    }
    
    /**
     * 设置变量值
     * @param name 变量名
     * @param value 值
     */
    public function set(name:String, value:Dynamic):Void {
        interpreter.setVariable(name, value);
    }
    
    /**
     * 获取变量值
     * @param name 变量名
     * @return 值
     */
    public function get(name:String):Dynamic {
        return interpreter.getVariable(name);
    }
    
    /**
     * 获取全局作用域
     * @return 全局变量映射
     */
    public function getGlobals():Map<String, Dynamic> {
        return interpreter.getGlobals();
    }
}