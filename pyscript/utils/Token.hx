package pyscript.utils;

import pyscript.utils.TokenType;

/**
 * Token类
 * 表示一个词法单元,包含类型、值和位置信息
 */
class Token {
    // Token类型
    public var type:TokenType;
    
    // Token值,可能为:
    // - String: 标识符名、字符串内容
    // - Int: 整数值
    // - Float: 浮点数值
    // - null: 无值Token
    public var value:Dynamic;
    
    // 位置信息
    public var line:Int;     // 行号
    public var column:Int;   // 列号
    public var length:Int;   // Token长度
    
    /**
     * 构造函数
     * @param type Token类型
     * @param value Token值
     * @param line 行号
     * @param column 列号
     * @param length Token长度
     */
    public function new(type:TokenType, value:Dynamic, line:Int, column:Int, ?length:Int) {
        this.type = type;
        this.value = value;
        this.line = line;
        this.column = column;
        this.length = length != null ? length : computeLength();
    }
    
    /**
     * 计算Token长度
     * @return Token长度
     */
    private function computeLength():Int {
        if (value == null) return 0;
        return switch(type) {
            case TokenType.STRING: 
                // 字符串长度 + 2(引号)
                Std.string(value).length + 2;
            
            case TokenType.INT, TokenType.FLOAT:
                // 数字转字符串的长度
                Std.string(value).length;
            
            case TokenType.IDENTIFIER:
                // 标识符长度
                Std.string(value).length;
                
            case TokenType.INDENT: 4; // 缩进标准是4个空格
            case TokenType.DEDENT: 0;
            case TokenType.EOF: 0;
            
            // 运算符和分隔符长度
            case TokenType.PLUS, TokenType.MINUS, TokenType.MULTIPLY, 
                 TokenType.DIVIDE, TokenType.MODULO, TokenType.ASSIGN,
                 TokenType.LESS, TokenType.GREATER, TokenType.NOT,
                 TokenType.LPAREN, TokenType.RPAREN, TokenType.LBRACKET,
                 TokenType.RBRACKET, TokenType.LBRACE, TokenType.RBRACE,
                 TokenType.COMMA, TokenType.COLON, TokenType.DOT,
                 TokenType.SEMICOLON, TokenType.AT: 1;
                 
            case TokenType.EQUALS, TokenType.NOT_EQUALS,
                 TokenType.LESS_EQUAL, TokenType.GREATER_EQUAL,
                 TokenType.PLUS_ASSIGN, TokenType.MINUS_ASSIGN,
                 TokenType.MULTIPLY_ASSIGN, TokenType.DIVIDE_ASSIGN,
                 TokenType.POWER_ASSIGN, TokenType.ARROW: 2;
                 
            case TokenType.FLOOR_DIVIDE, TokenType.POWER,
                 TokenType.ELLIPSIS: 3;
                 
            // 关键字长度
            case TokenType.IF: 2;
            case TokenType.IN, TokenType.IS: 2;
            case TokenType.DEF: 3;
            case TokenType.FOR: 3;
            case TokenType.TRY: 3;
            case TokenType.AND: 3;
            case TokenType.DEL: 3;
            case TokenType.ELIF: 4;
            case TokenType.ELSE: 4;
            case TokenType.FROM: 4;
            case TokenType.NONE: 4;
            case TokenType.TRUE: 4;
            case TokenType.WITH: 4;
            case TokenType.PASS: 4;
            case TokenType.RAISE: 5;
            case TokenType.WHILE: 5;
            case TokenType.BREAK: 5;
            case TokenType.CLASS: 5;
            case TokenType.FALSE: 5;
            case TokenType.YIELD: 5;
            case TokenType.ASYNC: 5;
            case TokenType.AWAIT: 5;
            case TokenType.EXCEPT: 6;
            case TokenType.RETURN: 6;
            case TokenType.GLOBAL: 6;
            case TokenType.IMPORT: 6;
            case TokenType.LAMBDA: 6;
            case TokenType.ASSERT: 6;
            case TokenType.FINALLY: 7;
            case TokenType.NONLOCAL: 8;
            case TokenType.CONTINUE: 8;
            case TokenType.YIELD_FROM: 10;
            
            // 处理未使用的模式
            case TokenType.MATMULT, TokenType.BIT_AND, TokenType.BIT_OR,
                 TokenType.BIT_XOR, TokenType.BIT_NOT, TokenType.LSHIFT,
                 TokenType.RSHIFT, TokenType.LSHIFT_ASSIGN, TokenType.RSHIFT_ASSIGN,
                 TokenType.XOR_ASSIGN, TokenType.OR_ASSIGN, TokenType.AND_ASSIGN,
                 TokenType.BYTES, TokenType.AS: 1;
            
            default: 1;
        }
    }
    
    /**
     * 创建一个错误Token
     * @param message 错误信息
     * @param line 行号
     * @param column 列号
     * @return 错误Token
     */
    public static function error(message:String, line:Int, column:Int):Token {
        return new Token(TokenType.ERROR, message, line, column);
    }
    
    /**
     * 转为字符串表示
     * @return Token的字符串表示
     */
    public function toString():String {
        return switch(type) {
            case TokenType.INT, TokenType.FLOAT, 
                 TokenType.STRING, TokenType.IDENTIFIER:
                '${type}(${value})';
            
            case TokenType.ERROR:
                'Error: ${value}';
                
            case TokenType.EOF:
                'EOF';
                
            case TokenType.NEWLINE:
                'NEWLINE';
                
            case TokenType.INDENT:
                'INDENT';
                
            case TokenType.DEDENT:
                'DEDENT';
                
            default:
                Std.string(type);
        }
    }
    
    /**
     * 检查Token类型是否匹配
     * @param type 要匹配的类型
     * @return 是否匹配
     */
    public function isType(type:TokenType):Bool {
        return this.type == type;
    }
    
    /**
     * 检查Token是否是关键字
     * @return 是否是关键字
     */
    public function isKeyword():Bool {
        return switch(type) {
            case TokenType.IF, TokenType.ELIF, TokenType.ELSE,
                 TokenType.FOR, TokenType.WHILE,
                 TokenType.BREAK, TokenType.CONTINUE,
                 TokenType.RETURN, TokenType.PASS,
                 TokenType.DEF, TokenType.CLASS,
                 TokenType.TRY, TokenType.EXCEPT,
                 TokenType.FINALLY, TokenType.RAISE,
                 TokenType.IMPORT, TokenType.FROM,
                 TokenType.AS, TokenType.GLOBAL,
                 TokenType.NONLOCAL, TokenType.ASSERT,
                 TokenType.WITH, TokenType.LAMBDA,
                 TokenType.YIELD, TokenType.ASYNC,
                 TokenType.AWAIT: true;
            default: false;
        }
    }
    
    /**
     * 检查Token是否是运算符
     * @return 是否是运算符
     */
    public function isOperator():Bool {
        return switch(type) {
            case TokenType.PLUS, TokenType.MINUS,
                 TokenType.MULTIPLY, TokenType.DIVIDE,
                 TokenType.FLOOR_DIVIDE, TokenType.MODULO,
                 TokenType.POWER, TokenType.MATMULT,
                 TokenType.ASSIGN,
                 TokenType.PLUS_ASSIGN, TokenType.MINUS_ASSIGN,
                 TokenType.MULTIPLY_ASSIGN, TokenType.DIVIDE_ASSIGN,
                 TokenType.MODULO_ASSIGN, TokenType.POWER_ASSIGN,
                 TokenType.AND_ASSIGN, TokenType.OR_ASSIGN,
                 TokenType.XOR_ASSIGN,
                 TokenType.LSHIFT_ASSIGN, TokenType.RSHIFT_ASSIGN,
                 TokenType.BIT_AND, TokenType.BIT_OR,
                 TokenType.BIT_XOR, TokenType.BIT_NOT,
                 TokenType.LSHIFT, TokenType.RSHIFT,
                 TokenType.EQUALS, TokenType.NOT_EQUALS,
                 TokenType.LESS, TokenType.GREATER,
                 TokenType.LESS_EQUAL, TokenType.GREATER_EQUAL,
                 TokenType.AND, TokenType.OR, TokenType.NOT: true;
            default: false;
        }
    }
}

class TokenBuilder {
    public static function build(type:TokenType, value:Dynamic, line:Int, column:Int, ?length:Int):Token {
        return new Token(type, value, line, column, length);
    }
    
    public static function error(message:String, line:Int, column:Int):Token {
        return new Token(TokenType.ERROR, message, line, column);
    }
}
