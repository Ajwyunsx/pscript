package pyscript.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import StringTools;

/**
 * PyScript高级宏系统
 * 提供更复杂的宏功能，如异步操作、装饰器支持和类型注解
 */
class PyScriptAdvancedMacro extends PyScriptMacro {
    /**
     * 创建异步Python函数的宏
     * 将Haxe函数转换为异步Python函数
     * @param interpreter Python解释器
     * @param func Haxe函数
     * @return 转换后的表达式
     */
    public static macro function asyncPythonFunction(interpreter:Expr, funcName:Expr, func:Expr):Expr {
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
                var funcNameStr = name != null ? name : "anonymous_async";
                
                // 创建异步函数包装器代码
                var code = 'async def ' + funcNameStr + '(';
                
                // 添加参数
                for (i in 0...f.args.length) {
                    if (i > 0) code += ', ';
                    code += f.args[i].name;
                }
                
                code += '):\n';
                
                // 添加函数体，将return语句转换为yield语句
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        for (expr in exprs) {
                            var exprStr = exprToString(expr);
                            // 将return语句转换为yield语句
                            exprStr = StringTools.replace(exprStr, "return ", "yield ");
                            code += '    ' + exprStr + '\n';
                        }
                    case _:
                        var exprStr = exprToString(f.expr);
                        exprStr = StringTools.replace(exprStr, "return ", "yield ");
                        code += '    ' + exprStr + '\n';
                }
                
                // 返回执行代码的表达式
                return macro {
                    $interpreter.run($v{code});
                };
            case _:
                Context.error("Expected function expression", func.pos);
                return macro {};
        }
    }
    
    /**
     * 创建Python装饰器的宏
     * 将Haxe函数转换为Python装饰器
     * @param interpreter Python解释器
     * @param decoratorFunc 装饰器函数
     * @param targetFunc 目标函数
     * @return 转换后的表达式
     */
    public static macro function pythonDecorator(interpreter:Expr, decoratorName:Expr, targetFunc:Expr):Expr {
        var decoratorNameStr:String;
        var targetName:String;
        
        // 获取装饰器函数名
        switch (decoratorName.expr) {
            case EConst(CString(s)):
                decoratorNameStr = s;
            case EConst(CIdent(s)):
                decoratorNameStr = s;
            case _:
                Context.error("Expected string literal or identifier", decoratorName.pos);
                return macro {};
        }
        
        // 获取目标函数名
        switch (targetFunc.expr) {
            case EFunction(f):
                var name = f.name;
                targetName = name != null ? name : "anonymous_target";
            case _:
                Context.error("Expected function expression", targetFunc.pos);
                return macro {};
        }
        
        // 创建装饰器代码
        var code = '@' + decoratorNameStr + '\n';
        code += 'def ' + targetName + '():\n';
        code += '    pass\n';
        
        return macro {
            $interpreter.run($v{code});
        };
    }
    
    /**
     * 创建带类型注解的Python函数的宏
     * 将Haxe函数转换为带类型注解的Python函数
     * @param interpreter Python解释器
     * @param func Haxe函数
     * @return 转换后的表达式
     */
    public static macro function typedPythonFunction(interpreter:Expr, funcName:Expr, typeParams:Expr, func:Expr):Expr {
        var name:String;
        var typeParamStrings:Array<String> = [];
        
        // 获取函数名
        switch (funcName.expr) {
            case EConst(CString(s)):
                name = s;
            case EConst(CIdent(s)):
                name = s;
            case _:
                Context.error("Expected string literal or identifier", funcName.pos);
                return macro {};
        }
        
        // 获取类型参数
        switch (typeParams.expr) {
            case EArrayDecl(values):
                for (v in values) {
                    switch (v.expr) {
                        case EConst(CString(s)):
                            typeParamStrings.push(s);
                        case _:
                            // 忽略非字符串类型参数
                    }
                }
                // Continue with function processing
            case _:
                // 忽略非数组类型参数
        }
        
        switch (func.expr) {
            case EFunction(f):
                var funcNameStr = name != null ? name : "anonymous_typed";
                
                // 创建带类型注解的函数代码
                var code = 'def ' + funcNameStr + '(';
                
                // 添加带类型注解的参数
                for (i in 0...f.args.length) {
                    if (i > 0) code += ', ';
                    code += f.args[i].name;
                    
                    // 添加类型注解
                    if (f.args[i].type != null) {
                        code += ': ' + typeToString(f.args[i].type);
                    } else if (i < typeParamStrings.length) {
                        // 使用提供的类型参数
                        code += ': ' + typeParamStrings[i];
                    }
                }
                
                code += ')';
                
                // 添加返回类型注解
                if (f.ret != null) {
                    code += ' -> ' + typeToString(f.ret);
                }
                
                code += ':\n';
                
                // 添加函数体
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        for (expr in exprs) {
                            code += '    ' + exprToString(expr) + '\n';
                        }
                    case _:
                        code += '    ' + exprToString(f.expr) + '\n';
                }
                
                // 返回执行代码的表达式
                return macro {
                    $interpreter.run($v{code});
                };
            case _:
                Context.error("Expected function expression", func.pos);
                return macro {};
        }
    }
    
    /**
     * 创建Python上下文管理器的宏
     * 将Haxe类转换为Python上下文管理器
     * @param interpreter Python解释器
     * @param className 类名
     * @return 转换后的表达式
     */
    public static macro function pythonContextManager(interpreter:Expr, className:Expr):Expr {
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
        
        // 生成上下文管理器代码
        var code = 'class ' + name + ':\n';
        
        // 添加__enter__方法
        code += '    def __enter__(self):\n';
        code += '        return self\n';
        
        // 添加__exit__方法
        code += '\n    def __exit__(self, exc_type, exc_val, exc_tb):\n';
        code += '        return False\n';
        
        // 返回执行代码的表达式
        return macro {
            $interpreter.run($v{code});
        };
    }
    
    /**
     * 创建Python生成器的宏
     * 将Haxe函数转换为Python生成器
     * @param interpreter Python解释器
     * @param func Haxe函数
     * @return 转换后的表达式
     */
    public static macro function pythonGenerator(interpreter:Expr, func:Expr):Expr {
        switch (func.expr) {
            case EFunction(f):
                var name = f.name;
                var funcName = name != null ? name : "anonymous_generator";
                
                // 创建生成器代码
                var code = 'def ' + funcName + '(';
                
                // 添加参数
                for (i in 0...f.args.length) {
                    if (i > 0) code += ', ';
                    code += f.args[i].name;
                }
                
                code += '):\n';
                
                // 添加函数体，将return语句转换为yield语句
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        for (expr in exprs) {
                            var exprStr = exprToString(expr);
                            // 将return语句转换为yield语句
                            exprStr = StringTools.replace(exprStr, "return ", "yield ");
                            code += '    ' + exprStr + '\n';
                        }
                    case _:
                        var exprStr = exprToString(f.expr);
                        exprStr = StringTools.replace(exprStr, "return ", "yield ");
                        code += '    ' + exprStr + '\n';
                }
                
                // 返回执行代码的表达式
                return macro {
                    $interpreter.run($v{code});
                };
            case _:
                Context.error("Expected function expression", func.pos);
                return macro {};
        }
    }
    
    /**
     * 创建Python异常处理类的宏
     * 将Haxe类转换为Python异常处理类
     * @param interpreter Python解释器
     * @param className 类名
     * @return 转换后的表达式
     */
    public static macro function pythonException(interpreter:Expr, className:Expr):Expr {
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
        
        // 生成异常类代码
        var code = 'class ' + name + '(Exception):\n';
        code += '    def __init__(self, message=""):\n';
        code += '        self.message = message\n';
        code += '        super().__init__(self.message)\n';
        
        // 返回执行代码的表达式
        return macro {
            $interpreter.run($v{code});
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
     * 将类型转换为字符串
     * @param type 类型
     * @return 字符串表示
     */
    private static function typeToString(type:ComplexType):String {
        return switch (type) {
            case TPath(p):
                var name = p.name;
                // 简化类型映射
                return switch (name) {
                    case "Int": "int";
                    case "Float": "float";
                    case "String": "str";
                    case "Bool": "bool";
                    case "Array": "list";
                    case "Map": "dict";
                    case "Dynamic": "Any";
                    case "Void": "None";
                    case _: name;
                }
            case TFunction(args, ret):
                var argsStr = [for (arg in args) typeToString(arg)].join(", ");
                return "Callable[[" + argsStr + "], " + typeToString(ret) + "]";
            case TAnonymous(fields):
                var fieldsStr = [for (field in fields) field.name + ": Any"].join(", ");
                return "{" + fieldsStr + "}";
            case TParent(t):
                return "(" + typeToString(t) + ")";
            case TOptional(t):
                return "Optional[" + typeToString(t) + "]";
            case TNamed(n, t):
                return n;
            case TExtend(p, fields):
                var fieldsStr = [for (field in fields) field.name + ": Any"].join(", ");
                return "{" + fieldsStr + "}";
            case TIntersection(types):
                var typesStr = [for (t in types) typeToString(t)].join(" & ");
                return typesStr;
        }
    }
}