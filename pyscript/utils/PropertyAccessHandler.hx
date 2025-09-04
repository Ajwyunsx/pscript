package pyscript;

import pyscript.ASTNode;
import pyscript.NodeType;

typedef PropertyAssignment = {
    chain:Array<String>,
    value:Dynamic
}

/**
 * 专门处理属性访问和赋值的助手类
 */
class PropertyAccessHandler {
    private var interpreter:Interpreter;
    private var propertyChain:PropertyChain;
    
    public function new(interpreter:Interpreter) {
        this.interpreter = interpreter;
        this.propertyChain = new PropertyChain(interpreter);
    }
    
    /**
     * 从AST节点中提取属性链
     * 例如: game.camHUD.alpha -> ["game", "camHUD", "alpha"]
     */
    public function extractPropertyChain(node:ASTNode):Array<String> {
        var chain = new Array<String>();
        
        if (node == null) return chain;
        
        function extractFromNode(currentNode:ASTNode) {
            if (currentNode == null) return;
            
            switch (currentNode.type) {
                case Identifier:
                    chain.unshift(currentNode.name);
                case PropertyAccess:
                    chain.push(getPropertyName(currentNode.property));
                    extractFromNode(currentNode.object);
                default:
                    // 忽略其他节点类型
            }
        }
        
        extractFromNode(node);
        return chain;
    }
    
    /**
     * 处理属性赋值
     * 例如: game.camHUD.alpha = 0
     */
    public function handlePropertyAssignment(node:ASTNode):Dynamic {
        // 提取属性链
        var chain = extractPropertyChain(node.object);
        if (chain.length == 0) {
            trace("Error: Invalid property chain");
            return null;
        }
        chain.push(getPropertyName(node.property));
        
        // 获取要设置的值
        var value = interpreter.evaluate(node.value);
        trace('Setting property chain [${chain.join(".")}] = ${value}');
        
        // 设置属性值
        propertyChain.setValue(chain, value);
        return value;
    }
    
    /**
     * 处理属性访问
     * 例如: game.camHUD.alpha
     */
    public function handlePropertyAccess(node:ASTNode):Dynamic {
        var chain = extractPropertyChain(node);
        trace('Getting property chain [${chain.join(".")}]');
        return propertyChain.getValue(chain);
    }
    
    /**
     * 获取属性名称
     */
    private function getPropertyName(prop:Dynamic):String {
        if (prop == null) return null;
        
        if (Std.isOfType(prop, String)) {
            return prop;
        }
        
        if (Reflect.hasField(prop, "name")) {
            return Reflect.field(prop, "name");
        }
        
        if (Reflect.hasField(prop, "value")) {
            var value = Reflect.field(prop, "value");
            return value != null ? Std.string(value) : null;
        }
        
        return Std.string(prop);
    }
}
