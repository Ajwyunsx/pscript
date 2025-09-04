package pyscript.extensions;

import pyscript.core.Interpreter;
import pyscript.utils.VariableHandler;
import pyscript.utils.PropertyHandler;

class InterpreterExtensions {
    private var interpreter:Interpreter;
    private var variableHandler:VariableHandler;
    private var propertyHandler:PropertyHandler;

    public function new(interpreter:Interpreter) {
        this.interpreter = interpreter;
        this.variableHandler = new VariableHandler(
            interpreter,
            interpreter.variables,
            interpreter.globals
        );
        this.propertyHandler = new PropertyHandler(interpreter);
    }

    /**
     * 处理表达式语句
     */
    public function handleExpressionStatement(node:ASTNode):Dynamic {
        trace("ExpressionStatement: Executing expression");
        var result = interpreter.evaluate(node.expression);
        trace("ExpressionStatement: Result = " + result);
        return result;
    }

    /**
     * 处理属性访问
     */
    public function handlePropertyAccess(node:ASTNode):Dynamic {
        return propertyHandler.handlePropertyAccess(node);
    }

    /**
     * 处理属性赋值
     */
    public function handlePropertyAssignment(node:ASTNode):Dynamic {
        return propertyHandler.handlePropertyAssignment(node);
    }

    /**
     * 处理变量声明
     */
    public function handleVariableDeclaration(node:ASTNode):Dynamic {
        var name = node.name;
        var value = node.value != null ? interpreter.evaluate(node.value) : null;
        variableHandler.setVariable(name, value);
        return value;
    }

    /**
     * 获取变量值
     */
    public function getVariable(name:String):Dynamic {
        return variableHandler.getVariable(name);
    }

    /**
     * 设置变量值
     */
    public function setVariable(name:String, value:Dynamic):Void {
        variableHandler.setVariable(name, value);
    }

    /**
     * 安全地转换为字符串
     */
    public function safeToString(value:Dynamic):String {
        if (value == null) return "null";
        try {
            return Std.string(value);
        } catch (e:Dynamic) {
            return "无法转换为字符串的对象";
        }
    }
}
