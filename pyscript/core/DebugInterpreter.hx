package pyscript.core;

/**
 * 调试用的解释器 - 追踪变量变化
 */
class DebugInterpreter extends Interpreter {
    public var debugLog:Array<String>;
    public var gameChanges:Array<Dynamic>;
    
    public function new() {
        super();
        debugLog = [];
        gameChanges = [];
    }
    
    override public function setVariable(name:String, value:Dynamic):Void {
        // 调试日志
        if (name == "game") {
            var change = {
                value: value,
                type: Type.typeof(value),
                stack: "Set from script"
            };
            gameChanges.push(change);
            
            debugLog.push("Game changed to: " + Std.string(value) + " (" + Type.typeof(value) + ")");
            
            // 检测是否变成字符串
            if (Std.isOfType(value, String)) {
                debugLog.push("WARNING: Game became a string!");
            }
        }
        
        super.setVariable(name, value);
    }
    
    override private function evaluateAssignment(node:ASTNode):Dynamic {
        var value = evaluate(node.value);
        
        if (node.name == "game") {
            debugLog.push("Assignment to game: " + Std.string(value) + " (" + Type.typeof(value) + ")");
        }
        
        setVariable(node.name, value);
        return value;
    }
    
    override private function evaluateFunctionDef(node:ASTNode):Dynamic {
        debugLog.push("Defining function: " + node.name);
        
        var func = new PythonFunction(node.name, node.parameters, node.body, node.decorators);
        functions.set(node.name, func);
        
        // 检查是否会覆盖 game
        if (node.name == "game" && globals.exists("game")) {
            var existingValue = globals.get("game");
            if (!Std.isOfType(existingValue, PythonFunction)) {
                debugLog.push("WARNING: Function " + node.name + " would overwrite game object!");
                return func;
            }
        }
        
        globals.set(node.name, func);
        return func;
    }
    
    public function printDebugLog():Void {
        trace("\n=== Debug Log ===");
        for (entry in debugLog) {
            trace(entry);
        }
        
        trace("\n=== Game Changes ===");
        for (i in 0...gameChanges.length) {
            var change = gameChanges[i];
            trace("Change " + (i + 1) + ": " + Std.string(change.value) + " (" + change.type + ")");
        }
    }
}