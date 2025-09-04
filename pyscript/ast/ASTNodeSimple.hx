package pyscript.ast;

import pyscript.ast.NodeType;

/**
 * AST节点类 - 简化版本用于测试
 */
class ASTNodeSimple {
    public var type:NodeType;
    public var startLine:Int;
    public var startColumn:Int;
    public var endLine:Int;
    public var endColumn:Int;
    public var value:Dynamic;
    public var name:String;
    public var docString:String;
    public var statements:Array<ASTNodeSimple>;
    public var body:Array<ASTNodeSimple>;
    public var decorators:Array<ASTNodeSimple>;
    public var expression:ASTNodeSimple;
    public var left:ASTNodeSimple;
    public var right:ASTNodeSimple;
    public var operand:ASTNodeSimple;
    public var op:String;
    public var parameters:Array<ASTNodeSimple>;
    public var defaults:Array<ASTNodeSimple>;
    public var kwDefaults:Array<ASTNodeSimple>;
    public var vararg:String;
    public var kwarg:String;
    public var arguments:Array<ASTNodeSimple>;
    public var keywords:Array<{name:String, value:ASTNodeSimple}>;
    public var returns:ASTNodeSimple;
    public var bases:Array<ASTNodeSimple>;
    public var classKeywords:Array<{name:String, value:ASTNodeSimple}>;
    public var decoratorList:Array<ASTNodeSimple>;
    public var test:ASTNodeSimple;
    public var orelse:ASTNodeSimple;
    public var finalbody:ASTNodeSimple;
    public var iter:ASTNodeSimple;
    public var target:ASTNodeSimple;
    public var elifBranches:Array<ASTNodeSimple>;
    public var handlers:Array<ASTNodeSimple>;
    public var exctype:ASTNodeSimple;
    public var cause:ASTNodeSimple;
    public var module:String;
    public var names:Array<{name:String, asname:String}>;
    public var level:Int;
    public var identifierNames:Array<String>;
    public var object:ASTNodeSimple;
    public var attr:String;
    public var slice:ASTNodeSimple;
    public var index:ASTNodeSimple;
    public var start:ASTNodeSimple;
    public var end:ASTNodeSimple;
    public var step:ASTNodeSimple;
    public var items:Array<{context_expr:ASTNodeSimple, optional_vars:ASTNodeSimple}>;
    public var elements:Array<ASTNodeSimple>;
    public var keys:Array<ASTNodeSimple>;
    public var values:Array<ASTNodeSimple>;
    public var annotation:ASTNodeSimple;
    public var defaultValue:ASTNodeSimple;
    public var exc:ASTNodeSimple;
    public var msg:ASTNodeSimple;
    public var contextExpr:ASTNodeSimple;
    public var optionalVars:ASTNodeSimple;
    
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