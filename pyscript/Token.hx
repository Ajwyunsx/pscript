package pyscript;

/**
 * Token类型枚举
 */
enum TokenType {
    // 字面量
    INT;
    FLOAT;
    STRING;
    TRUE;
    FALSE;
    NONE;
    IDENTIFIER;
    
    // 运算符
    PLUS;           // +
    MINUS;          // -
    MULTIPLY;       // *
    DIVIDE;         // /
    FLOOR_DIVIDE;   // //
    MODULO;         // %
    POWER;          // **
    ASSIGN;         // =
    PLUS_ASSIGN;    // +=
    MINUS_ASSIGN;   // -=
    MULTIPLY_ASSIGN; // *=
    DIVIDE_ASSIGN;  // /=
    MODULO_ASSIGN;  // %=
    
    // 比较运算符
    EQUALS;         // ==
    NOT_EQUALS;     // !=
    LESS_THAN;      // <
    GREATER_THAN;   // >
    LESS_EQUAL;     // <=
    GREATER_EQUAL;  // >=
    
    // 逻辑运算符
    AND;            // and
    OR;             // or
    NOT;            // not
    IS;             // is
    
    // 分隔符
    LPAREN;         // (
    RPAREN;         // )
    LBRACKET;       // [
    RBRACKET;       // ]
    LBRACE;         // {
    RBRACE;         // }
    COMMA;          // ,
    COLON;          // :
    SEMICOLON;      // ;
    DOT;            // .
    
    // 关键字
    DEF;            // def
    IF;             // if
    ELSE;           // else
    ELIF;           // elif
    WHILE;          // while
    FOR;            // for
    IN;             // in
    RETURN;         // return
    BREAK;          // break
    CONTINUE;       // continue
    PASS;           // pass
    CLASS;          // class
    IMPORT;         // import
    FROM;           // from
    AS;             // as
    TRY;            // try
    EXCEPT;         // except
    FINALLY;        // finally
    RAISE;          // raise
    WITH;           // with
    LAMBDA;         // lambda
    GLOBAL;         // global
    NONLOCAL;       // nonlocal
    
    // 特殊
    NEWLINE;
    INDENT;
    DEDENT;
    EOF;
    
    // LScript兼容语法
    SCRIPT_IMPORT;   // script:import
}

/**
 * Token类
 */
class Token {
    public var type:TokenType;
    public var value:Dynamic;
    public var line:Int;
    public var column:Int;
    
    public function new(type:TokenType, value:Dynamic, line:Int, column:Int) {
        this.type = type;
        this.value = value;
        this.line = line;
        this.column = column;
    }
    
    public function toString():String {
        return 'Token(${type}, ${value}, ${line}:${column})';
    }
}