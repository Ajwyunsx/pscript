package pyscript.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import StringTools;

/**
 * PyScript宏系统 - 用于增强扩展功能
 * 提供代码转换、语法扩展和Haxe与Python集成增强功能
 */
class PyScriptMacro {
    /**
     * 注册Python函数的宏
     * 将Haxe函数自动转换为可在Python中调用的函数
     * @param interpreter Python解释器
     * @param func 要注册的Haxe函数
     * @return 转换后的表达式
     */
    public static macro function registerPythonFunction(interpreter:Expr, funcName:Expr, func:Expr):Expr {
        var name:String;
        
        switch (funcName.expr) {
            case EConst(CString(s)):
                name = s;
            case EConst(CIdent(s)):
                name = s;
            case _:
                Context.error("Expected string literal or identifier", funcName.pos);
                return macro {};
        }
        
        switch (func.expr) {
            case EFunction(f):
                var funcNameStr = name != null ? name : "anonymous_function";
                
                // 创建函数包装器代码
                var code = 'interpreter.registerFunction("' + funcNameStr + '", function(args:Array<Dynamic>):Dynamic {';
                
                // 添加函数体
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        for (expr in exprs) {
                            code += "    " + exprToString(expr) + "\n";
                        }
                    case _:
                        code += "    " + exprToString(f.expr) + "\n";
                }
                
                code += '});';
                
                // 返回执行代码的表达式
                return macro {
                    $interpreter.registerFunction($v{funcNameStr}, function(args:Array<Dynamic>):Dynamic {
                        $i{funcNameStr}(args);
                    });
                };
            case _:
                Context.error("Expected function expression", func.pos);
                return macro {};
        }
    }
    
    /**
     * 创建Python类的宏
     * 简化Haxe类到Python类的转换
     * @param interpreter Python解释器
     * @param className 类名
     * @return 转换后的表达式
     */
    public static macro function createPythonClass(interpreter:Expr, className:Expr):Expr {
        var name:String;
        
        switch (className.expr) {
            case EConst(CString(s)):
                name = s;
            case EConst(CIdent(s)):
                name = s;
            case _:
                Context.error("Expected string literal or identifier", className.pos);
                return macro {};
        }
        
        // 生成Python类代码
        var pythonCode = 'class ' + name + ':\n';
        
        // 添加构造函数
        pythonCode += '    def __init__(self):\n';
        
        // 添加构造函数体
        pythonCode += '        pass\n';
        
        // 返回执行Python代码的表达式
        return macro {
            $interpreter.run($v{pythonCode});
        };
    }
    
    /**
     * 导入Python模块的宏
     * 简化Python模块的导入过程
     * @param interpreter Python解释器
     * @param moduleName 模块名
     * @return 导入表达式
     */
    public static macro function importPythonModule(interpreter:Expr, moduleName:Expr):Expr {
        var module:String;
        
        switch (moduleName.expr) {
            case EConst(CString(s)):
                module = s;
            case _:
                Context.error("Expected string literal", moduleName.pos);
                return macro {};
        }
        
        var importCode = 'import ' + module + '\n';
        
        return macro {
            $interpreter.run($v{importCode});
        };
    }
    
    /**
     * 执行Python代码的宏
     * 提供更简洁的Python代码执行方式
     * @param interpreter Python解释器
     * @param code Python代码
     * @return 执行表达式
     */
    public static macro function python(interpreter:Expr, code:Expr):Expr {
        var pythonCode:String;
        
        switch (code.expr) {
            case EConst(CString(s)):
                pythonCode = s;
            case _:
                Context.error("Expected string literal", code.pos);
                return macro {};
        }
        
        return macro {
            $interpreter.run($v{pythonCode});
        };
    }
    
    /**
     * 创建Python变量的宏
     * 简化Python变量的创建和赋值
     * @param interpreter Python解释器
     * @param varName 变量名
     * @param value 值表达式
     * @return 赋值表达式
     */
    public static macro function pythonVar(interpreter:Expr, varName:Expr, value:Expr):Expr {
        var name:String;
        
        switch (varName.expr) {
            case EConst(CIdent(s)):
                name = s;
            case _:
                Context.error("Expected identifier", varName.pos);
                return macro {};
        }
        
        return macro {
            $interpreter.execute($v{name + " = " + exprToString(value)});
        };
    }
    
    /**
     * 调用Python函数的宏
     * 简化Python函数的调用
     * @param interpreter Python解释器
     * @param funcName 函数名
     * @param args 参数数组
     * @return 调用表达式
     */
    public static macro function callPythonFunction(interpreter:Expr, funcName:Expr, args:Expr):Expr {
        var name:String;
        
        switch (funcName.expr) {
            case EConst(CIdent(s)):
                name = s;
            case _:
                Context.error("Expected identifier", funcName.pos);
                return macro {};
        }
        
        return macro {
            $interpreter.execute($v{name + "(" + argsToString(args) + ")"});
        };
    }
    
    /**
     * 将表达式转换为字符串
     * @param expr 表达式
     * @return 字符串表示
     */
    private static function exprToString(expr:Expr):String {
        // 简化版实现，实际应用中需要更复杂的转换逻辑
        return switch (expr.expr) {
            case EConst(c):
                switch (c) {
                    case CInt(v): Std.string(v);
                    case CFloat(f): Std.string(f);
                    case CString(s): '"' + s + '"';
                    case CIdent(s): s;
                    case CRegexp(r, opt): "/" + r + "/" + opt;
                }
            case EBinop(op, e1, e2):
                exprToString(e1) + " " + opToString(op) + " " + exprToString(e2);
            case ECall(e, params):
                exprToString(e) + "(" + paramsToString(params) + ")";
            case EField(e, field):
                exprToString(e) + "." + field;
            case EReturn(e):
                "return " + (e != null ? exprToString(e) : "");
            case EBlock(exprs):
                var block = "";
                for (e in exprs) {
                    block += exprToString(e) + "; ";
                }
                return block;
            case EFor(it, expr):
                var result = "for " + exprToString(it) + " in " + exprToString(expr) + ":\n";
                result += "    pass\n";
                return result;
            case EWhile(econd, ebody, normalWhile):
                var result = "while " + exprToString(econd) + ":\n";
                result += "    " + exprToString(ebody) + "\n";
                return result;
            case EIf(econd, eif, eelse):
                var result = "if " + exprToString(econd) + ":\n";
                result += "    " + exprToString(eif) + "\n";
                if (eelse != null) {
                    result += "else:\n";
                    result += "    " + exprToString(eelse) + "\n";
                }
                return result;
            case ETry(e, catches):
                var result = "try:\n";
                result += "    " + exprToString(e) + "\n";
                for (c in catches) {
                    result += "except " + exprToString(c.expr) + ":\n";
                    result += "    pass\n";
                }
                return result;
            case _:
                "/* unsupported expression */";
        }
    }
    
    /**
     * 将二元操作符转换为字符串
     * @param op 操作符
     * @return 字符串表示
     */
    private static function opToString(op:Binop):String {
        return switch (op) {
            case OpAdd: "+";
            case OpSub: "-";
            case OpMult: "*";
            case OpDiv: "/";
            case OpMod: "%";
            case OpEq: "==";
            case OpNotEq: "!=";
            case OpLt: "<";
            case OpLte: "<=";
            case OpGt: ">";
            case OpGte: ">=";
            case OpBoolAnd: "and";
            case OpBoolOr: "or";
            case OpAssign: "=";
            case OpArrow: "->";
            case OpIn: "in";
            case OpInterval: "...";
            case OpAnd: "&";
            case OpOr: "|";
            case OpXor: "^";
            case OpShl: "<<";
            case OpShr: ">>";
            case OpUShr: ">>>";
            case OpNullCoal: "??";
            case OpAssignOp(op): opToString(op) + "=";
            case _: "unknown_op";
        }
    }
    
    /**
     * 将参数数组转换为字符串
     * @param params 参数数组
     * @return 字符串表示
     */
    private static function paramsToString(params:Array<Expr>):String {
        var result = "";
        for (i in 0...params.length) {
            if (i > 0) result += ", ";
            result += exprToString(params[i]);
        }
        return result;
    }
    
    /**
     * 将参数表达式转换为字符串
     * @param argsExpr 参数表达式
     * @return 字符串表示
     */
    private static function argsToString(argsExpr:Expr):String {
        switch (argsExpr.expr) {
            case EArrayDecl(values):
                var result = "";
                for (i in 0...values.length) {
                    if (i > 0) result += ", ";
                    result += exprToString(values[i]);
                }
                return result;
            case _:
                return exprToString(argsExpr);
        }
    }
}