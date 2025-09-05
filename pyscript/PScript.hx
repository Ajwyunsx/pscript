package pyscript;

import pyscript.core.Interpreter;
import pyscript.utils.BasicHaxeConverter;
import pyscript.utils.SimpleHaxeConverter;

/**
 * Python script parser
 * Similar to LScript, but for Python scripts
 */
class PScript {
    public var interpreter:Interpreter;
    private var scriptContent:String;
    
    // Module registry
    private static var modules:Map<String, PScript> = new Map<String, PScript>();
    
    // Haxe class registry for Python interop
    private static var haxeClasses:Map<String, Class<Dynamic>> = new Map<String, Class<Dynamic>>();
    
    public var parent(get, set):Dynamic;
    
    // Function call related variables
    public var lastCalledFunction:String = '';
    public var lastCalledScript:PScript = null;
    
    // Cache function call code to avoid repeated building
    private var callCodeCache:Map<String, String> = new Map<String, String>();
    
    // Error and output callbacks
    public var onError:String->Void = null;
    public var onPrint:Int->String->Void = null;
    
    // Control whether to enable global error handling
    public var enableGlobalErrorHandling:Bool = true;
    
    // Haxe syntax support
    public var enableHaxeSyntax:Bool = true;
    private var originalScriptContent:String;
    
    // Script object (similar to LScript's specialVars[0])
    private var scriptObject:Dynamic = {};
    
    public function new(?scriptContent:String) {
        interpreter = new Interpreter();
        
        // Initialize script object
        scriptObject = {};
        scriptObject.parent = null;
        
        // Make script object available to Python scripts
        interpreter.setVariable("script", scriptObject);
        
        // Register Haxe class registry with interpreter
        interpreter.setHaxeClassRegistry(haxeClasses);
        
        // Set up custom error handling if callbacks are provided
        if (onError != null) {
            interpreter.customErrorHandler = onError;
        }
        if (onPrint != null) {
            interpreter.customPrintHandler = onPrint;
        }
        
        // Haxe syntax support
        this.enableHaxeSyntax = true;
        this.originalScriptContent = null;
        
        if (scriptContent != null) {
            this.originalScriptContent = scriptContent;
            this.scriptContent = processScriptContent(scriptContent);
        }
    }
    
    /**
     * Load Python script from file path
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
     * Create Python script from string
     */
    public static function fromString(content:String):PScript {
        return new PScript(content);
    }
    
    /**
     * Set variable in Python environment
     * Supports Haxe syntax conversion for string values
     */
    public function setVar(name:String, value:Dynamic):Void {
        // If value is a string that contains Haxe syntax, convert it
        if (Std.isOfType(value, String)) {
            var stringValue:String = cast value;
            // Check if it contains Haxe method calls or hex numbers
            if (containsHaxeSyntax(stringValue)) {
                var convertedValue = SimpleHaxeConverter.convertHaxeToPython(stringValue);
                
                // 特殊处理十六进制数值，将其转换为整数
                if (~/^0x([0-9a-fA-F]+)$/.match(convertedValue)) {
                    var hexValue = convertedValue.substr(2);
                    var intValue = Std.parseInt("0x" + hexValue);
                    interpreter.setVariable(name, intValue);
                    return;
                }
                
                interpreter.setVariable(name, convertedValue);
                return;
            }
        }
        
        interpreter.setVariable(name, value);
    }
    
    /**
     * Check if a string contains Haxe syntax that needs conversion
     */
    private function containsHaxeSyntax(code:String):Bool {
        // Check for hex numbers (0xFF0000)
        if (~/0x[0-9a-fA-F]+/.match(code)) {
            return true;
        }
        
        // Check for chained method calls (object.property.method())
        if (~/\w+\.\w+\.\w+\s*\(/.match(code)) {
            return true;
        }
        
        // Check for other Haxe patterns
        if (BasicHaxeConverter.isHaxeSyntax(code)) {
            return true;
        }
        
        return false;
    }
    
    /**
     * Set error handler callback
     */
    public function setErrorHandler(callback:String->Void):Void {
        onError = callback;
        interpreter.customErrorHandler = callback;
    }
    
    /**
     * Set print output callback
     */
    public function setPrintHandler(callback:Int->String->Void):Void {
        onPrint = callback;
        interpreter.customPrintHandler = callback;
    }
    
    /**
     * Set parent object
     * @param parent The parent object to set
     */
    public function setParent(parent:Dynamic):Void {
        this.parent = parent;
    }
    
    /**
     * Set error and print callbacks (convenience method)
     * @param location Script location identifier for error messages
     * @param scriptName Script name for print output prefix
     */
    public function setupCallbacks(?location:String = "script", ?scriptName:String = "script"):Void {
        // Set error callback
        onError = function(err:String) {
            #if openfl
            // Assuming PlayState instance exists, may need adjustment in actual use
            if (Reflect.hasField(Type.resolveClass("PlayState"), "instance")) {
                var playState = Reflect.field(Type.resolveClass("PlayState"), "instance");
                if (playState != null && Reflect.hasField(playState, "addTextToDebug")) {
                    Reflect.callMethod(playState, Reflect.field(playState, "addTextToDebug"), ['Failed to execute script at ${location}: ${err}', 0xFF0000]);
                }
            }
            #end
            trace('Failed to execute script at ${location}: ${err}');
        };
        
        // Set print callback
        onPrint = function(line:Int, s:String) {
            #if openfl
            // Assuming PlayState instance exists, may need adjustment in actual use
            if (Reflect.hasField(Type.resolveClass("PlayState"), "instance")) {
                var playState = Reflect.field(Type.resolveClass("PlayState"), "instance");
                if (playState != null && Reflect.hasField(playState, "addTextToDebug")) {
                    Reflect.callMethod(playState, Reflect.field(playState, "addTextToDebug"), ['${scriptName}:${line}: ${s}', 0xFFFFFF]);
                }
            }
            #end
            trace('${scriptName}:${line}: ${s}');
        };
        
        // Apply to interpreter
        interpreter.customErrorHandler = onError;
        interpreter.customPrintHandler = onPrint;
    }
    
    /**
     * Get variable from Python environment
     */
    public function getVar(name:String):Dynamic {
        return interpreter.getVariable(name);
    }
    
    /**
     * Execute Python script
     */
    public function execute():Void {
        if (scriptContent != null) {
            try {
                interpreter.run(scriptContent);
            } catch (e:pyscript.core.Interpreter.ReturnException) {
                // Top-level return statement, ignore
            } catch (e:Dynamic) {
                // Only use global error handling if enabled
                if (enableGlobalErrorHandling) {
                    if (onError != null) {
                        onError(Std.string(e));
                    } else {
                        trace("Python error: " + e);
                    }
                } else {
                    // Re-throw the exception to allow try-except handling
                    throw e;
                }
            }
        }
    }
    
    /**
     * Call Python function
     */
    public function callFunc(funcName:String, ?args:Array<Dynamic>):Dynamic {
        if (args == null) args = [];
        
        // Record last called function and script
        lastCalledFunction = funcName;
        lastCalledScript = this;
        
        try {
            if (interpreter == null) return "FUNC_CONT";
            
            // Check if function exists
            var func = null;
            try {
                func = interpreter.getVariable(funcName);
            } catch (e:Dynamic) {
                // If function is not defined, return silently without error
                return "FUNC_CONT";
            }
            if (func == null) {
                // Function doesn't exist, return silently without error
                return "FUNC_CONT";
            }
            
            // Call function directly, avoid building and executing code strings
            // Use safer way to check if it's a PythonFunction instance
            if (Reflect.hasField(func, "name") && Reflect.hasField(func, "parameters") && Reflect.hasField(func, "call")) {
                try {
                    // Use Reflect.callMethod to safely call the call method
                    return Reflect.callMethod(func, Reflect.field(func, "call"), [interpreter, args]);
                } catch (e:Dynamic) {
                    if (onError != null) {
                        onError("Python error (calling Python function): " + Std.string(e));
                    } else {
                        trace("Python error (calling Python function): " + e);
                    }
                    return "FUNC_CONT";
                }
            }
            
            // For non-PythonFunction, use optimized code call method
            var cacheKey:String;
            try {
                var argsLength:Int = args.length;
                cacheKey = funcName + "_" + argsLength;
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError("Python error: Invalid field access : length (args)");
                } else {
                    trace("Python error: Invalid field access : length (args)");
                }
                cacheKey = funcName + "_0";
            }
            var callCode:String = null;
            
            // Check if there's already built call code in cache
            if (callCodeCache.exists(cacheKey)) {
                callCode = callCodeCache.get(cacheKey);
                // Set parameters
                try {
                    var argsLength:Int = args.length;
                    for (i in 0...argsLength) {
                        var argName = "__arg" + i;
                        interpreter.setVariable(argName, args[i]);
                    }
                } catch (e:Dynamic) {
                    if (onError != null) {
                        onError("Python error: Invalid field access : length (args)");
                    } else {
                        trace("Python error: Invalid field access : length (args)");
                    }
                }
            } else {
                // Build function call code
            var argsStr = "";
            try {
                var argsLength:Int = args.length;
                for (i in 0...argsLength) {
                    if (i > 0) argsStr += ", ";
                    // Set parameters to temporary variables
                    var argName = "__arg" + i;
                    
                    // 特殊处理十六进制参数
                    var argValue = args[i];
                    if (Std.isOfType(argValue, String)) {
                        var strValue:String = cast argValue;
                        if (pyscript.utils.HexConverter.isHexValue(strValue)) {
                            // 将十六进制字符串转换为整数
                            argValue = pyscript.utils.HexConverter.hexToInt(strValue);
                        }
                    }
                    
                    interpreter.setVariable(argName, argValue);
                    argsStr += argName;
                }
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError("Python error: Invalid field access : length (args)");
                } else {
                    trace("Python error: Invalid field access : length (args)");
                }
            }
                
                callCode = "__result = " + funcName + "(" + argsStr + ")";
                // Cache call code
                callCodeCache.set(cacheKey, callCode);
            }
            
            interpreter.run(callCode);
            
            var result:Dynamic = interpreter.getVariable("__result");
            if (result == null) result = "FUNC_CONT";
            
            return result;
        } catch (e:Dynamic) {
            // Catch all exceptions, mark as fatal error
            interpreter.fatalError = true;
            // Output detailed error information
            if (onError != null) {
                onError("Python error (" + funcName + "): " + Std.string(e));
            } else {
                trace("Python error (" + funcName + "): " + e);
            }
            return "FUNC_CONT";
        }
    }
    
    /**
     * Call multiple Python functions in sequence
     * @param funcNames Array of function names to call
     * @param argsArray Array of argument arrays (one per function)
     * @return Array of results from each function call
     */
    public function callMultipleFunctions(funcNames:Array<String>, ?argsArray:Array<Array<Dynamic>> = null):Array<Dynamic> {
        var results:Array<Dynamic> = [];
        
        if (argsArray == null) argsArray = [];
        
        for (i in 0...funcNames.length) {
            var funcName = funcNames[i];
            var args:Array<Dynamic> = (i < argsArray.length) ? argsArray[i] : [];
            
            try {
                var result = callFunc(funcName, args);
                results.push(result);
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError("Python error (calling multiple functions - " + funcName + "): " + Std.string(e));
                } else {
                    trace("Python error (calling multiple functions - " + funcName + "): " + e);
                }
                results.push("FUNC_CONT");
            }
        }
        
        return results;
    }
    
    /**
     * Call all functions that match a prefix pattern
     * @param prefix Function name prefix to match
     * @param args Arguments to pass to each function
     * @return Array of results from each function call
     */
    public function callFunctionsByPrefix(prefix:String, ?args:Array<Dynamic> = null):Array<Dynamic> {
        var results:Array<Dynamic> = [];
        var matchedFunctions:Array<String> = [];
        
        // Get all variable names from interpreter
        var allVars = getGlobalScope();
        if (allVars == null) return results;
        
        // Find functions that match the prefix
        for (varName in allVars.keys()) {
            if (StringTools.startsWith(varName, prefix)) {
                var func = allVars.get(varName);
                if (func != null && isFunction(func)) {
                    matchedFunctions.push(varName);
                }
            }
        }
        
        // Call all matched functions
        for (funcName in matchedFunctions) {
            try {
                var result = callFunc(funcName, args);
                results.push(result);
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError("Python error (calling functions by prefix - " + funcName + "): " + Std.string(e));
                } else {
                    trace("Python error (calling functions by prefix - " + funcName + "): " + e);
                }
                results.push("FUNC_CONT");
            }
        }
        
        return results;
    }
    
    /**
     * Execute multiple function calls in a batch
     * @param functionCalls Array of objects with function name and arguments
     * @return Array of results from each function call
     */
    public function batchCallFunctions(functionCalls:Array<{funcName:String, ?args:Array<Dynamic>}>):Array<Dynamic> {
        var results:Array<Dynamic> = [];
        
        for (call in functionCalls) {
            try {
                var result = callFunc(call.funcName, call.args);
                results.push(result);
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError("Python error (batch function call - " + call.funcName + "): " + Std.string(e));
                } else {
                    trace("Python error (batch function call - " + call.funcName + "): " + e);
                }
                results.push("FUNC_CONT");
            }
        }
        
        return results;
    }
    
    /**
     * Check if a variable is a function
     */
    private function isFunction(func:Dynamic):Bool {
        if (func == null) return false;
        
        // Check if it's a PythonFunction instance
        if (Reflect.hasField(func, "name") && Reflect.hasField(func, "parameters") && Reflect.hasField(func, "call")) {
            return true;
        }
        
        // Check if it's a regular function
        return Reflect.isFunction(func);
    }
    
    /**
     * Check if function exists
     */
    public function hasFunc(funcName:String):Bool {
        var func = interpreter.getVariable(funcName);
        return func != null;
    }
    
    /**
     * Run single line Python code
     */
    public function run(code:String):Dynamic {
        try {
            return interpreter.run(code);
        } catch (e:Dynamic) {
            // Catch all exceptions, mark as fatal error
            interpreter.fatalError = true;
            if (onError != null) {
                onError("Python error: " + Std.string(e));
            } else {
                trace("Python error: " + e);
            }
            return null;
        }
    }
    
    /**
     * Clear all variables
     */
    public function clear():Void {
        interpreter = new Interpreter();
    }
    
    /**
     * Get all variable names
     */
    public function getVarNames():Array<String> {
        // This needs support in Interpreter
        return [];
    }
    
    /**
     * Get interpreter instance
     */
    public function getInterpreter():Interpreter {
        return interpreter;
    }
    
    /**
     * Set interpreter instance (for enhanced interpreter)
     */
    public function setInterpreter(interp:Interpreter):Void {
        interpreter = interp;
    }
    
    /**
     * Reset fatal error flag
     */
    public function resetFatalError():Void {
        interpreter.resetFatalError();
    }
    
    /**
     * Register module
     */
    public static function registerModule(name:String, script:PScript):Void {
        modules.set(name, script);
    }
    
    /**
     * Get registered module
     */
    public static function getModule(name:String):PScript {
        return modules.get(name);
    }
    
    /**
     * Register Haxe class for Python use
     * @param pythonName The name to use in Python scripts
     * @param haxeClass The Haxe class to register
     */
    public static function registerHaxeClass(pythonName:String, haxeClass:Class<Dynamic>):Void {
        haxeClasses.set(pythonName, haxeClass);
    }
    
    /**
     * Get registered Haxe class
     * @param pythonName The Python name of the class
     * @return The Haxe class or null if not found
     */
    public static function getHaxeClass(pythonName:String):Class<Dynamic> {
        return haxeClasses.get(pythonName);
    }
    
    /**
     * Register multiple Haxe classes at once
     * @param classMap Map of Python names to Haxe classes
     */
    public static function registerHaxeClasses(classMap:Map<String, Class<Dynamic>>):Void {
        for (pythonName in classMap.keys()) {
            haxeClasses.set(pythonName, classMap.get(pythonName));
        }
    }
    
    /**
     * Get global scope
     */
    public function getGlobalScope():Map<String, Dynamic> {
        return interpreter.getGlobalScope();
    }
    
    /**
     * Get script object
     */
    inline function get_script():Dynamic {
        return scriptObject;
    }
    
    /**
     * Get parent object
     */
    inline function get_parent():Dynamic {
        return scriptObject.parent;
    }
    
    /**
     * Set parent object
     */
    inline function set_parent(newParent:Dynamic):Dynamic {
        return scriptObject.parent = newParent;
    }
    
    /**
     * Process script content with Haxe syntax support
     * @param content The script content to process
     * @return Processed Python-compatible content
     */
    private function processScriptContent(content:String):String {
        if (content == null) return null;
        
        if (enableHaxeSyntax) {
            return BasicHaxeConverter.smartConvert(content);
        } else {
            return content;
        }
    }
    
    /**
     * Set script content with Haxe syntax support
     * @param content The script content to set
     */
    public function setScriptContent(content:String):Void {
        this.originalScriptContent = content;
        this.scriptContent = processScriptContent(content);
    }
    
    /**
     * Get original script content
     * @return The original script content
     */
    public function getOriginalScriptContent():String {
        return originalScriptContent;
    }
    
    /**
     * Set whether to enable Haxe syntax conversion
     * @param enable True to enable Haxe syntax conversion
     */
    public function setHaxeSyntaxEnabled(enable:Bool):Void {
        this.enableHaxeSyntax = enable;
        // Re-process content if it exists
        if (originalScriptContent != null) {
            this.scriptContent = processScriptContent(originalScriptContent);
        }
    }
    
    /**
     * Check if Haxe syntax is enabled
     * @return True if Haxe syntax is enabled
     */
    public function isHaxeSyntaxEnabled():Bool {
        return enableHaxeSyntax;
    }
}
