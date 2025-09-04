package pyscript.ast;

import pyscript.ast.NodeType;

/**
 * AST节点包装器 - 用于避免抽象类型问题
 */
class ASTNodeWrapper {
    public var node:ASTNode;
    public var customElifBranches:Array<ASTNode>;
    
    public function new(node:ASTNode) {
        this.node = node;
        this.customElifBranches = [];
    }
    
    public function getElifBranches():Array<ASTNode> {
        return customElifBranches;
    }
    
    public function setElifBranches(value:Array<ASTNode>):Void {
        customElifBranches = value;
    }
}