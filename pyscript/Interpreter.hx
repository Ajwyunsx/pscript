package pyscript;

import pyscript.Token;
import pyscript.ASTNode;
import pyscript.Lexer;
import pyscript.Parser;

class ReturnException {
    public var value:Dynamic;
    
    public function new(value:Dynamic) {
        this.value = value;
    }
}

class ModuleLoader {
    private var haxeModules:Map<String, Dynamic>;
    
    public function new() {
        haxeModules = new Map<String, Dynamic>();
        setupBuiltinModules();
    }
    
    private function setupBuiltinModules() {
        // 设置内置模块，可以映射到Haxe的类和函数
        haxeModules.set("math", {
            "pi": Math.PI,
            "sqrt": Math.sqrt,
            "pow": Math.pow,
            "sin": Math.sin,
            "cos": Math.cos,
            "tan": Math.tan,
            "floor": Math.floor,
            "ceil": Math.ceil,
            "abs": Math.abs,
            "random": Math.random
        });
        
        haxeModules.set("sys", {
            "platform": Sys.systemName,
            "exit": Sys.exit
        });
    }
    
    public function loadModule(moduleName:String):Dynamic {
        // 首先检查是否是内置模块
        if (haxeModules.exists(moduleName)) {
            return haxeModules.get(moduleName);
        }
        
        // 尝试加载Python文件
        try {
            var pythonCode = sys.io.File.getContent(moduleName + ".py");
            var interpreter = new Interpreter();
            interpreter.run(pythonCode);
            
            // 返回模块的全局变量和函数
            var moduleObj = {};
            var globalScope = interpreter.getGlobalScope();
            for (key in globalScope.keys()) {
                Reflect.setField(moduleObj, key, globalScope.get(key));
            }
            var funcs = interpreter.getFunctions();
            for (funcName in funcs.keys()) {
                var pythonFunc = funcs.get(funcName);
                // 直接存储PythonFunction对象，在callMethod中特殊处理
                Reflect.setField(moduleObj, funcName, pythonFunc);
            }
            
            return moduleObj;
        } catch (e:Dynamic) {
            // 如果文件加载失败，返回空对象而不是抛出异常
            trace("Warning: Could not load module " + moduleName + ", using empty module");
            return {};
        }
    }
}

class PythonFunction {
    public var name:String;
    public var parameters:Array<String>;
    public var body:ASTNode;
    public var interpreter:Interpreter;
    
    public function new(name:String, parameters:Array<String>, body:ASTNode, interpreter:Interpreter) {
        this.name = name;
        this.parameters = parameters;
        this.body = body;
        this.interpreter = interpreter;
    }
    
    public function call(args:Array<Dynamic>):Dynamic {
        // trace("PythonFunction.call: starting " + name + " with args " + args);
        if (args.length != parameters.length) {
            throw "Function " + name + " expects " + parameters.length + " arguments, got " + args.length;
        }
        
        interpreter.pushScope();
        
        for (i in 0...parameters.length) {
            interpreter.setVariable(parameters[i], args[i]);
            // trace("PythonFunction.call: set param " + parameters[i] + " = " + args[i]);
        }
        
        var result:Dynamic = null;
        try {
            // trace("PythonFunction.call: evaluating body");
            result = interpreter.evaluate(body);
            // trace("PythonFunction.call: body evaluation completed, result = " + result);
        } catch (e:Dynamic) {
            if (Std.isOfType(e, ReturnException)) {
                var retEx:ReturnException = cast e;
                result = retEx.value;
                // trace("PythonFunction.call: caught ReturnException with value " + result);
            } else {
                interpreter.popScope();
                throw e;
            }
        }
        
        interpreter.popScope();
        // trace("PythonFunction.call: returning " + result);
        
        return result;
    }
}

class Interpreter {
    private var variables:Array<Map<String, Dynamic>>;
    private var functions:Map<String, PythonFunction>;
    private var globalVars:Map<String, Bool>; // 跟踪哪些变量被声明为全局变量
    private var modules:Map<String, Dynamic>; // 已导入的模块
    private var moduleLoader:ModuleLoader; // 模块加载器
    
    public function new() {
        variables = [new Map<String, Dynamic>()];
        functions = new Map<String, PythonFunction>();
        globalVars = new Map<String, Bool>();
        modules = new Map<String, Dynamic>();
        moduleLoader = new ModuleLoader();
    }
    
    public function run(code:String):Dynamic {
        var lexer = new Lexer(code);
        var tokens = lexer.tokenize();
        var parser = new Parser(tokens);
        var ast = parser.parse();
        return evaluate(ast);
    }
    
    public function pushScope() {
        variables.push(new Map<String, Dynamic>());
    }
    
    public function popScope() {
        if (variables.length > 1) {
            variables.pop();
        }
    }
    
    public function setVariable(name:String, value:Dynamic) {
        // 如果变量被声明为全局变量，则设置到全局作用域
        if (globalVars.exists(name) && globalVars.get(name)) {
            variables[0].set(name, value);
        } else {
            variables[variables.length - 1].set(name, value);
        }
    }
    
    public function getVariable(name:String):Dynamic {
        for (i in 0...variables.length) {
            var scope = variables[variables.length - 1 - i];
            if (scope.exists(name)) {
                return scope.get(name);
            }
        }
        throw "Undefined variable: " + name;
    }
    
    public function getGlobalScope():Map<String, Dynamic> {
        return variables[0];
    }
    
    public function getFunctions():Map<String, PythonFunction> {
        return functions;
    }
    
    public function evaluate(node:ASTNode):Dynamic {
        if (node == null) return null;
        
        // trace("Evaluating node: " + node.type + " with value: " + node.value);
        
        switch (node.type) {
            case Literal:
                return node.value;
                
            case Identifier:
                return getVariable(node.name);
                
            case BinaryOp:
                var left = evaluate(node.left);
                var right = evaluate(node.right);
                return evaluateBinaryOp(node.op, left, right);
                
            case UnaryOp:
                var operand = evaluate(node.operand);
                return evaluateUnaryOp(node.op, operand);
                
            case Assignment:
                // trace("Processing assignment: " + node.name + " = " + node.value);
                var value = evaluate(node.value);
                setVariable(node.name, value);
                // trace("Set variable " + node.name + " to " + value);
                return value;
                
            case FunctionCall:
                if (node.object != null) {
                    // 方法调用 (object.method())
                    var obj = evaluate(node.object);
                    return callMethod(obj, node.name, node.arguments);
                } else {
                    // 普通函数调用
                    return callFunction(node.name, node.arguments);
                }
                
            case PropertyAccess:
                var obj = evaluate(node.object);
                return getProperty(obj, node.property);
                
            case IndexAccess:
                var obj = evaluate(node.object);
                var index = evaluate(node.index);
                return getIndexedValue(obj, index);
                
            case FunctionDef:
                // trace("Defining function: " + node.name);
                var func = new PythonFunction(node.name, node.parameters, node.body, this);
                functions.set(node.name, func);
                return null;
                
            case IfStatement:
                if (isTruthy(evaluate(node.condition))) {
                    return evaluate(node.thenBranch);
                } else if (node.elseBranch != null) {
                    return evaluate(node.elseBranch);
                }
                return null;
                
            case WhileLoop:
                var result:Dynamic = null;
                while (isTruthy(evaluate(node.condition))) {
                    result = evaluate(node.body);
                }
                return result;
                
            case ForLoop:
                var result:Dynamic = null;
                var iterable = evaluate(node.iterable);
                if (Std.isOfType(iterable, Array)) {
                    var arr:Array<Dynamic> = cast iterable;
                    for (item in arr) {
                        setVariable(node.variable, item);
                        result = evaluate(node.body);
                    }
                }
                return result;
                
            case Block:
                pushScope();
                var result:Dynamic = null;
                for (stmt in node.statements) {
                    try {
                        result = evaluate(stmt);
                    } catch (e:ReturnException) {
                        popScope();
                        throw e;
                    }
                }
                popScope();
                return result;
                
            case ReturnStatement:
                var value = null;
                if (node.value != null) {
                    value = evaluate(node.value);
                }
                // trace("ReturnStatement: throwing ReturnException with value " + value);
                throw new ReturnException(value);
                
            case GlobalStatement:
                // Global语句在Python中用于声明全局变量
                // 标记这些变量为全局变量，以便在赋值时正确处理
                for (name in node.names) {
                    globalVars.set(name, true);
                    // 如果全局作用域中不存在该变量，初始化为null
                    if (!variables[0].exists(name)) {
                        variables[0].set(name, null);
                    }
                }
                return null;
                
            case ImportStatement:
                // import module [as alias]
                var module = moduleLoader.loadModule(node.module);
                var varName = node.alias != null ? node.alias : node.module;
                setVariable(varName, module);
                return null;
                
            case FromImportStatement:
                // from module import name1 [as alias1], name2 [as alias2], ...
                var module = moduleLoader.loadModule(node.module);
                for (i in 0...node.importNames.length) {
                    var importName = node.importNames[i];
                    var alias = node.importAliases[i];
                    var varName = alias != null ? alias : importName;
                    
                    if (Reflect.hasField(module, importName)) {
                        var value = Reflect.field(module, importName);
                        setVariable(varName, value);
                    } else {
                        throw "Cannot import '" + importName + "' from module '" + node.module + "'";
                    }
                }
                return null;
                
            case ExpressionStatement:
                return evaluate(node.expression);
                
            case Program:
                var result:Dynamic = null;
                for (stmt in node.statements) {
                    result = evaluate(stmt);
                }
                return result;
                
            case ListLiteral:
                return evaluateListLiteral(node);
                
            case DictLiteral:
                return evaluateDictLiteral(node);
                
            default:
                throw "Unknown node type: " + node.type;
        }
    }
    
    private function evaluateBinaryOp(op:String, left:Dynamic, right:Dynamic):Dynamic {
        switch (op) {
            case "+": return left + right;
            case "-": return left - right;
            case "*": return left * right;
            case "/": return left / right;
            case "%": return left % right;
            case "**": return Math.pow(left, right);
            case "//": return Math.floor(left / right); // 整除运算符
            case "==": return left == right;
            case "!=": return left != right;
            case "<": return left < right;
            case ">": return left > right;
            case "<=": return left <= right;
            case ">=": return left >= right;
            case "and": return isTruthy(left) && isTruthy(right);
            case "or": return isTruthy(left) || isTruthy(right);
            default: throw "Unknown binary operator: " + op;
        }
    }
    
    private function evaluateUnaryOp(op:String, operand:Dynamic):Dynamic {
        switch (op) {
            case "not": return !isTruthy(operand);
            case "-": return -operand;
            case "+": return operand;  // 一元加号，直接返回操作数
            default: throw "Unknown unary operator: " + op;
        }
    }
    
    private function callFunction(name:String, args:Array<ASTNode>):Dynamic {
        if (functions.exists(name)) {
            var func = functions.get(name);
            var evaluatedArgs = [];
            for (arg in args) {
                evaluatedArgs.push(evaluate(arg));
            }
            return func.call(evaluatedArgs);
        }
        
        // 内置函数
        switch (name) {
            case "print":
                var values = [];
                for (arg in args) {
                    values.push(evaluate(arg));
                }
                // trace(values.join(" "));
                return null;
                
            case "len":
                if (args.length != 1) throw "len() takes exactly one argument";
                var obj = evaluate(args[0]);
                if (Std.isOfType(obj, Array)) {
                    return (cast obj:Array<Dynamic>).length;
                } else if (Std.isOfType(obj, String)) {
                    return (cast obj:String).length;
                }
                throw "object has no len()";
                
            default:
                // 检查是否是变量中的函数
                try {
                    var func = getVariable(name);
                    if (Std.isOfType(func, PythonFunction)) {
                        // 如果是PythonFunction，直接调用
                        var pythonFunc:PythonFunction = cast func;
                        var evaluatedArgs = [];
                        for (arg in args) {
                            evaluatedArgs.push(evaluate(arg));
                        }
                        return pythonFunc.call(evaluatedArgs);
                    } else if (Reflect.isFunction(func)) {
                        var evaluatedArgs = [];
                        for (arg in args) {
                            evaluatedArgs.push(evaluate(arg));
                        }
                        return Reflect.callMethod(null, func, evaluatedArgs);
                    }
                } catch (e:Dynamic) {
                    // 变量不存在，继续抛出未知函数错误
                }
                
                // 检查Python内置函数
                var evaluatedArgs = [];
                for (arg in args) {
                    evaluatedArgs.push(evaluate(arg));
                }
                
                switch (name) {
                    case "str":
                        if (evaluatedArgs.length > 0) {
                            return Std.string(evaluatedArgs[0]);
                        }
                        return "";
                    case "int":
                        if (evaluatedArgs.length > 0) {
                            var val = evaluatedArgs[0];
                            if (Std.isOfType(val, Int)) return val;
                            if (Std.isOfType(val, Float)) return Math.floor(cast(val, Float));
                            if (Std.isOfType(val, String)) {
                                var parsed = Std.parseInt(val);
                                return parsed != null ? parsed : 0;
                            }
                        }
                        return 0;
                    case "len":
                        if (evaluatedArgs.length > 0) {
                            var val = evaluatedArgs[0];
                            if (Std.isOfType(val, Array)) {
                                var arr:Array<Dynamic> = cast val;
                                return arr.length;
                            }
                            if (Std.isOfType(val, String)) {
                                var str:String = cast val;
                                return str.length;
                            }
                        }
                        return 0;
                    case "range":
                        var result = [];
                        if (evaluatedArgs.length == 1) {
                            // range(stop)
                            var end = Std.int(Std.parseFloat(Std.string(evaluatedArgs[0])));
                            for (i in 0...end) {
                                result.push(i);
                            }
                        } else if (evaluatedArgs.length == 2) {
                            // range(start, stop)
                            var start = Std.int(Std.parseFloat(Std.string(evaluatedArgs[0])));
                            var end = Std.int(Std.parseFloat(Std.string(evaluatedArgs[1])));
                            for (i in start...end) {
                                result.push(i);
                            }
                        } else if (evaluatedArgs.length == 3) {
                            // range(start, stop, step)
                            var start = Std.int(Std.parseFloat(Std.string(evaluatedArgs[0])));
                            var end = Std.int(Std.parseFloat(Std.string(evaluatedArgs[1])));
                            var step = Std.int(Std.parseFloat(Std.string(evaluatedArgs[2])));
                            
                            if (step == 0) {
                                throw "range() step argument must not be zero";
                            }
                            
                            if (step > 0) {
                                var i = start;
                                while (i < end) {
                                    result.push(i);
                                    i += step;
                                }
                            } else {
                                var i = start;
                                while (i > end) {
                                    result.push(i);
                                    i += step; // step is negative
                                }
                            }
                        }
                        return result;
                    default:
                        throw "Unknown function: " + name;
                }
        }
    }
    
    private function getProperty(obj:Dynamic, property:String):Dynamic {
        if (obj == null) {
            throw "Cannot access property '" + property + "' of null";
        }
        
        if (Reflect.hasField(obj, property)) {
            return Reflect.field(obj, property);
        } else {
            throw "Property '" + property + "' does not exist on object";
        }
    }
    
    private function callMethod(obj:Dynamic, methodName:String, args:Array<ASTNode>):Dynamic {
        var argValues = [];
        for (arg in args) {
            argValues.push(evaluate(arg));
        }
        
        if (obj == null) {
            throw "Cannot call method '" + methodName + "' on null";
        }
        
        // 为Array添加Python方法支持
        if (Std.isOfType(obj, Array)) {
            var arr:Array<Dynamic> = cast obj;
            switch (methodName) {
                case "append":
                    if (argValues.length > 0) {
                        arr.push(argValues[0]);
                        return null;
                    }
                case "extend":
                    if (argValues.length > 0 && Std.isOfType(argValues[0], Array)) {
                        var other:Array<Dynamic> = cast argValues[0];
                        for (item in other) {
                            arr.push(item);
                        }
                        return null;
                    }
                case "pop":
                    return arr.length > 0 ? arr.pop() : null;
                case "remove":
                    if (argValues.length > 0) {
                        arr.remove(argValues[0]);
                        return null;
                    }
                case "clear":
                    arr.splice(0, arr.length);
                    return null;
            }
        }
        
        if (Reflect.hasField(obj, methodName)) {
            var method = Reflect.field(obj, methodName);
            if (Std.isOfType(method, PythonFunction)) {
                // 如果是PythonFunction，直接调用
                var pythonFunc:PythonFunction = cast method;
                return pythonFunc.call(argValues);
            } else if (Reflect.isFunction(method)) {
                return Reflect.callMethod(obj, method, argValues);
            } else {
                throw "'" + methodName + "' is not a method";
            }
        } else {
            throw "Method '" + methodName + "' does not exist on object";
        }
    }
    
    private function isTruthy(value:Dynamic):Bool {
        if (value == null) return false;
        if (Std.isOfType(value, Bool)) return cast value;
        if (Std.isOfType(value, Float)) return cast(value, Float) != 0;
        if (Std.isOfType(value, Int)) return cast(value, Int) != 0;
        if (Std.isOfType(value, String)) return cast(value, String) != "";
        if (Std.isOfType(value, Array)) return (cast value:Array<Dynamic>).length > 0;
        return true;
    }
    
    private function evaluateListLiteral(node:ASTNode):Array<Dynamic> {
        var result = [];
        for (element in node.elements) {
            result.push(evaluate(element));
        }
        return result;
    }
    
    private function evaluateDictLiteral(node:ASTNode):haxe.ds.StringMap<Dynamic> {
        var result = new haxe.ds.StringMap<Dynamic>();
        for (pair in node.elements) {
            if (pair.type == NodeType.KeyValue) {
                var key = Std.string(evaluate(pair.key));
                var value = evaluate(pair.value);
                result.set(key, value);
            }
        }
        return result;
    }
    
    private function getIndexedValue(obj:Dynamic, index:Dynamic):Dynamic {
        if (Std.isOfType(obj, Array)) {
            var arr:Array<Dynamic> = cast obj;
            var idx:Int = 0;
            
            // 简单的索引转换
            if (Std.isOfType(index, Int)) {
                idx = cast(index, Int);
            } else {
                // 尝试转换为整数
                try {
                    idx = Std.parseInt(Std.string(index));
                    if (idx == null) idx = 0;
                } catch (e:Dynamic) {
                    idx = 0;
                }
            }
            
            if (idx >= 0 && idx < arr.length) {
                return arr[idx];
            }
            return null;
        }
        
        // 对于Map字典
        // 对于Map字典
        if (Std.isOfType(obj, haxe.ds.StringMap)) {
            var map:haxe.ds.StringMap<Dynamic> = cast obj;
            var key = Std.string(index);
            return map.get(key);
        }
        
        // 对于字典/对象，使用反射
        if (obj != null) {
            var key = Std.string(index);
            return Reflect.field(obj, key);
        }
        
        return null;
    }
}
