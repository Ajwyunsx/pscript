package pyscript.core;

import Sys;
import pyscript.utils.Token;
import pyscript.ast.ASTNode;
import pyscript.ast.NodeType;
import pyscript.utils.Exceptions;
import pyscript.utils.SafeComparison;
import pyscript.utils.ListMethods;

/**
 * Python interpreter
 * Executes AST nodes and maintains runtime environment
 */
class Interpreter {
    // Variable scopes
    public var globals:Map<String, Dynamic>;
    public var locals:Map<String, Dynamic>;
    
    // Function definitions
    private var functions:Map<String, Dynamic>;
    
    // Error state
    public var fatalError:Bool;
    
    // Current self object (for super() support)
    public var currentSelf:PythonObject;
    
    // Custom callbacks
    public var customErrorHandler:String->Void = null;
    
    // Scope tracking for proper variable handling
    public var currentFunctionName:String;
    public var isGlobalVariable:Map<String, Bool>;
    public var isLocalVariable:Map<String, Bool>;
    public var functionCallDepth:Int;
    
    // Track explicitly defined variables to distinguish from undefined ones
    private var explicitlyDefined:Map<String, Bool>;
    
    // Protected objects system - prevents critical objects from being converted to strings
    private var protectedObjects:Array<Dynamic>;
    
    // Haxe class registry for Python interop
    private var haxeClassRegistry:Map<String, Class<Dynamic>>;
    
    // CPP目标对象跟踪系统
    #if cpp
    private static var objectTracker:Map<Int, Dynamic> = new Map<Int, Dynamic>();
    private static var nextObjectId:Int = 1;
    #end
    
    
    // Helper function to check if object is an array
    private function isArray(obj:Dynamic):Bool {
        return Std.isOfType(obj, Array) || (Reflect.hasField(obj, "length") && Reflect.isFunction(obj.push) && !Std.isOfType(obj, String));
    }
    
    // Helper function to safely cast to array
    private function asArray(obj:Dynamic):Array<Dynamic> {
        if (Std.isOfType(obj, Array)) {
            return cast(obj, Array<Dynamic>);
        }
#if !cpp
        return cast(obj, Array<Dynamic>);
#else
        // For C++, try to avoid the problematic cast
        try {
            return cast(obj, Array<Dynamic>);
        } catch (e:Dynamic) {
            // If cast fails, return empty array
            return [];
        }
#end
    }
    public var customPrintHandler:Int->String->Void = null;
    
    // Current execution position
    private var currentLine:Int = 0;
    
    /**
     * Constructor
     */
    public function new() {
        globals = new Map<String, Dynamic>();
        locals = new Map<String, Dynamic>();
        functions = new Map<String, Dynamic>();
        fatalError = false;
        currentSelf = null;
        
        // 初始化作用域跟踪
        currentFunctionName = null;
        isGlobalVariable = new Map<String, Bool>();
        isLocalVariable = new Map<String, Bool>();
        functionCallDepth = 0;
        protectedObjects = new Array<Dynamic>();
        explicitlyDefined = new Map<String, Bool>();
        haxeClassRegistry = new Map<String, Class<Dynamic>>();
        
        // 初始化内置函数和变量
        initBuiltins();
    }
    
    /**
     * Protect an object from being converted to string
     */
    public function protectObject(obj:Dynamic):Void {
        if (obj != null && !isProtected(obj)) {
            protectedObjects.push(obj);
        }
    }
    
    /**
     * Unprotect an object
     */
    public function unprotectObject(obj:Dynamic):Void {
        if (obj != null) {
            for (i in 0...protectedObjects.length) {
                if (protectedObjects[i] == obj) {
                    protectedObjects.splice(i, 1);
                    break;
                }
            }
        }
    }
    
    /**
     * Check if an object is protected
     */
    public function isProtected(obj:Dynamic):Bool {
        if (obj == null) return false;
        
        // First check explicit protection
        for (protectedObj in protectedObjects) {
            if (protectedObj == obj) {
                return true;
            }
        }
        
        // Then check if it's a Haxe object that should be protected
        return isHaxeObject(obj);
    }
    
    /**
     * Check if object is a Haxe object (not primitive type)
     */
    private function isHaxeObject(obj:Dynamic):Bool {
        if (obj == null) return false;
        
        // CPP目标特殊处理：检查是否是包装器
        #if cpp
        if (Reflect.hasField(obj, "__wrappedObject") || Reflect.hasField(obj, "__objectId")) {
            return true;
        }
        #end
        
        var type = Type.typeof(obj);
        return switch (type) {
            case TUnknown: false;
            case TInt: false;
            case TFloat: false;
            case TBool: false;
            case TFunction: false;
            case TObject: true;  // This is most Haxe objects
            case TClass(c): 
                // 基础类型不需要保护
                var className = Type.getClassName(c);
                return !(
                    className == "String" || 
                    className == "Array" ||
                    className == "Date" ||
                    className == "StringBuf" ||
                    className == "haxe.ds.StringMap" ||
                    className == "haxe.ds.IntMap" ||
                    className == "haxe.ds.ObjectMap" ||
                    className == "haxe.ds.EnumValueMap" ||
                    className == "haxe.ds.Vector" ||
                    className == "Math" ||
                    className == "Std" ||
                    className == "StringTools" ||
                    className == "Reflect" ||
                    className == "Type" ||
                    className == "Json"
                );
            case TEnum(_): false;
            case TNull: false;
        }
    }
    
    /**
     * Safely get property from Haxe object
     */
    private function getHaxeObjectProperty(obj:Dynamic, attr:String):Dynamic {
        #if cpp
        // CPP目标特殊处理：更宽松的属性访问
        try {
            // 检查是否是ID包装器
            if (Reflect.hasField(obj, "__objectId")) {
                var getInstanceFunc = Reflect.field(obj, "__getInstance");
                var realObj = Reflect.callMethod(obj, getInstanceFunc, []);
                if (realObj != null) {
                    return getHaxeObjectProperty(realObj, attr);
                }
                return null;
            }
            
            // 检查是否是旧的包装器
            if (Reflect.hasField(obj, "__wrappedObject")) {
                var wrappedObj = Reflect.field(obj, "__wrappedObject");
                if (Reflect.hasField(obj, "__getProperty")) {
                    var getPropertyFunc = Reflect.field(obj, "__getProperty");
                    return Reflect.callMethod(obj, getPropertyFunc, [attr]);
                } else {
                    return getHaxeObjectProperty(wrappedObj, attr);
                }
            }
            
            // 首先尝试直接反射访问
            if (Reflect.hasField(obj, attr)) {
                return Reflect.field(obj, attr);
            }
            
            // CPP目标特殊处理：如果Reflect.hasField失败，尝试直接访问
            #if cpp
            try {
                var result = Reflect.field(obj, attr);
                if (result != null) {
                    return result;
                }
            } catch (e:Dynamic) {
                // 访问失败，继续其他方法
            }
            #end
            
            // 特殊处理toString方法
            if (attr == "toString") {
                return function() {
                    // 直接调用对象的toString方法，避免Std.string()
                    if (Reflect.hasField(obj, "toString") && Reflect.isFunction(Reflect.field(obj, "toString"))) {
                        return Reflect.callMethod(obj, Reflect.field(obj, "toString"), []);
                    } else {
                        return "[HaxeObject " + Type.getClassName(Type.getClass(obj)) + "]";
                    }
                };
            }
            
            // 尝试通过getter方法
            var getterName = "get_" + attr;
            if (Reflect.hasField(obj, getterName)) {
                var getter = Reflect.field(obj, getterName);
                if (Reflect.isFunction(getter)) {
                    return Reflect.callMethod(obj, getter, []);
                }
            }
            
            // 如果都失败了，返回null而不是抛出异常
            return null;
        } catch (e:Dynamic) {
            // 任何异常都返回null
            return null;
        }
        #else
        // 非CPP目标的标准处理
        try {
            if (Reflect.hasField(obj, attr)) {
                return Reflect.field(obj, attr);
            }
            
            var getterName = "get_" + attr;
            if (Reflect.hasField(obj, getterName)) {
                var getter = Reflect.field(obj, getterName);
                if (Reflect.isFunction(getter)) {
                    return Reflect.callMethod(obj, getter, []);
                }
            }
            
            return null;
        } catch (e:Dynamic) {
            return null;
        }
        #end
    }
    
    /**
     * Safely set property on Haxe object
     */
    private function setHaxeObjectProperty(obj:Dynamic, attr:String, value:Dynamic):Bool {
        #if cpp
        // CPP目标特殊处理：更宽松的属性设置
        try {
            Reflect.setProperty(obj, attr, value);
            return true;
        } catch (e:Dynamic) {
            return false;
        }
        #else
        // 非CPP目标的标准处理
        try {
            Reflect.setProperty(obj, attr, value);
            return true;
        } catch (e:Dynamic) {
            return false;
        }
        #end
    }
    
    /**
     * Initialize built-in functions and variables
     */
    private function initBuiltins():Void {
        // Built-in constants
        globals.set("True", true);
        globals.set("False", false);
        globals.set("None", null);
        
        // Built-in functions - store markers in globals
        globals.set("print", "__builtin__");
        globals.set("len", "__builtin__");
        globals.set("str", "__builtin__");
        globals.set("int", "__builtin__");
        globals.set("float", "__builtin__");
        globals.set("bool", "__builtin__");
        globals.set("list", "__builtin__");
        globals.set("dict", "__builtin__");
        globals.set("range", "__builtin__");
        
        // Additional built-in functions
        globals.set("sum", "__builtin__");
        globals.set("max", "__builtin__");
        globals.set("min", "__builtin__");
        globals.set("abs", "__builtin__");
        globals.set("round", "__builtin__");
        globals.set("pow", "__builtin__");
        globals.set("type", "__builtin__");
        globals.set("isinstance", "__builtin__");
        globals.set("chr", "__builtin__");
        globals.set("ord", "__builtin__");
        globals.set("hex", "__builtin__");
        globals.set("oct", "__builtin__");
        globals.set("bin", "__builtin__");
        globals.set("super", "__builtin__");
        
        // 标记所有内置变量为明确定义
        markBuiltinsAsExplicitlyDefined();
    }
    
    /**
     * 标记所有内置变量为明确定义
     */
    private function markBuiltinsAsExplicitlyDefined():Void {
        var builtinNames = [
            "True", "False", "None",
            "print", "len", "str", "int", "float", "bool", "list", "dict", "range",
            "sum", "max", "min", "abs", "round", "pow", "type", "isinstance",
            "chr", "ord", "hex", "oct", "bin", "super"
        ];
        
        for (name in builtinNames) {
            explicitlyDefined.set(name, true);
        }
    }
    
    /**
     * Execute code
     * @param code Code to execute
     * @return Execution result
     */
    public function run(code:String):Dynamic {
        try {
            var lexer = new Lexer();
            lexer.setSource(code);
            var tokens = lexer.tokenize();
            
            var parser = new Parser();
            parser.setTokens(tokens);
            var ast = parser.parse();
            
            var result = evaluate(ast);
            return result;
        } catch (e:Dynamic) {
            fatalError = true;
            throw e;
        }
    }
    
    /**
     * Evaluate AST node
     * @param node Node to evaluate
     * @return Evaluation result
     */
    public function evaluate(node:ASTNode):Dynamic {
        if (node == null) {
            return null;
        }
        
        // Update current line number
        if (node.startLine > 0) {
            currentLine = node.startLine;
        }
        
        try {
            switch (node.type) {
                case NodeType.Program:
                    return evaluateProgram(node);
                    
                case NodeType.ExpressionStatement:
                    return evaluate(node.expression);
                    
                case NodeType.Block:
                    var result:Dynamic = null;
                    if (node.statements != null) {
                        for (stmt in node.statements) {
                            result = evaluate(stmt);
                        }
                    }
                    return result;
                    
                case NodeType.Literal:
                    return node.value;
                    
                case NodeType.Identifier:
                    return getVariable(node.name);
                    
                case NodeType.Assignment:
                    return evaluateAssignment(node);
                    
                case NodeType.PropertyAssignment:
                    return evaluatePropertyAssignment(node);
                    
                case NodeType.IndexAssignment:
                    return evaluateIndexAssignment(node);
                    
                case NodeType.BinaryOp:
                    return evaluateBinaryOp(node);
                    
                case NodeType.UnaryOp:
                    return evaluateUnaryOp(node);
                    
                case NodeType.FunctionCall:
                    return evaluateFunctionCall(node);
                    
                case NodeType.PropertyAccess:
                    return evaluatePropertyAccess(node);
                    
                case NodeType.IndexAccess:
                    return evaluateIndexAccess(node);
                    
                case NodeType.Slice:
                    return evaluateSlice(node);
                    
                case NodeType.ListLiteral:
                    return evaluateListLiteral(node);
                    
                case NodeType.DictLiteral:
                    return evaluateDictLiteral(node);
                    
                case NodeType.IfStatement:
                    return evaluateIfStatement(node);
                    
                case NodeType.ElifBranch:
                    // ElifBranch nodes should be handled within evaluateIfStatement
                    throw "ElifBranch should not be evaluated directly";
                    
                case NodeType.WhileStatement:
                    return evaluateWhileStatement(node);
                    
                case NodeType.ForStatement:
                    return evaluateForStatement(node);
                    
                case NodeType.TryStatement:
                    return evaluateTryStatement(node);
                    
                case NodeType.FunctionDef:
                    return evaluateFunctionDef(node);
                    
                case NodeType.ClassDef:
                    return evaluateClassDef(node);
                    
                case NodeType.ReturnStatement:
                    return evaluateReturnStatement(node);
                    
                case NodeType.BreakStatement:
                    throw new BreakException();
                    
                case NodeType.ContinueStatement:
                    throw new ContinueException();
                    
                default:
                    throw "Unsupported node type: " + node.type + " at line " + currentLine;
            }
        } catch (e:ReturnException) {
            throw e;
        } catch (e:BreakException) {
            throw e;
        } catch (e:ContinueException) {
            throw e;
        } catch (e:Dynamic) {
            fatalError = true;
            throw e;
        }
    }
    
    /**
     * 评估程序节点
     */
    private function evaluateProgram(node:ASTNode):Dynamic {
        var result = null;
        
        if (node.body != null) {
            for (i in 0...node.body.length) {
                var stmt = node.body[i];
                
                result = evaluate(stmt);
                
            }
        }
        return result;
    }
    
    /**
     * 评估赋值节点
     */
    private function evaluateAssignment(node:ASTNode):Dynamic {
        var value = evaluate(node.value);
        
        // 处理复合赋值操作符
        if (node.op != null && node.op != "=") {
            value = evaluateCompoundAssignment(node.op, getVariable(node.name), value);
        }
        
        // CPP目标特殊处理：保护Haxe对象不被转换为字符串
        #if cpp
        if (isHaxeObject(value)) {
            protectObject(value);
        }
        #end
        
        setVariable(node.name, value);
        return value;
    }
    
    /**
     * 评估复合赋值操作
     * @param op 操作符
     * @param currentValue 当前值
     * @param newValue 新值
     * @return 计算结果
     */
    private function evaluateCompoundAssignment(op:String, currentValue:Dynamic, newValue:Dynamic):Dynamic {
        // CPP目标特殊处理：检查当前值是否是被错误转换为字符串的对象
        #if cpp
        if (Std.isOfType(currentValue, String)) {
            var strVal = cast(currentValue, String);
            // 检查这个字符串是否看起来像被错误转换的对象
            if (strVal.indexOf("=>") != -1 || strVal.indexOf("{") != -1 || strVal.indexOf("}") != -1) {
                // 这很可能是一个被错误转换为字符串的对象
                // 尝试从全局作用域恢复原始对象
                var recoveredObj = recoverFromObjectString(strVal);
                if (recoveredObj != null) {
                    currentValue = recoveredObj;
                }
            }
        }
        #end
        
        switch (op) {
            case "+=":
                if (Std.isOfType(currentValue, String) || Std.isOfType(newValue, String)) {
                    return Std.string(currentValue) + Std.string(newValue);
                } else {
                    return toNumber(currentValue) + toNumber(newValue);
                }
            case "-=":
                return toNumber(currentValue) - toNumber(newValue);
            case "*=":
                if (Std.isOfType(currentValue, String) && Std.isOfType(newValue, Int)) {
                    var str = cast(currentValue, String);
                    var count = cast(newValue, Int);
                    var result = "";
                    for (i in 0...count) {
                        result += str;
                    }
                    return result;
                } else {
                    return toNumber(currentValue) * toNumber(newValue);
                }
            case "/=":
                return toNumber(currentValue) / toNumber(newValue);
            case "%=":
                return toNumber(currentValue) % toNumber(newValue);
            case "**=":
                return Math.pow(toNumber(currentValue), toNumber(newValue));
            default:
                return newValue;
        }
    }
    
    /**
     * 评估属性赋值节点
     */
    private function evaluatePropertyAssignment(node:ASTNode):Dynamic {
        // 对于属性赋值，node.object包含对象，node.attr包含属性名
        var obj = evaluate(node.object);
        var attr = node.attr;
        var value = evaluate(node.value);
        
        // 检查对象是否为null
        if (obj == null) {
            // 检查是否是因为访问未定义变量导致的
            if (node.object.type == NodeType.Identifier) {
                var varName = node.object.name;
                if (!explicitlyDefined.exists(varName) && !globals.exists(varName)) {
                    throw new AttributeError("NameError: name '" + varName + "' is not defined");
                }
            }
            throw new AttributeError("'NoneType' object has no attribute '" + attr + "'");
        }
        
        // 处理复合赋值操作符
        if (node.op != null && node.op != "=") {
            var currentValue:Dynamic = null;
            
            // 获取当前属性值
            if (Std.isOfType(obj, PythonDict)) {
                var dict = cast(obj, PythonDict);
                currentValue = dict.getProperty(attr);
            } else if (Std.isOfType(obj, PythonObject)) {
                var pyObj = cast(obj, PythonObject);
                currentValue = pyObj.getProperty(attr);
            } else {
                currentValue = Reflect.getProperty(obj, attr);
            }
            
            value = evaluateCompoundAssignment(node.op, currentValue, value);
        }
        
        if (Std.isOfType(obj, PythonDict)) {
            var dict = cast(obj, PythonDict);
            dict.setProperty(attr, value);
            return value;
        }
        
        if (Std.isOfType(obj, PythonObject)) {
            var pyObj = cast(obj, PythonObject);
            pyObj.setProperty(attr, value);
            return value;
        }
        
        // CPP目标特殊处理：检查是否是对象被错误转换为字符串
#if cpp
        if (Std.isOfType(obj, String)) {
            var strObj = cast(obj, String);
            // 检查这个字符串是否看起来像被错误转换的对象
            if (strObj.indexOf("=>") != -1 || strObj.indexOf("{") != -1 || strObj.indexOf("}") != -1) {
                // 这很可能是一个被错误转换为字符串的对象
                // 尝试从全局作用域恢复原始对象
                var recoveredObj = recoverFromObjectString(strObj);
                if (recoveredObj != null) {
                    // 使用恢复的对象进行属性访问
                    if (Reflect.hasField(recoveredObj, attr)) {
                        return Reflect.getProperty(recoveredObj, attr);
                    }
                }
            }
            throw new AttributeError("'str' object has no attribute '" + attr + "'");
        }
#end
        
        // 对于基本类型，不允许属性赋值，但提供更好的错误信息
        if (Std.isOfType(obj, String)) {
            throw new AttributeError("'str' object has no attribute '" + attr + "'");
        } else if (Std.isOfType(obj, Int)) {
            throw new AttributeError("'int' object has no attribute '" + attr + "'");
        } else if (Std.isOfType(obj, Float)) {
            throw new AttributeError("'float' object has no attribute '" + attr + "'");
        } else if (Std.isOfType(obj, Bool)) {
            throw new AttributeError("'bool' object has no attribute '" + attr + "'");
        }
        
        // 对于Haxe对象，使用安全的方法设置属性
        if (isHaxeObject(obj)) {
            if (setHaxeObjectProperty(obj, attr, value)) {
                return value;
            } else {
                // 设置失败，静默处理
                return value;
            }
        }
        
        // 尝试使用反射
        // Use Reflect.setProperty for more flexible property assignment
        Reflect.setProperty(obj, attr, value);
        return value;
        
        // Try to find similar attributes for better error messages
        var suggestion = "";
        var availableAttrs = [];
        if (Reflect.isObject(obj)) {
            var fields = Reflect.fields(obj);
            
            // Look for case-insensitive matches (but not the exact same name)
            for (field in fields) {
                availableAttrs.push(field);
                if (field.toLowerCase() == attr.toLowerCase() && field != attr) {
                    suggestion = " (did you mean '" + field + "'?)";
                    break;
                }
            }
        }
        
        // If no suggestion found, show some available attributes
        if (suggestion == "" && availableAttrs.length > 0) {
            var sample = availableAttrs.slice(0, Std.int(Math.min(5, availableAttrs.length)));
            suggestion = " (available attributes: " + sample.join(", ") + (availableAttrs.length > 5 ? ", ..." : "") + ")";
        }
        
        throw new AttributeError("'" + getTypeName(obj) + "' object has no attribute '" + attr + "'" + suggestion);
    }
    
    /**
     * 获取对象的类型名称
     */
    private function getTypeName(obj:Dynamic):String {
        if (obj == null) return "NoneType";
        
        var type = Type.typeof(obj);
        
        // Check type before specific checks to avoid conflicts
        switch (type) {
            case TNull: return "NoneType";
            case TInt: return "int";
            case TFloat: return "float";
            case TBool: return "bool";
            case TFunction: return "function";
            case TClass(c):
                var className = Type.getClassName(c).split(".").pop();
                // Handle special cases
                switch (className) {
                    case "String": return "str";
                    case "Array": return "list";
                    case "List": return "list";
                    case "Int": return "int";
                    case "Float": return "float";
                    case "Bool": return "bool";
                    default: return className;
                }
            case TEnum(e): return Type.getEnumName(e).split(".").pop();
            case TObject: 
                // Check if it's a Python-specific type
                if (Std.isOfType(obj, PythonDict)) return "dict";
                if (Std.isOfType(obj, PythonClass)) {
                    try {
                        var pyClass = cast(obj, PythonClass);
                        return pyClass.name;
                    } catch (e:Dynamic) {
                        return "type";
                    }
                }
                if (Std.isOfType(obj, PythonObject)) return "object";
                return "object";
            default: return Std.string(type);
        }
    }
    
    /**
     * 评估索引赋值节点
     */
    private function evaluateIndexAssignment(node:ASTNode):Dynamic {
        var obj = evaluate(node.object);
        var index = evaluate(node.index);
        var value = evaluate(node.value);
        
        if (Std.isOfType(obj, PythonDict)) {
            var dict = cast(obj, PythonDict);
            dict.set(index, value);
            return value;
        } else if (Std.isOfType(obj, String)) {
            // String assignment not supported in Python
            throw "TypeError: 'str' object does not support item assignment";
        } else if (isArray(obj)) {
            var arr = asArray(obj);
            arr[Std.int(index)] = value;
            return value;
        }
        
        throw "Cannot assign to non-indexable object: " + obj;
    }
    
    /**
     * 创建方法的包装器
     */
    private function makeMethodWrapper(func:Array<Dynamic>->Dynamic):Dynamic {
        return function(?args:Array<Dynamic>) {
            if (args == null) args = [];
            return func(args);
        };
    }
    
    /**
     * 创建列表方法的包装器（保持向后兼容）
     */
    private function makeListMethod(func:Array<Dynamic>->Dynamic):Dynamic {
        return makeMethodWrapper(func);
    }
    
    /**
     * 评估二元操作节点
     */
    private function evaluateBinaryOp(node:ASTNode):Dynamic {
        var left = evaluate(node.left);
        var right = evaluate(node.right);
        var op = node.op;
        
        switch (op) {
            case "+": 
                // String concatenation
                if (Std.isOfType(left, String) || Std.isOfType(right, String)) {
                    #if cpp
                    // CPP目标特殊处理：确保Haxe对象正确转换为字符串
                    var leftStr = Std.string(left);
                    var rightStr = Std.string(right);
                    // 如果是Haxe对象，尝试调用toString方法
                    if (isHaxeObject(left)) {
                        leftStr = getHaxeObjectProperty(left, "toString")();
                    }
                    if (isHaxeObject(right)) {
                        rightStr = getHaxeObjectProperty(right, "toString")();
                    }
                    return leftStr + rightStr;
                    #else
                    return Std.string(left) + Std.string(right);
                    #end
                }
                // Numeric addition
                return toNumber(left) + toNumber(right);
            case "-": 
                return toNumber(left) - toNumber(right);
            case "*": 
                // 字符串重复处理
                if (Std.isOfType(left, String) && Std.isOfType(right, Int)) {
                    var str = cast(left, String);
                    var count = cast(right, Int);
                    var result = "";
                    for (i in 0...count) {
                        result += str;
                    }
                    return result;
                } else if (Std.isOfType(right, String) && Std.isOfType(left, Int)) {
                    var str = cast(right, String);
                    var count = cast(left, Int);
                    var result = "";
                    for (i in 0...count) {
                        result += str;
                    }
                    return result;
                }
                return toNumber(left) * toNumber(right);
            case "/": 
                return toNumber(left) / toNumber(right);
            case "//": 
                return Math.floor(toNumber(left) / toNumber(right));
            case "%": 
                return toNumber(left) % toNumber(right);
            case "**": 
                return Math.pow(toNumber(left), toNumber(right));
            case "==": 
                return SafeComparison.safeEquals(left, right);
                
            case "!=": 
                return SafeComparison.safeNotEquals(left, right);
                
            case "<": 
                return SafeComparison.safeLessThan(left, right);
                
            case "<=": 
                return SafeComparison.safeLessThanOrEqual(left, right);
                
            case ">": 
                return SafeComparison.safeGreaterThan(left, right);
                
            case ">=": 
                return SafeComparison.safeGreaterThanOrEqual(left, right);
            case "and": return isTruthy(left) ? right : left;
            case "or": return isTruthy(left) ? left : right;
            default: throw "Unsupported operator: " + op;
        }
    }
    
    /**
     * 评估一元操作节点
     */
    private function evaluateUnaryOp(node:ASTNode):Dynamic {
        var operand = evaluate(node.operand);
        var op = node.op;
        
        switch (op) {
            case "-": return -operand;
            case "not": return !isTruthy(operand);
            case "~": return ~operand;
            default: throw "Unsupported unary operator: " + op;
        }
    }
    
    /**
     * 评估函数调用节点
     */
    private function evaluateFunctionCall(node:ASTNode):Dynamic {
        // 检查是否是方法调用（有name属性）
        if (node.name != null && node.name.length > 0) {
            // 这是方法调用，node.object是目标对象，node.name是方法名
            var target = evaluate(node.object);
            var methodName = node.name;
            
            // 创建临时的PropertyAccess节点来获取方法
            var propAccessNode = new ASTNode(NodeType.PropertyAccess);
            propAccessNode.object = node.object;
            propAccessNode.attr = methodName;
            
            var func = evaluatePropertyAccess(propAccessNode);
            
            var args = new Array<Dynamic>();
            if (node.arguments != null) {
                for (arg in node.arguments) {
                    args.push(evaluate(arg));
                }
            }
            
            // 调用方法
            if (Std.isOfType(func, BoundMethod)) {
                return cast(func, BoundMethod).call(this, args);
            } else if (Std.isOfType(func, PythonFunction)) {
                return cast(func, PythonFunction).call(this, args);
            } else if (Std.isOfType(func, SuperProxy)) {
                // 对于super()调用，我们需要方法名
                if (methodName != null) {
                    var superProxy = cast(func, SuperProxy);
                    var method = superProxy.resolveMethod(methodName);
                    return cast(method, BoundMethod).call(this, args);
                } else {
                    throw "super() requires a method name";
                }
            } else {
                // 直接尝试调用
                try {
                    #if cpp
                    // CPP目标特殊处理：检查是否是Haxe对象方法
                    if (Reflect.isFunction(func)) {
                        var targetObj = evaluate(node.object);
                        if (targetObj != null) {
                            return Reflect.callMethod(targetObj, func, args);
                        }
                    }
                    #end
                    return func(args);
                } catch (e:Dynamic) {
                    throw "Method call failed: " + e;
                }
            }
        }
        
        // 普通函数调用 - 静默处理未定义函数
        var func = null;
        try {
            func = evaluate(node.object);
        } catch (e:Dynamic) {
            // 任何异常都静默处理，返回null
            return null;
        }
        
        // 如果函数为null或undefined，优雅处理
        if (func == null) {
            return null;
        }
        
        var args = new Array<Dynamic>();
        
        if (node.arguments != null) {
            for (arg in node.arguments) {
                args.push(evaluate(arg));
            }
        }
        
        // 直接调用函数
        try {
            // 检查是否是内置函数
            if (Std.isOfType(func, String) && cast(func, String).indexOf("builtin:") == 0) {
                var builtinName = cast(func, String).substr(8);
                switch (builtinName) {
                    case "print": return this.print(args);
                    case "len": return this.len(args);
                    case "str": return this.str(args);
                    case "int": return this.int(args);
                    case "float": return this.float(args);
                    case "bool": return this.bool(args);
                    case "list": return this.list(args);
                    case "dict": return this.dict(args);
                    case "range": return this.range(args);
                    case "sum": return this.sum(args);
                    case "max": return this.max(args);
                    case "min": return this.min(args);
                    case "abs": return this.abs(args);
                    case "round": return this.round(args);
                    case "pow": return this.pow(args);
                    case "type": return this.type(args);
                    case "isinstance": return this.isinstance(args);
                    case "chr": return this.chr(args);
                    case "ord": return this.ord(args);
                    case "hex": return this.hex(args);
                    case "oct": return this.oct(args);
                    case "bin": return this.bin(args);
                    case "super": return this.superFunc(args);
                    default: throw "Unknown builtin function: " + builtinName;
                }
            } else if (Std.isOfType(func, PythonClass)) {
                // 对于Python类 - 创建实例
                return cast(func, PythonClass).createInstance(this, args);
            } else if (Std.isOfType(func, PythonFunction)) {
                // 对于Python函数
                return cast(func, PythonFunction).call(this, args);
            } else if (Std.isOfType(func, BoundMethod)) {
                // 对于绑定方法
                return cast(func, BoundMethod).call(this, args);
            } else if (func != null && Reflect.hasField(func, "__haxeClass")) {
                // 对于Haxe类包装器
                try {
                    return Reflect.callMethod(func, Reflect.field(func, "__call"), [args]);
                } catch (e:Dynamic) {
                    throw "Haxe class construction failed: " + e;
                }
            } else if (func != null && Reflect.isFunction(func)) {
                // 对于Haxe函数或闭包
                try {
                    return Reflect.callMethod(null, func, args);
                } catch (e:Dynamic) {
                    throw "Function call failed: " + e;
                }
            } else if (func != null && isHaxeObject(func)) {
                // 对于Haxe对象，尝试将其作为函数调用
                try {
                    if (Reflect.isFunction(func)) {
                        return Reflect.callMethod(null, func, args);
                    } else {
                        // 如果不是函数，可能是可调用对象
                        return Reflect.callMethod(func, Reflect.field(func, "call"), args);
                    }
                } catch (e:Dynamic) {
                    throw "Haxe object call failed: " + e;
                }
            } else {
                // 不支持的函数类型，静默返回
                return null;
            }
        } catch (e:Dynamic) {
            // 函数调用失败，静默返回
            return null;
        }
    }
    
    /**
     * 评估属性访问节点
     */
    private function evaluatePropertyAccess(node:ASTNode):Dynamic {
        var obj = evaluate(node.object);
        var attr = node.attr;
        
        // CPP目标特殊处理：检查是否是ID包装器被错误识别为字符串
        #if cpp
        if (Std.isOfType(obj, String) && node.object.type == NodeType.Identifier) {
            // 首先检查是否是ID包装器
            var globalValue = globals.get(node.object.name);
            if (globalValue != null && Reflect.hasField(globalValue, "__objectId")) {
                obj = globalValue;
            } else {
                var varName = node.object.name;
                var globalValue = globals.get(varName);
                // 只有当字符串确实代表一个变量名时才替换
                if (globalValue != null && !Std.isOfType(globalValue, String) && varName == obj) {
                    obj = globalValue;
                }
            }
        }
        #end
        
        // 检查对象是否为null
        if (obj == null) {
            // 检查是否是因为访问未定义变量导致的
            if (node.object.type == NodeType.Identifier) {
                var varName = node.object.name;
                if (!explicitlyDefined.exists(varName) && !globals.exists(varName)) {
                    throw new AttributeError("NameError: name '" + varName + "' is not defined");
                }
            }
            throw new AttributeError("'NoneType' object has no attribute '" + attr + "'");
        }
        
        // 检查是否是SuperProxy对象
        if (Std.isOfType(obj, SuperProxy)) {
            var superProxy = cast(obj, SuperProxy);
            return superProxy.resolveMethod(attr);
        }
        
        // 检查是否是Python字典
        if (Std.isOfType(obj, PythonDict)) {
            var dict = cast(obj, PythonDict);
            return dict.resolveProperty(attr);
        }
        
        // 检查是否是Python对象
        if (Std.isOfType(obj, PythonObject)) {
            var pyObj = cast(obj, PythonObject);
            return pyObj.getProperty(attr);
        }
        
        // 检查是否是Haxe对象
        if (isHaxeObject(obj)) {
            var value = getHaxeObjectProperty(obj, attr);
            if (value != null) {
                // 如果是函数，返回绑定版本
                if (Reflect.isFunction(value)) {
                    return function(?args:Array<Dynamic>) {
                        if (args == null) args = [];
                        return Reflect.callMethod(obj, value, args);
                    };
                }
                return value;
            } else {
                // 属性不存在，返回null而不是抛出异常
                return null;
            }
        }
        
        // 检查是否是Python类
        if (Std.isOfType(obj, PythonClass)) {
            var pyClass = cast(obj, PythonClass);
            // 检查类属性
            if (pyClass.staticProperties.exists(attr)) {
                return pyClass.staticProperties.get(attr);
            }
            // 检查方法
            if (pyClass.methods.exists(attr)) {
                var method = pyClass.methods.get(attr);
                // 如果是静态方法或类方法，直接返回方法
                if (method.isStatic || method.isClassMethod) {
                    return method;
                }
                // 否则返回绑定的实例方法
                var interpreter = this;
                return function(?args:Array<Dynamic>) {
                    var allArgs:Array<Dynamic> = [];
                    if (args != null) {
                        allArgs = allArgs.concat(args);
                    }
                    // 对于实例方法，需要interpreter参数
                    return method.call(interpreter, allArgs);
                };
            }
            throw "AttributeError: type '" + pyClass.name + "' has no attribute '" + attr + "'";
        }
        
        // 检查是否是列表方法
        if (isArray(obj)) {
            var arr = asArray(obj);
            switch (attr) {
                case "append":
                    return makeListMethod(function(args) {
                        if (args.length > 0) ListMethods.append(arr, args[0]);
                        return null;
                    });
                case "extend":
                    return makeListMethod(function(args) {
                        if (args.length > 0 && isArray(args[0])) {
                            ListMethods.extend(arr, asArray(args[0]));
                        }
                        return null;
                    });
                case "insert":
                    return makeListMethod(function(args) {
                        if (args.length >= 2) {
                            ListMethods.insert(arr, Std.int(args[0]), args[1]);
                        }
                        return null;
                    });
                case "remove":
                    return makeListMethod(function(args) {
                        if (args.length > 0) {
                            ListMethods.remove(arr, args[0]);
                        }
                        return null;
                    });
                case "pop":
                    return makeListMethod(function(args) {
                        var index = -1;
                        if (args.length > 0) index = Std.int(args[0]);
                        return ListMethods.pop(arr, index);
                    });
                case "clear":
                    return makeListMethod(function(args) {
                        ListMethods.clear(arr);
                        return null;
                    });
                case "index":
                    return makeListMethod(function(args) {
                        if (args.length > 0) {
                            return ListMethods.index(arr, args[0]);
                        }
                        throw "Value not found in list";
                    });
                case "count":
                    return makeListMethod(function(args) {
                        if (args.length > 0) {
                            return ListMethods.count(arr, args[0]);
                        }
                        return 0;
                    });
                case "sort":
                    return makeListMethod(function(args) {
                        ListMethods.sort(arr);
                        return null;
                    });
                case "reverse":
                    return makeListMethod(function(args) {
                        ListMethods.reverse(arr);
                        return null;
                    });
                case "copy":
                    return makeListMethod(function(args) {
                        return ListMethods.copy(arr);
                    });
            }
        }
        
        // 检查是否是字典方法
        if (Reflect.hasField(obj, "keys") && Reflect.hasField(obj, "get")) {
            switch (attr) {
                case "keys":
                    return function() {
                        var keys = [];
                        for (key in Reflect.fields(obj)) {
                            if (key != "keys" && key != "get" && key != "set") {
                                keys.push(key);
                            }
                        }
                        return keys;
                    };
                case "values":
                    return function() {
                        var values = [];
                        for (key in Reflect.fields(obj)) {
                            if (key != "keys" && key != "get" && key != "set") {
                                values.push(Reflect.field(obj, key));
                            }
                        }
                        return values;
                    };
                case "items":
                    return function() {
                        var items = [];
                        for (key in Reflect.fields(obj)) {
                            if (key != "keys" && key != "get" && key != "set") {
                                items.push([key, Reflect.field(obj, key)]);
                            }
                        }
                        return items;
                    };
                case "get":
                    return function(key:Dynamic, ?defaultValue:Dynamic) {
                        if (Reflect.hasField(obj, safeStringConversion(key))) {
                            return Reflect.field(obj, safeStringConversion(key));
                        }
                        return defaultValue;
                    };
                case "set":
                    return function(key:Dynamic, value:Dynamic) {
                        Reflect.setField(obj, safeStringConversion(key), value);
                        return null;
                    };
                case "pop":
                    return function(key:Dynamic, ?defaultValue:Dynamic) {
                        var keyStr = safeStringConversion(key);
                        if (Reflect.hasField(obj, keyStr)) {
                            var value = Reflect.field(obj, keyStr);
                            Reflect.deleteField(obj, keyStr);
                            return value;
                        }
                        return defaultValue;
                    };
                case "clear":
                    return function() {
                        for (key in Reflect.fields(obj)) {
                            if (key != "keys" && key != "get" && key != "set") {
                                Reflect.deleteField(obj, key);
                            }
                        }
                        return null;
                    };
                case "update":
                    return function(other:Dynamic) {
                        if (Reflect.hasField(other, "keys") && Reflect.hasField(other, "get")) {
                            var keys = Reflect.callMethod(other, Reflect.field(other, "keys"), []);
                            if (isArray(keys)) {
                                var keyArray = asArray(keys);
                                for (key in keyArray) {
                                    var value = Reflect.callMethod(other, Reflect.field(other, "get"), [key]);
                                    Reflect.setField(obj, Std.string(key), value);
                                }
                            }
                        }
                        return null;
                    };
                case "copy":
                    return function() {
                        var copy = {};
                        for (key in Reflect.fields(obj)) {
                            if (key != "keys" && key != "get" && key != "set") {
                                Reflect.setField(copy, key, Reflect.field(obj, key));
                            }
                        }
                        return copy;
                    };
            }
        }
        
        // 检查是否是字符串方法
        if (Std.isOfType(obj, String)) {
            var str = cast(obj, String);
            
            switch (attr) {
                case "upper":
                    return makeMethodWrapper(function(args) {
                        return str.toUpperCase();
                    });
                case "lower":
                    return makeMethodWrapper(function(args) {
                        return str.toLowerCase();
                    });
                case "strip":
                    return makeMethodWrapper(function(args) {
                        return StringTools.trim(str);
                    });
                case "split":
                    return makeMethodWrapper(function(args) {
                        var sepStr = args.length > 0 ? safeStringConversion(args[0]) : " ";
                        return str.split(sepStr);
                    });
                case "join":
                    return makeMethodWrapper(function(args) {
                        if (args.length > 0) {
                            var iterable = args[0];
                            if (isArray(iterable)) {
                                return asArray(iterable).join(str);
                            }
                        }
                        throw "join() argument must be iterable";
                    });
                case "replace":
                    return makeMethodWrapper(function(args) {
                        if (args.length >= 2) {
                            return StringTools.replace(str, safeStringConversion(args[0]), safeStringConversion(args[1]));
                        }
                        throw "replace() takes at least 2 arguments";
                    });
                case "find":
                    return makeMethodWrapper(function(args) {
                        if (args.length > 0) {
                            var startIndex = args.length > 1 ? Std.int(args[1]) : 0;
                            return str.indexOf(Std.string(args[0]), startIndex);
                        }
                        throw "find() takes at least 1 argument";
                    });
                case "count":
                    return makeMethodWrapper(function(args) {
                        if (args.length > 0) {
                            var subStr = Std.string(args[0]);
                            var count = 0;
                            var pos = 0;
                            while ((pos = str.indexOf(subStr, pos)) != -1) {
                                count++;
                                pos += subStr.length;
                            }
                            return count;
                        }
                        throw "count() takes exactly 1 argument";
                    });
                case "startswith":
                    return makeMethodWrapper(function(args) {
                        if (args.length > 0) {
                            return StringTools.startsWith(str, safeStringConversion(args[0]));
                        }
                        throw "startswith() takes exactly 1 argument";
                    });
                case "endswith":
                    return makeMethodWrapper(function(args) {
                        if (args.length > 0) {
                            return StringTools.endsWith(str, safeStringConversion(args[0]));
                        }
                        throw "endswith() takes exactly 1 argument";
                    });
                default:
#if cpp
                    // CPP目标特殊处理：检查是否是对象被错误转换为字符串
                    if (str.indexOf("=>") != -1 || str.indexOf("{") != -1 || str.indexOf("}") != -1) {
                        // 这很可能是一个被错误转换为字符串的对象
                        // 尝试从全局作用域恢复原始对象
                        var recoveredObj = recoverFromObjectString(str);
                        if (recoveredObj != null) {
                            // 使用恢复的对象进行属性访问
                            if (Reflect.hasField(recoveredObj, attr)) {
                                return Reflect.getProperty(recoveredObj, attr);
                            }
                        }
                    }
#end
                    throw new AttributeError("'str' object has no attribute '" + attr + "'");
            }
        }
        
                
        // 改进的Haxe对象处理
        if (Reflect.isObject(obj)) {
            // 首先检查字段是否存在
            if (Reflect.hasField(obj, attr)) {
                // 字段存在，使用Reflect.getProperty获取值
                return Reflect.getProperty(obj, attr);
            }
            
            // 检查是否是getter/setter属性
            var getterName = "get_" + attr;
            var setterName = "set_" + attr;
            
            if (Reflect.hasField(obj, getterName) && Reflect.isFunction(Reflect.field(obj, getterName))) {
                // 如果有getter方法，调用它
                return Reflect.callMethod(obj, Reflect.field(obj, getterName), []);
            }
            
            // 检查是否有动态属性访问方法
            if (Reflect.hasField(obj, "__getattr__") && Reflect.isFunction(Reflect.field(obj, "__getattr__"))) {
                // 调用自定义的属性访问方法
                return Reflect.callMethod(obj, Reflect.field(obj, "__getattr__"), [attr]);
            }
            
            // 属性不存在，提供有用的错误信息
            var suggestion = "";
            var availableAttrs = [];
            var fields = Reflect.fields(obj);
            
            // 收集所有可用属性
            for (field in fields) {
                availableAttrs.push(field);
                // 查找大小写不敏感的匹配
                if (field.toLowerCase() == attr.toLowerCase() && field != attr) {
                    suggestion = " (did you mean '" + field + "'?)";
                    break;
                }
            }
            
            // 如果没有找到大小写匹配，显示一些可用属性
            if (suggestion == "" && availableAttrs.length > 0) {
                var sample = availableAttrs.slice(0, Std.int(Math.min(5, availableAttrs.length)));
                suggestion = " (available attributes: " + sample.join(", ") + (availableAttrs.length > 5 ? ", ..." : "") + ")";
            }
            
            throw new AttributeError("'" + getTypeName(obj) + "' object has no attribute '" + attr + "'" + suggestion);
        } else {
            throw "Cannot access property of non-object: " + obj + " (type: " + Type.typeof(obj) + ")";
        }
    }
    
    /**
     * 评估索引访问节点
     */
    private function evaluateIndexAccess(node:ASTNode):Dynamic {
        var obj = evaluate(node.object);
        var index = evaluate(node.index);
        
        if (Std.isOfType(obj, String)) {
            var str = cast(obj, String);
            return str.charAt(Std.int(index));
        } else if (isArray(obj)) {
            var arr = asArray(obj);
            return arr[Std.int(index)];
        } else if (Std.isOfType(obj, PythonDict)) {
            var dict = cast(obj, PythonDict);
            return dict.get(index);
        } else if (Reflect.hasField(obj, "get") && Reflect.isFunction(Reflect.field(obj, "get"))) {
            // Assume it's a map-like object
            return Reflect.callMethod(obj, Reflect.field(obj, "get"), [index]);
        } else {
            throw "Cannot index non-iterable: " + obj;
        }
    }
    
    /**
     * 评估切片节点
     */
    private function evaluateSlice(node:ASTNode):Dynamic {
        var obj = evaluate(node.object);
        
        // 获取切片参数
        var start:Dynamic = null;
        var end:Dynamic = null;
        var step:Dynamic = null;
        
        if (node.start != null) start = evaluate(node.start);
        if (node.end != null) end = evaluate(node.end);
        if (node.step != null) step = evaluate(node.step);
        
        // 处理字符串切片
        if (Std.isOfType(obj, String)) {
            var str = cast(obj, String);
            var len = str.length;
            
            // 默认值
            var stepInt = step != null ? Std.int(step) : 1;
            var startInt = start != null ? Std.int(start) : (stepInt > 0 ? 0 : len - 1);
            var endInt = end != null ? Std.int(end) : (stepInt > 0 ? len : -1);
            
            // 调整负数索引
            if (startInt < 0) startInt = len + startInt;
            if (endInt < 0) endInt = len + endInt;
            
            // 边界检查
            startInt = Std.int(Math.max(0, Math.min(len, startInt)));
            endInt = Std.int(Math.max(0, Math.min(len, endInt)));
            
            // 构建结果
            var result = "";
            if (stepInt > 0) {
                for (i in startInt...endInt) {
                    result += str.charAt(i);
                }
            } else {
                for (i in startInt...endInt) {
                    result += str.charAt(i);
                }
            }
            
            return result;
        }
        
        // 处理列表切片
        if (isArray(obj)) {
            var arr = asArray(obj);
            var len = arr.length;
            
            // 默认值
            var stepInt = step != null ? Std.int(step) : 1;
            var startIndex = start != null ? Std.int(start) : (stepInt >= 0 ? 0 : len - 1);
            var endIndex = end != null ? Std.int(end) : (stepInt >= 0 ? len : -1);
            
            // 处理负数索引
            if (startIndex < 0) startIndex = len + startIndex;
            if (endIndex < 0 && !(stepInt < 0 && end == null)) endIndex = len + endIndex;
            
            // 对于负步长，需要特殊处理边界
            if (stepInt < 0) {
                if (end == null) endIndex = -1;  // 特殊标记，表示到第一个元素之前
                startIndex = Std.int(Math.min(startIndex, len - 1));
                startIndex = Std.int(Math.max(startIndex, -1));
            } else {
                // 限制范围
                startIndex = Std.int(Math.max(0, Math.min(startIndex, len)));
                endIndex = Std.int(Math.max(0, Math.min(endIndex, len)));
            }
            
            // 执行切片
            var result = new Array<Dynamic>();
            if (stepInt > 0) {
                var i = startIndex;
                while (i < endIndex) {
                    result.push(arr[i]);
                    i += stepInt;
                }
            } else if (stepInt < 0) {
                var i = startIndex;
                while (i > endIndex) {
                    if (i >= 0 && i < len) {
                        result.push(arr[i]);
                    }
                    i += stepInt;
                }
            }
            
            return result;
        }
        
        throw "Cannot slice object of type " + Type.typeof(obj);
    }
    
    /**
     * 评估列表字面量节点
     */
    private function evaluateListLiteral(node:ASTNode):Dynamic {
        var result = new Array<Dynamic>();
        if (node.elements != null) {
            for (elem in node.elements) {
                result.push(evaluate(elem));
            }
        }
        return result;
    }
    
    /**
     * 评估字典字面量节点
     */
    private function evaluateDictLiteral(node:ASTNode):Dynamic {
        var dict = new PythonDict();
        if (node.keys != null && node.values != null) {
            for (i in 0...node.keys.length) {
                var key = evaluate(node.keys[i]);
                var value = evaluate(node.values[i]);
                dict.set(key, value);
            }
        }
        return dict;
    }
    
    /**
     * 评估if语句节点
     */
    private function evaluateIfStatement(node:ASTNode):Dynamic {
        var condition:Dynamic;
        try {
            condition = evaluate(node.test);
        } catch (e:Dynamic) {
            throw e;
        }
        
        if (isTruthy(condition)) {
            // Execute if body
            if (node.body != null) {
                for (stmt in node.body) {
                    evaluate(stmt);
                }
            }
        } else {
            // Check elif branches
            var executed = false;
            
            // Get elif branches
            var elifBranches:Array<ASTNode> = node.elifBranches;
            
            if (elifBranches != null && elifBranches.length > 0) {
                for (elifNode in elifBranches) {
                    var elifCondition:Dynamic = evaluate(elifNode.test);
                    if (isTruthy(elifCondition)) {
                        // Execute elif body
                        if (elifNode.body != null) {
                            for (stmt in elifNode.body) {
                                evaluate(stmt);
                            }
                        }
                        executed = true;
                        break;
                    }
                }
            }
            
            // Execute else clause if no elif was executed
            if (!executed && node.orelse != null) {
                if (node.orelse.type == NodeType.Block) {
                    for (stmt in node.orelse.statements) {
                        evaluate(stmt);
                    }
                } else {
                    evaluate(node.orelse);
                }
            }
        }
        
        return null;
    }
    
    /**
     * 评估while语句节点
     */
    private function evaluateWhileStatement(node:ASTNode):Dynamic {
        var broken = false;
        
        while (isTruthy(evaluate(node.test))) {
            try {
                if (node.body != null) {
                    for (stmt in node.body) {
                        evaluate(stmt);
                    }
                }
            } catch (e:BreakException) {
                broken = true;
                break;
            } catch (e:ContinueException) {
                continue;
            }
        }
        
        // else子句 - 当循环正常结束时执行（没有break）
        if (!broken && node.orelse != null) {
            if (node.orelse.type == NodeType.Block) {
                for (stmt in node.orelse.statements) {
                    evaluate(stmt);
                }
            } else {
                evaluate(node.orelse);
            }
        }
        
        return null;
    }
    
    /**
     * 评估for语句节点
     */
    private function evaluateForStatement(node:ASTNode):Dynamic {
        var iterable = evaluate(node.iter);
        var varName = node.target.name;
        var broken = false;
        
        for (value in makeIterable(iterable)) {
            try {
                setVariable(varName, value);
                if (node.body != null) {
                    for (stmt in node.body) {
                        evaluate(stmt);
                    }
                }
            } catch (e:BreakException) {
                broken = true;
                break;
            } catch (e:ContinueException) {
                continue;
            }
        }
        
        // else子句 - 当循环正常结束时执行（没有break）
        if (!broken && node.orelse != null) {
            if (node.orelse.type == NodeType.Block) {
                for (stmt in node.orelse.statements) {
                    evaluate(stmt);
                }
            } else {
                evaluate(node.orelse);
            }
        }
        
        return null;
    }
    
    /**
     * 评估函数定义节点
     */
    private function evaluateFunctionDef(node:ASTNode):Dynamic {
        
        var func = new PythonFunction(node.name, node.parameters, node.body, node.decorators);
        functions.set(node.name, func);
        
        // Check if a variable with the same name already exists
        if (globals.exists(node.name)) {
            var existingValue = globals.get(node.name);
            // Don't overwrite non-function values
            if (!Std.isOfType(existingValue, PythonFunction)) {
                // Keep the existing value, don't overwrite with function
                // But still store the function in the functions map for callFunc access
                return func;
            }
        }
        
        globals.set(node.name, func);
        
        return func;
    }
    
    /**
     * 评估类定义节点
     */
    private function evaluateClassDef(node:ASTNode):Dynamic {
        var pythonClass = new PythonClass(node.name);
        
        // 处理继承
        if (node.bases != null && node.bases.length > 0) {
            var baseNode = node.bases[0]; // 简化处理，只支持单继承
            if (baseNode.type == NodeType.Identifier) {
                var superClassName = baseNode.name;
                if (globals.exists(superClassName)) {
                    var superClass = globals.get(superClassName);
                    if (Std.isOfType(superClass, PythonClass)) {
                        pythonClass.superClass = cast(superClass, PythonClass);
                    }
                }
            }
        }
        
        // 处理类体中的方法定义
        if (node.body != null) {
            for (stmt in node.body) {
                if (stmt.type == NodeType.FunctionDef) {
                    var method = new PythonFunction(stmt.name, stmt.parameters, stmt.body, stmt.decorators);
                    pythonClass.addMethod(stmt.name, method);
                } else if (stmt.type == NodeType.Assignment) {
                    // 处理类属性
                    if (stmt.target.type == NodeType.Identifier) {
                        var varName = stmt.target.name;
                        var value = evaluate(stmt.value);
                        pythonClass.staticProperties.set(varName, value);
                    }
                }
            }
        }
        
        // 将类存储到全局作用域
        globals.set(node.name, pythonClass);
        return pythonClass;
    }
    
    /**
     * 评估return语句节点
     */
    private function evaluateReturnStatement(node:ASTNode):Dynamic {
        var value = node.value != null ? evaluate(node.value) : null;
        throw new ReturnException(value);
    }
    
    /**
     * 评估try语句节点
     */
    private function evaluateTryStatement(node:ASTNode):Dynamic {
        var result = null;
        var finallyBlock = node.finalbody;
        
        try {
            // 执行try块
            if (node.body != null) {
                for (stmt in node.body) {
                    result = evaluate(stmt);
                }
            }
        } catch (e:Dynamic) {
            // 查找匹配的except处理器
            var handled = false;
            
            if (node.handlers != null) {
                for (handler in node.handlers) {
                    var shouldHandle = false;
                    
                    // 如果没有指定异常类型，处理所有异常
                    if (handler.exctype == null) {
                        shouldHandle = true;
                    } else {
                        // 检查异常类型是否匹配
                        var excTypeNode = handler.exctype;
                        if (excTypeNode != null && excTypeNode.type == NodeType.Identifier) {
                            var excTypeName = excTypeNode.name;
                            
                            // 如果是PyException，检查类型
                            if (Std.isOfType(e, PyException)) {
                                var pyExc = cast(e, PyException);
                                if (pyExc.type == excTypeName) {
                                    shouldHandle = true;
                                }
                            } else if (Std.string(e).indexOf(excTypeName) != -1) {
                                // 对于字符串异常，检查是否包含类型名
                                shouldHandle = true;
                            }
                        }
                    }
                    
                    if (shouldHandle && handler.body != null) {
                        // 如果有as子句，将异常赋值给变量
                        if (handler.exc != null && handler.exc.name != null) {
                            setVariable(handler.exc.name, e);
                        }
                        
                        for (stmt in handler.body) {
                            result = evaluate(stmt);
                        }
                        handled = true;
                        break;
                    }
                }
            }
            
            // 如果没有处理器，重新抛出异常
            if (!handled) {
                throw e;
            }
        }
        
        // 执行finally块（如果有）
        if (finallyBlock != null) {
            if (isArray(finallyBlock)) {
                for (stmt in asArray(finallyBlock)) {
                    evaluate(stmt);
                }
            } else {
                evaluate(finallyBlock);
            }
        }
        
        return result;
    }
    
    /**
     * 检查值是否为真值
     */
    private function isTruthy(value:Dynamic):Bool {
        if (value == null) return false;
        if (Std.isOfType(value, Bool)) return cast(value, Bool);
        if (Std.isOfType(value, Float) || Std.isOfType(value, Int)) {
            return value != 0;
        }
        if (Std.isOfType(value, String)) return cast(value, String).length > 0;
        if (isArray(value)) return asArray(value).length > 0;
        if (Reflect.hasField(value, "keys") && Reflect.isFunction(Reflect.field(value, "keys"))) {
            // Assume it's a map-like object
            var keys = Reflect.callMethod(value, Reflect.field(value, "keys"), []);
            return keys.length > 0;
        }
        return true;
    }
    
    /**
     * 将值转换为可迭代对象
     */
    private function makeIterable(value:Dynamic):Array<Dynamic> {
        if (isArray(value)) {
            return asArray(value);
        }
        if (Std.isOfType(value, String)) {
            return [for (i in 0...cast(value, String).length) cast(value, String).charAt(i)];
        }
        if (Reflect.hasField(value, "keys") && Reflect.isFunction(Reflect.field(value, "keys"))) {
            // Assume it's a map-like object
            return Reflect.callMethod(value, Reflect.field(value, "keys"), []);
        }
        if (value.hasNext != null && value.next != null) {
            var result = [];
            var iter = value;
            while (iter.hasNext()) {
                result.push(iter.next());
            }
            return result;
        }
        throw "Value is not iterable: " + value;
    }
    
    /**
     * 设置变量
     */
    public function setVariable(name:String, value:Dynamic):Void {
        // 标记变量为明确定义
        explicitlyDefined.set(name, true);
        
#if cpp
        // CPP目标特殊处理：保护Haxe对象不被转换为字符串
        if (isHaxeObject(value)) {
            protectObject(value);
        }
#end
        
        if (locals != null && locals.exists(name)) {
            locals.set(name, value);
        } else {
            // 检查是否在函数作用域内
            if (currentFunctionName != null && !isGlobalVariable.exists(name)) {
                // 在函数内第一次赋值，创建局部变量
                if (locals != null) {
                    locals.set(name, value);
                }
                // 标记为局部变量
                isLocalVariable.set(name, true);
            } else {
                globals.set(name, value);
            }
        }
    }
    
    /**
     * 检查是否是重要的对象变量
     */
    private function isImportantObjectVariable(name:String):Bool {
        // 常见的游戏对象变量名
        var importantNames = ["game", "player", "obj", "entity", "character"];
        for (importantName in importantNames) {
            if (name == importantName) {
                return true;
            }
        }
        return false;
    }
    
#if cpp
    /**
     * CPP目标专用的对象检查函数
     */
    private function cppIsHaxeObject(obj:Dynamic):Bool {
        if (obj == null) return false;
        
        // 在CPP目标下，我们需要更严格的检查
        var type = Type.typeof(obj);
        return switch (type) {
            case TObject: true;  // 匿名对象
            case TClass(c): 
                var className = Type.getClassName(c);
                // 排除基本类型
                className != "String" && 
                className != "Array" &&
                className != "Date";
            case TUnknown: false;
            default: false;
        }
    }
    
    /**
     * 从对象字符串恢复原始对象
     */
    private function recoverFromObjectString(str:String):Dynamic {
        // 查找看起来像对象的字符串模式
        if (str.indexOf("=>") != -1) {
            // 尝试解析类似 "{ health => 100 }" 的字符串
            var pattern = ~/\{\s*(\w+)\s*=>\s*(\d+)\s*\}/;
            if (pattern.match(str)) {
                var attrName = pattern.matched(1);
                var attrValue = Std.parseFloat(pattern.matched(2));
                var recovered = {};
                Reflect.setField(recovered, attrName, attrValue);
                return recovered;
            }
        }
        
        // 检查是否是Haxe对象的字符串表示
        if (str.indexOf("<") == 0 && str.indexOf("instance>") != -1) {
            // 这是类似 "<test.SimpleSprite instance>" 的字符串
            // 我们需要从全局作用域中找到原始对象
            // 这是一个简化的实现，实际应用中可能需要更复杂的对象跟踪
            for (obj in protectedObjects) {
                var objStr = Std.string(obj);
                if (objStr == str) {
                    return obj;
                }
            }
        }
        
        return null;
    }
    
    /**
     * 创建Haxe对象的安全包装器
     * @param obj 要包装的Haxe对象
     * @return 包装后的对象
     */
    private function createHaxeObjectWrapper(obj:Dynamic):Dynamic {
        var wrapper = {
            __wrappedObject: obj,
            __originalToString: function() {
                // 直接调用对象的toString方法，避免Std.string()
                if (Reflect.hasField(obj, "toString") && Reflect.isFunction(Reflect.field(obj, "toString"))) {
                    return Reflect.callMethod(obj, Reflect.field(obj, "toString"), []);
                } else {
                    // 回退到安全的方式
                    return "[HaxeObject " + Type.getClassName(Type.getClass(obj)) + "]";
                }
            },
            __getProperty: function(attr:String) {
                return getHaxeObjectProperty(obj, attr);
            },
            __setProperty: function(attr:String, value:Dynamic) {
                return setHaxeObjectProperty(obj, attr, value);
            }
        };
        
        // 保护包装器
        protectObject(wrapper);
        return wrapper;
    }
#end
    
    /**
     * 标记变量为全局变量
     */
    public function markAsGlobal(name:String):Void {
        isGlobalVariable.set(name, true);
    }
    
    /**
     * 获取变量
     */
    public function getVariable(name:String):Dynamic {
        // 首先检查是否是内置函数
        switch (name) {
            case "print": return "builtin:print";
            case "len": return "builtin:len";
            case "str": return "builtin:str";
            case "int": return "builtin:int";
            case "float": return "builtin:float";
            case "bool": return "builtin:bool";
            case "list": return "builtin:list";
            case "dict": return "builtin:dict";
            case "range": return "builtin:range";
            case "sum": return "builtin:sum";
            case "max": return "builtin:max";
            case "min": return "builtin:min";
            case "abs": return "builtin:abs";
            case "round": return "builtin:round";
            case "pow": return "builtin:pow";
            case "type": return "builtin:type";
            case "isinstance": return "builtin:isinstance";
            case "chr": return "builtin:chr";
            case "ord": return "builtin:ord";
            case "hex": return "builtin:hex";
            case "oct": return "builtin:oct";
            case "bin": return "builtin:bin";
            case "super": return "builtin:super";
        }
        
#if cpp
        // 调试：追踪变量获取
        var result:Dynamic = null;
        
        // 在Python中，变量查找顺序是：局部 -> 全局 -> Haxe类注册表
        if (locals != null && locals.exists(name)) {
            result = locals.get(name);
        } else if (globals.exists(name)) {
            result = globals.get(name);
        } else if (haxeClassRegistry != null && haxeClassRegistry.exists(name)) {
            result = haxeClassRegistry.get(name);
            if (result != null) {
                result = createHaxeClassWrapper(result, name);
            }
        } else {
            return null;
        }
        
        return result;
#else
        // 在Python中，变量查找顺序是：局部 -> 全局 -> Haxe类注册表
        if (locals != null && locals.exists(name)) {
            return locals.get(name);
        } else if (globals.exists(name)) {
            return globals.get(name);
        } else if (haxeClassRegistry != null && haxeClassRegistry.exists(name)) {
            var haxeClass = haxeClassRegistry.get(name);
            if (haxeClass != null) {
                return createHaxeClassWrapper(haxeClass, name);
            }
            return haxeClass;
        } else {
            return null;
        }
#end
    }
    
    /**
     * 获取全局作用域
     */
    public function getGlobalScope():Map<String, Dynamic> {
        return globals;
    }
    
    /**
     * Set Haxe class registry
     * @param registry Map of Python names to Haxe classes
     */
    public function setHaxeClassRegistry(registry:Map<String, Class<Dynamic>>):Void {
        haxeClassRegistry = registry;
    }
    
    /**
     * Create a wrapper for Haxe class that can be called from Python
     * @param haxeClass The Haxe class to wrap
     * @param name The name to use for error messages
     * @return A callable wrapper object
     */
    private function createHaxeClassWrapper(haxeClass:Class<Dynamic>, name:String):Dynamic {
        var wrapper = {
            __haxeClass: haxeClass,
            __name: name,
            __call: function(args:Array<Dynamic>) {
                return createHaxeInstance(haxeClass, args);
            }
        };
        
        // Make the wrapper callable
        Reflect.setField(wrapper, "call", wrapper.__call);
        
        return wrapper;
    }
    
    /**
     * Create an instance of a Haxe class
     * @param haxeClass The Haxe class to instantiate
     * @param args Constructor arguments
     * @return The created instance
     */
    private function createHaxeInstance(haxeClass:Class<Dynamic>, args:Array<Dynamic>):Dynamic {
        try {
            // 确保args是有效的数组
            if (args == null) {
                args = [];
            }
            
            // 处理参数中的null值（可选参数）
            var processedArgs:Array<Dynamic> = [];
            for (arg in args) {
                processedArgs.push(arg);
            }
            
            var instance = Type.createInstance(haxeClass, processedArgs);
            
            // CPP目标特殊处理：使用对象ID系统
            #if cpp
            var objectId = nextObjectId++;
            objectTracker.set(objectId, instance);
            
            var idWrapper = {
                __objectId: objectId,
                __getInstance: function() {
                    return objectTracker.get(objectId);
                },
                __toString: function() {
                    var obj = objectTracker.get(objectId);
                    if (obj != null) {
                        if (Reflect.hasField(obj, "toString") && Reflect.isFunction(Reflect.field(obj, "toString"))) {
                            return Reflect.callMethod(obj, Reflect.field(obj, "toString"), []);
                        } else {
                            return "[HaxeObject " + Type.getClassName(Type.getClass(obj)) + "]";
                        }
                    }
                    return "[InvalidObject]";
                }
            };
            
            protectObject(idWrapper);
            return idWrapper;
            #else
            return instance;
            #end
        } catch (e:Dynamic) {
            throw "Failed to create Haxe instance: " + e;
        }
    }
    
    /**
     * Get Haxe class from registry
     * @param pythonName The Python name of the class
     * @return The Haxe class or null if not found
     */
    public function getHaxeClass(pythonName:String):Class<Dynamic> {
        return haxeClassRegistry.get(pythonName);
    }
    
    /**
     * 获取函数定义
     */
    public function getFunctions():Map<String, Dynamic> {
        return functions;
    }
    
    /**
     * 重置致命错误标志
     */
    public function resetFatalError():Void {
        fatalError = false;
    }
    
    // Built-in function implementations
    private function print(args:Array<Dynamic>):Dynamic {
        var output = "";
        for (i in 0...args.length) {
            if (i > 0) output += " ";
            #if cpp
            // CPP目标特殊处理：确保Haxe对象正确转换为字符串
            var arg = args[i];
            if (isHaxeObject(arg)) {
                // 检查是否是ID包装器
                if (Reflect.hasField(arg, "__objectId")) {
                    var getInstanceFunc = Reflect.field(arg, "__getInstance");
                    var realObj = Reflect.callMethod(arg, getInstanceFunc, []);
                    if (realObj != null) {
                        if (Reflect.hasField(realObj, "toString") && Reflect.isFunction(Reflect.field(realObj, "toString"))) {
                            output += Reflect.callMethod(realObj, Reflect.field(realObj, "toString"), []);
                        } else {
                            output += "[HaxeObject " + Type.getClassName(Type.getClass(realObj)) + "]";
                        }
                    } else {
                        output += "[InvalidObject]";
                    }
                } else if (Reflect.hasField(arg, "__originalToString")) {
                    var toStringFunc = Reflect.field(arg, "__originalToString");
                    output += Reflect.callMethod(arg, toStringFunc, []);
                } else if (Reflect.hasField(arg, "__wrappedObject")) {
                    // 是包装器但没有toString方法
                    var wrappedObj = Reflect.field(arg, "__wrappedObject");
                    if (Reflect.hasField(wrappedObj, "toString") && Reflect.isFunction(Reflect.field(wrappedObj, "toString"))) {
                        output += Reflect.callMethod(wrappedObj, Reflect.field(wrappedObj, "toString"), []);
                    } else {
                        output += "[HaxeObject]";
                    }
                } else {
                    // 直接处理Haxe对象
                    if (Reflect.hasField(arg, "toString") && Reflect.isFunction(Reflect.field(arg, "toString"))) {
                        output += Reflect.callMethod(arg, Reflect.field(arg, "toString"), []);
                    } else {
                        output += "[HaxeObject]";
                    }
                }
            } else {
                output += Std.string(arg);
            }
            #else
            output += Std.string(args[i]);
            #end
        }
        
        if (customPrintHandler != null) {
            customPrintHandler(currentLine, output);
        } else {
            Sys.println(output);
        }
        return null;
    }
    
    private function len(args:Array<Dynamic>):Dynamic {
        if (args.length != 1) throw "len() takes exactly 1 argument";
        var obj = args[0];
        
        if (Std.isOfType(obj, String)) return cast(obj, String).length;
        if (Std.isOfType(obj, Array)) return cast(obj, Array<Dynamic>).length;
        if (Reflect.hasField(obj, "length") && Reflect.isFunction(obj.push)) return cast(obj, Array<Dynamic>).length;
        if (Reflect.hasField(obj, "keys") && Reflect.isFunction(Reflect.field(obj, "keys"))) {
            // Assume it's a map-like object
            var keys = Reflect.callMethod(obj, Reflect.field(obj, "keys"), []);
            return keys.length;
        }
        
        throw "object of type " + Type.typeof(obj) + " has no len()";
    }
    
    // 安全的字符串转换函数，防止Haxe对象被意外转换
    private function safeStringConversion(obj:Dynamic):String {
        // 基本类型直接转换
        var type = Type.typeof(obj);
        switch (type) {
            case TInt, TFloat, TBool, TClass(String):
                return Std.string(obj);
            case TNull:
                return "None";
            case TFunction:
                return "<function>";
            case TClass(Array):
                return "<array>";
            case TClass(c):
                // 对于其他类，返回类名而不是对象内容
                return "<" + Type.getClassName(c) + " instance>";
            case TObject:
                // 对于匿名对象，返回一个安全的字符串表示
                return "<object>";
            case TEnum(_):
                return "<enum>";
            case TUnknown:
                return "<unknown>";
        }
    }
    
    private function str(args:Array<Dynamic>):Dynamic {
        if (args.length != 1) throw "str() takes exactly 1 argument";
        var arg = args[0];
        
        return safeStringConversion(arg);
    }
    
    private function int(args:Array<Dynamic>):Dynamic {
        if (args.length != 1) throw "int() takes exactly 1 argument";
        return Std.parseInt(safeStringConversion(args[0]));
    }
    
    private function float(args:Array<Dynamic>):Dynamic {
        if (args.length != 1) throw "float() takes exactly 1 argument";
        return Std.parseFloat(safeStringConversion(args[0]));
    }
    
    private function bool(args:Array<Dynamic>):Dynamic {
        if (args.length != 1) throw "bool() takes exactly 1 argument";
        return isTruthy(args[0]);
    }
    
    private function list(args:Array<Dynamic>):Dynamic {
        if (args.length == 0) return new Array<Dynamic>();
        if (args.length == 1) {
            var obj = args[0];
            if (Std.isOfType(obj, String)) {
                var result = new Array<Dynamic>();
                var str = cast(obj, String);
                for (i in 0...str.length) {
                    result.push(str.charAt(i));
                }
                return result;
            }
        }
        throw "list() takes at most 1 argument";
    }
    
    private function dict(args:Array<Dynamic>):Dynamic {
        if (args.length != 0) throw "dict() takes no arguments";
        return new Map<Dynamic, Dynamic>();
    }
    
    private function range(args:Array<Dynamic>):Dynamic {
        if (args.length < 1 || args.length > 3) throw "range() takes 1-3 arguments";
        
        var start = 0;
        var stop:Float;
        var step = 1;
        
        if (args.length == 1) {
            stop = args[0];
        } else if (args.length == 2) {
            start = args[0];
            stop = args[1];
        } else {
            start = args[0];
            stop = args[1];
            step = args[2];
        }
        
        var result = new Array<Dynamic>();
        for (i in Std.int(start)...Std.int(stop)) {
            result.push(i);
        }
        
        return result;
    }
    
    // 更多内置函数
    private function sum(args:Array<Dynamic>):Dynamic {
        if (args.length == 0) return 0;
        if (args.length == 1) {
            var iterable = args[0];
            var total:Float = 0;
            if (isArray(iterable)) {
                for (item in asArray(iterable)) {
                    total += toNumber(item);
                }
                return total;
            }
            throw "sum() argument must be iterable";
        }
        throw "sum() takes at most 1 argument";
    }
    
    private function max(args:Array<Dynamic>):Dynamic {
        if (args.length == 0) throw "max() expected at least 1 argument";
        
        if (args.length == 1) {
            var iterable = args[0];
            if (isArray(iterable)) {
                var arr = asArray(iterable);
                if (arr.length == 0) throw "max() arg is an empty sequence";
                var maxValue = arr[0];
                for (i in 1...arr.length) {
                    if (compareValues(arr[i], maxValue) > 0) {
                        maxValue = arr[i];
                    }
                }
                return maxValue;
            }
        } else {
            var maxValue = args[0];
            for (i in 1...args.length) {
                if (compareValues(args[i], maxValue) > 0) {
                    maxValue = args[i];
                }
            }
            return maxValue;
        }
        throw "max() argument must be iterable";
    }
    
    private function min(args:Array<Dynamic>):Dynamic {
        if (args.length == 0) throw "min() expected at least 1 argument";
        
        if (args.length == 1) {
            var iterable = args[0];
            if (isArray(iterable)) {
                var arr = asArray(iterable);
                if (arr.length == 0) throw "min() arg is an empty sequence";
                var minValue = arr[0];
                for (i in 1...arr.length) {
                    if (compareValues(arr[i], minValue) < 0) {
                        minValue = arr[i];
                    }
                }
                return minValue;
            }
        } else {
            var minValue = args[0];
            for (i in 1...args.length) {
                if (compareValues(args[i], minValue) < 0) {
                    minValue = args[i];
                }
            }
            return minValue;
        }
        throw "min() argument must be iterable";
    }
    
    private function abs(args:Array<Dynamic>):Dynamic {
        if (args.length != 1) throw "abs() takes exactly 1 argument";
        var value = toNumber(args[0]);
        return value < 0 ? -value : value;
    }
    
    private function round(args:Array<Dynamic>):Dynamic {
        if (args.length < 1 || args.length > 2) throw "round() takes 1-2 arguments";
        var number = toNumber(args[0]);
        var decimals = args.length > 1 ? Std.int(args[1]) : 0;
        var factor = Math.pow(10, decimals);
        return Math.round(number * factor) / factor;
    }
    
    private function pow(args:Array<Dynamic>):Dynamic {
        if (args.length != 2) throw "pow() takes exactly 2 arguments";
        var base = toNumber(args[0]);
        var exponent = toNumber(args[1]);
        return Math.pow(base, exponent);
    }
    
    private function type(args:Array<Dynamic>):Dynamic {
        if (args.length != 1) throw "type() takes exactly 1 argument";
        var obj = args[0];
        if (Std.isOfType(obj, String)) return "<class 'str'>";
        if (Std.isOfType(obj, Int)) return "<class 'int'>";
        if (Std.isOfType(obj, Float)) return "<class 'float'>";
        if (Std.isOfType(obj, Bool)) return "<class 'bool'>";
        if (Reflect.hasField(obj, "length") && Reflect.isFunction(obj.push)) return "<class 'list'>";
        if (Reflect.hasField(obj, "keys") && Reflect.hasField(obj, "get")) return "<class 'dict'>";
        return "<class 'object'>";
    }
    
    private function isinstance(args:Array<Dynamic>):Dynamic {
        if (args.length != 2) throw "isinstance() takes exactly 2 arguments";
        var obj = args[0];
        var classInfo = args[1];
        
        if (Std.isOfType(classInfo, String)) {
            var className = cast(classInfo, String);
            if (className == "str") return Std.isOfType(obj, String);
            if (className == "int") return Std.isOfType(obj, Int);
            if (className == "float") return Std.isOfType(obj, Float);
            if (className == "bool") return Std.isOfType(obj, Bool);
            if (className == "list") return isArray(obj);
            if (className == "dict") return Reflect.hasField(obj, "keys") && Reflect.hasField(obj, "get");
        }
        
        return false;
    }
    
    private function chr(args:Array<Dynamic>):Dynamic {
        if (args.length != 1) throw "chr() takes exactly 1 argument";
        var i = Std.int(args[0]);
        if (i < 0 || i > 0x10FFFF) throw "chr() arg not in range(0x110000)";
        return String.fromCharCode(i);
    }
    
    private function ord(args:Array<Dynamic>):Dynamic {
        if (args.length != 1) throw "ord() takes exactly 1 argument";
        var s = Std.string(args[0]);
        if (s.length != 1) throw "ord() expected a character, but string of length " + s.length + " found";
        return s.charCodeAt(0);
    }
    
    private function hex(args:Array<Dynamic>):Dynamic {
        if (args.length != 1) throw "hex() takes exactly 1 argument";
        var i = Std.int(args[0]);
        return "0x" + StringTools.hex(i);
    }
    
    private function oct(args:Array<Dynamic>):Dynamic {
        if (args.length != 1) throw "oct() takes exactly 1 argument";
        var i = Std.int(args[0]);
        return "0o" + StringTools.hex(i, 8);
    }
    
    private function bin(args:Array<Dynamic>):Dynamic {
        if (args.length != 1) throw "bin() takes exactly 1 argument";
        var i = Std.int(args[0]);
        var binStr = "";
        while (i > 0) {
            binStr = (i & 1) + binStr;
            i >>= 1;
        }
        return binStr == "" ? "0b0" : "0b" + binStr;
    }
    
    private function superFunc(args:Array<Dynamic>):Dynamic {
        // super() 应该在方法内部调用，第一个参数是类型或对象
        if (currentSelf == null) throw "super() must be called inside a method";
        
        // 创建一个super代理对象，它会将方法调用绑定到当前实例
        return new SuperProxy(currentSelf);
    }
    
    private function compareValues(a:Dynamic, b:Dynamic):Int {
        return SafeComparison.safeCompare(a, b);
    }
    
    /**
     * 将值转换为数字
     */
    private function toNumber(value:Dynamic):Float {
        if (Std.isOfType(value, Float)) return value;
        if (Std.isOfType(value, Int)) return value;
        if (Std.isOfType(value, String)) {
            var result = Std.parseFloat(value);
            return result;
        }
        if (Std.isOfType(value, Bool)) return value ? 1 : 0;
        return 0;
    }
    
    // 公共方法：获取全局变量表
    public function getGlobals():Map<String, Dynamic> {
        return globals;
    }
}

// Super代理类，用于处理super()调用
class SuperProxy {
    private var instance:PythonObject;
    
    public function new(instance:PythonObject) {
        this.instance = instance;
    }
    
    public function resolveMethod(methodName:String):Dynamic {
        // 查找父类中的方法
        var currentClass = instance.pythonClass;
        if (currentClass.superClass != null) {
            var superClass = currentClass.superClass;
            var method = superClass.getMethod(methodName);
            if (method != null) {
                // 返回绑定到当前实例的方法
                return new BoundMethod(method, instance);
            }
        }
        throw "AttributeError: '" + currentClass.superClass.name + "' object has no attribute '" + methodName + "'";
    }
}

// Python函数类
class PythonFunction {
    public var name:String;
    public var parameters:Array<ASTNode>;
    public var body:Array<ASTNode>;
    public var decorators:Array<ASTNode>;
    public var isStatic:Bool;
    public var isClassMethod:Bool;
    
    public function new(name:String, parameters:Array<ASTNode>, body:Array<ASTNode>, ?decorators:Array<ASTNode> = null) {
        this.name = name;
        this.parameters = parameters;
        this.body = body;
        this.decorators = decorators != null ? decorators : [];
        this.isStatic = false;
        this.isClassMethod = false;
        
        // 处理装饰器
        for (decorator in this.decorators) {
            if (decorator.expression.type == NodeType.Identifier) {
                var decoratorName = decorator.expression.name;
                if (decoratorName == "staticmethod") {
                    this.isStatic = true;
                } else if (decoratorName == "classmethod") {
                    this.isClassMethod = true;
                }
            }
        }
    }
    
    public function call(interpreter:Interpreter, args:Array<Dynamic>):Dynamic {
        // 保存当前作用域状态
        var oldLocals = interpreter.locals;
        var oldFunctionName = interpreter.currentFunctionName;
        var oldIsGlobalVariable = interpreter.isGlobalVariable;
        var oldIsLocalVariable = interpreter.isLocalVariable;
        var oldFunctionCallDepth = interpreter.functionCallDepth;
        
        // 创建新的作用域，但保留对全局变量的访问
        var newLocals = new Map<String, Dynamic>();
        var newIsGlobalVariable = new Map<String, Bool>();
        var newIsLocalVariable = new Map<String, Bool>();
        
        // 如果是在全局作用域中调用函数，保留全局变量访问
        if (interpreter.locals == interpreter.globals) {
            // 在全局作用域中调用， locals应该指向新的局部作用域
            interpreter.locals = newLocals;
        } else {
            // 在其他函数中调用，创建嵌套作用域
            interpreter.locals = newLocals;
        }
        
        interpreter.currentFunctionName = name;
        interpreter.isGlobalVariable = newIsGlobalVariable;
        interpreter.isLocalVariable = newIsLocalVariable;
        interpreter.functionCallDepth++;
        
        // 处理静态方法和类方法的特殊参数
        var adjustedArgs = args.copy();
        var oldSelf:PythonObject = null;
        
        if (isClassMethod) {
            // 类方法的第一个参数应该是类本身
            var cls = findClassForMethod(interpreter);
            if (cls != null) {
                adjustedArgs.unshift(cls);
            }
        } else if (!isStatic && !isClassMethod && args.length > 0) {
            // 实例方法的第一个参数是self，已经包含在args中
            oldSelf = interpreter.currentSelf;
            if (args[0] != null && Std.isOfType(args[0], PythonObject)) {
                interpreter.currentSelf = cast(args[0], PythonObject);
            }
        }
        
        // 设置参数
        for (i in 0...parameters.length) {
            var param = parameters[i];
            var value = i < adjustedArgs.length ? adjustedArgs[i] : null;
            
            // 调试：检查参数名是否是 game
            if (param.name == "game") {
                trace("DEBUG: Function parameter 'game' being set to:", value, "(" + Type.typeof(value) + ")");
            }
            
            // 对于局部变量，直接设置到 locals 而不是通过 setVariable
            if (interpreter.locals != null) {
                // 只有真正的Haxe对象才需要保护，不要保护基本类型
                if (interpreter.isProtected(value)) {
                    interpreter.protectObject(value);
                }
                interpreter.locals.set(param.name, value);
            } else {
                interpreter.setVariable(param.name, value);
            }
        }
        
        // 执行函数体
        var result:Dynamic = null;
        try {
            for (stmt in body) {
                interpreter.evaluate(stmt);
            }
        } catch (e:ReturnException) {
            result = e.value;
        }
        
        // 恢复作用域状态
        interpreter.locals = oldLocals;
        interpreter.currentFunctionName = oldFunctionName;
        interpreter.isGlobalVariable = oldIsGlobalVariable;
        interpreter.isLocalVariable = oldIsLocalVariable;
        interpreter.functionCallDepth = oldFunctionCallDepth;
        
        // 恢复原来的self
        if (!isStatic && !isClassMethod) {
            interpreter.currentSelf = oldSelf;
        }
        
        return result;
    }
    
    // 辅助方法：查找方法所属的类
    private function findClassForMethod(interpreter:Interpreter):Dynamic {
        // 遍历全局作用域找到包含此方法的类
        var globals = interpreter.getGlobals();
        for (key in globals.keys()) {
            var value = globals.get(key);
            if (Std.isOfType(value, PythonClass)) {
                var cls = cast(value, PythonClass);
                if (cls.methods.exists(this.name)) {
                    return cls;
                }
            }
        }
        return null;
    }
}

// 异常类
class ReturnException {
    public var value:Dynamic;
    public function new(value:Dynamic) {
        this.value = value;
    }
}

class BreakException {
    public function new() {}
}

class ContinueException {
    public function new() {}
}

// Python类定义
class PythonClass {
    public var name:String;
    public var superClass:PythonClass;
    public var methods:Map<String, PythonFunction>;
    public var staticProperties:Map<String, Dynamic>;
    
    public function new(name:String, ?superClass:PythonClass) {
        this.name = name;
        this.superClass = superClass;
        this.methods = new Map<String, PythonFunction>();
        this.staticProperties = new Map<String, Dynamic>();
    }
    
    public function addMethod(name:String, func:PythonFunction):Void {
        methods.set(name, func);
        
        // 如果是静态方法，也添加到静态属性中
        if (func.isStatic) {
            staticProperties.set(name, func);
        }
    }
    
    public function getMethod(name:String):PythonFunction {
        // 首先检查当前类的方法
        if (methods.exists(name)) {
            return methods.get(name);
        }
        
        // 然后检查父类的方法
        if (superClass != null) {
            return superClass.getMethod(name);
        }
        
        return null;
    }
    
    public function createInstance(interpreter:Interpreter, args:Array<Dynamic>):PythonObject {
        var instance = new PythonObject(this);
        
        // 调用__init__方法
        var initFunc = getMethod("__init__");
        if (initFunc != null) {
            // 将instance作为第一个参数（self）
            var instanceArgs:Array<Dynamic> = [instance];
            for (arg in args) {
                instanceArgs.push(arg);
            }
            initFunc.call(interpreter, instanceArgs);
        }
        
        return instance;
    }
}

// 绑定方法类
class BoundMethod {
    public var method:PythonFunction;
    public var instance:PythonObject;
    
    public function new(method:PythonFunction, instance:PythonObject) {
        this.method = method;
        this.instance = instance;
    }
    
    public function call(interpreter:Interpreter, args:Array<Dynamic>):Dynamic {
        // 将实例作为第一个参数（self）
        var allArgs:Array<Dynamic> = [instance];
        if (args != null) {
            allArgs = allArgs.concat(args);
        }
        return method.call(interpreter, allArgs);
    }
}

// Python对象实例
class PythonObject {
    public var pythonClass:PythonClass;
    public var properties:Map<String, Dynamic>;
    public var superClass:PythonObject; // 用于super()支持
    
    public function new(pythonClass:PythonClass) {
        this.pythonClass = pythonClass;
        this.properties = new Map<String, Dynamic>();
        this.superClass = null;
    }
    
    public function getProperty(name:String):Dynamic {
        // 首先检查实例属性
        if (properties.exists(name)) {
            return properties.get(name);
        }
        
        // 然后检查类方法（包括继承的方法）
        var method = pythonClass.getMethod(name);
        if (method != null) {
            // 返回绑定方法
            return new BoundMethod(method, this);
        }
        
        // 检查父类
        if (pythonClass.superClass != null) {
            var superMethod = pythonClass.superClass.methods.get(name);
            if (superMethod != null) {
                return function(?args:Array<Dynamic>) {
                    var allArgs:Array<Dynamic> = [this];
                    if (args != null) {
                        for (arg in args) {
                            allArgs.push(arg);
                        }
                    }
                    return superMethod.call(null, allArgs);
                };
            }
        }
        
        // 最后检查静态属性
        if (pythonClass.staticProperties.exists(name)) {
            return pythonClass.staticProperties.get(name);
        }
        
        throw "AttributeError: '" + pythonClass.name + "' object has no attribute '" + name + "'";
    }
    
    public function setProperty(name:String, value:Dynamic):Void {
        properties.set(name, value);
    }
    
    // 创建super对象
    public function getSuper():PythonObject {
        if (superClass == null && pythonClass.superClass != null) {
            superClass = new PythonObject(pythonClass.superClass);
        }
        return superClass;
    }
}
