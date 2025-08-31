package pyscript;

/**
 * AST节点类型枚举
 */
enum NodeType {
    Program;
    Block;
    
    // 语句
    ExpressionStatement;
    Assignment;
    PropertyAssignment;
    FunctionDef;
    ClassDef;
    ReturnStatement;
    GlobalStatement;
    ImportStatement;
    FromImportStatement;
    HaxeImportStatement;
    IfStatement;
    WhileLoop;
    ForLoop;
    BreakStatement;
    ContinueStatement;
    PassStatement;
    
    // 表达式
    BinaryOp;
    UnaryOp;
    FunctionCall;
    Identifier;
    Literal;
    IndexAccess;
    PropertyAccess;
    ListLiteral;
    DictLiteral;
    KeyValue;
}

/**
 * AST节点类
 */
class ASTNode {
    public var type:NodeType;
    
    // 通用属性
    // 通用属性
    public var value:Dynamic;
    public var name:String;
    public var superclass:String;
    
    // 语句列表
    public var statements:Array<ASTNode>;
    
    // 表达式
    public var expression:ASTNode;
    public var left:ASTNode;
    public var right:ASTNode;
    public var operand:ASTNode;
    public var op:String;
    
    // 函数相关
    public var func:ASTNode;
    public var arguments:Array<ASTNode>;
    public var parameters:Array<String>;
    public var body:ASTNode;
    
    // Global语句
    public var names:Array<String>;
    
    // Import语句
    public var module:String;
    public var alias:String;
    public var importNames:Array<String>;
    public var importAliases:Array<String>;
    
    // 控制流
    public var condition:ASTNode;
    public var thenBranch:ASTNode;
    public var elseBranch:ASTNode;
    
    // 循环
    public var variable:String;
    public var iterable:ASTNode;
    
    // 访问
    public var object:ASTNode;
    public var index:ASTNode;
    public var property:String;
    
    // 字典和列表
    public var elements:Array<ASTNode>;
    public var key:ASTNode;
    
    public function new(type:NodeType, ?value:Dynamic) {
        this.type = type;
        this.value = value;
        
        // 如果value是statements数组，使用它；否则初始化为空数组
        if (Std.isOfType(value, Array)) {
            this.statements = cast value;
            this.value = null; // 清除value，因为我们用它作为statements了
        } else {
            this.statements = [];
        }
        
        this.arguments = [];
        this.parameters = [];
        this.elements = [];
    }
    
    public function toString():String {
        return 'ASTNode(${type}, ${value})';
    }
}