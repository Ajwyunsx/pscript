package pyscript.ast;

/**
 * AST节点类型枚举
 */
enum NodeType {
    // 程序结构
    Program;         // 整个程序
    Block;          // 代码块
    ExpressionStatement; // 表达式语句
    
    // 基本节点
    Literal;        // 字面量
    Identifier;     // 标识符
    
    // 运算符
    BinaryOp;       // 二元运算符
    UnaryOp;        // 一元运算符
    
    // 变量和属性
    Assignment;     // 赋值
    PropertyAssignment; // 属性赋值
    PropertyAccess; // 属性访问
    IndexAccess;    // 索引访问
    IndexAssignment; // 索引赋值
    Slice;          // 切片
    
    // 数据结构
    ListLiteral;    // 列表字面量
    DictLiteral;    // 字典字面量
    SetLiteral;     // 集合字面量
    TupleLiteral;   // 元组字面量
    KeyValue;       // 键值对
    
    // 函数相关
    FunctionDef;    // 函数定义
    FunctionCall;   // 函数调用
    Parameter;      // 参数
    VarArgsParameter; // 可变位置参数
    KwargsParameter; // 可变关键字参数
    ReturnStatement; // return语句
    YieldStatement; // yield语句
    YieldFromStatement; // yield from语句
    
    // 控制流
    IfStatement;    // if语句
    ElifBranch;     // elif分支
    WhileStatement; // while循环
    ForStatement;   // for循环
    BreakStatement; // break语句
    ContinueStatement; // continue语句
    PassStatement;  // pass语句
    
    // 异常处理
    TryStatement;   // try语句
    ExceptHandler;  // except处理器
    FinallyClause;  // finally子句
    RaiseStatement; // raise语句
    AssertStatement; // assert语句
    
    // 类相关
    ClassDef;       // 类定义
    MethodDef;      // 方法定义
    PropertyDef;    // 属性定义
    
    // 模块系统
    ImportStatement; // import语句
    FromImport;     // from...import语句
    ModuleStatement; // 模块级语句
    
    // 作用域控制
    GlobalStatement; // global语句
    NonlocalStatement; // nonlocal语句
    
    // 上下文管理
    WithStatement;  // with语句
    WithItem;       // with项
    
    // 装饰器
    Decorator;      // 装饰器
    
    // 异步相关
    AsyncStatement; // async语句
    
    // 注解
    Annotation;     // 类型注解
    Comment;        // 注释
}
