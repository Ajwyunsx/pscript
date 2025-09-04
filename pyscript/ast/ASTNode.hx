package pyscript.ast;

import pyscript.ast.NodeType;

/**
 * AST节点类 - 用于构建Python语法的抽象语法树
 */
class ASTNode {
    public var type:NodeType;
    public var startLine:Int;
    public var startColumn:Int;
    public var endLine:Int;
    public var endColumn:Int;
    public var value:Dynamic;
    public var name:String;
    public var docString:String;
    public var statements:Array<ASTNode>;
    public var body:Array<ASTNode>;
    public var decorators:Array<ASTNode>;
    public var expression:ASTNode;
    public var left:ASTNode;
    public var right:ASTNode;
    public var operand:ASTNode;
    public var op:String;
    public var parameters:Array<ASTNode>;
    public var defaults:Array<ASTNode>;
    public var kwDefaults:Array<ASTNode>;
    public var vararg:String;
    public var kwarg:String;
    public var arguments:Array<ASTNode>;
    public var keywords:Array<{name:String, value:ASTNode}>;
    public var returns:ASTNode;
    public var bases:Array<ASTNode>;
    public var classKeywords:Array<{name:String, value:ASTNode}>;
    public var decoratorList:Array<ASTNode>;
    public var test:ASTNode;
    public var orelse:ASTNode;
    public var finalbody:ASTNode;
    public var iter:ASTNode;
    public var target:ASTNode;
    public var elifBranches:Array<ASTNode>;
    public var handlers:Array<ASTNode>;
    public var exctype:ASTNode;
    public var cause:ASTNode;
    public var module:String;
    public var names:Array<{name:String, asname:String}>;
    public var level:Int;
    public var identifierNames:Array<String>;
    public var object:ASTNode;
    public var attr:String;
    public var slice:ASTNode;
    public var index:ASTNode;
    public var start:ASTNode;
    public var end:ASTNode;
    public var step:ASTNode;
    public var items:Array<{context_expr:ASTNode, optional_vars:ASTNode}>;
    public var elements:Array<ASTNode>;
    public var keys:Array<ASTNode>;
    public var values:Array<ASTNode>;
    public var annotation:ASTNode;
    public var defaultValue:ASTNode;
    public var exc:ASTNode;
    public var msg:ASTNode;
    public var contextExpr:ASTNode;
    public var optionalVars:ASTNode;
    
    public function new(type:NodeType, ?value:Dynamic, ?startLine:Int = 0, ?startColumn:Int = 0, ?endLine:Int = 0, ?endColumn:Int = 0) {
        this.type = type;
        this.startLine = startLine;
        this.startColumn = startColumn;
        this.endLine = endLine;
        this.endColumn = endColumn;
        this.value = value;
        this.name = "";
        this.docString = "";
        this.statements = [];
        this.body = [];
        this.decorators = [];
        this.expression = null;
        this.left = null;
        this.right = null;
        this.operand = null;
        this.op = "";
        this.parameters = [];
        this.defaults = [];
        this.kwDefaults = [];
        this.vararg = "";
        this.kwarg = "";
        this.arguments = [];
        this.keywords = [];
        this.returns = null;
        this.bases = [];
        this.classKeywords = [];
        this.decoratorList = [];
        this.test = null;
        this.orelse = null;
        this.finalbody = null;
        this.iter = null;
        this.target = null;
        this.elifBranches = [];
        this.handlers = [];
        this.exctype = null;
        this.cause = null;
        this.module = "";
        this.names = [];
        this.level = 0;
        this.identifierNames = [];
        this.object = null;
        this.attr = "";
        this.slice = null;
        this.index = null;
        this.start = null;
        this.end = null;
        this.step = null;
        this.items = [];
        this.elements = [];
        this.keys = [];
        this.values = [];
        this.annotation = null;
        this.defaultValue = null;
        this.exc = null;
        this.msg = null;
        this.contextExpr = null;
        this.optionalVars = null;
    }
    
    public function toString():String {
        return 'ASTNode(${type}, ${value})';
    }
}