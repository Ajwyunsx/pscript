package pyscript.core;

import pyscript.utils.Token;
import pyscript.utils.TokenType;

/**
 * Python词法分析器
 * 将源代码字符串转换为Token序列
 */
class Lexer {
    // 源代码和当前位置
    private var source:String;           // 源代码字符串
    private var tokens:Array<Token>;     // 生成的Token列表
    private var start:Int;               // 当前Token起始位置
    private var current:Int;             // 当前字符位置
    private var line:Int;                // 当前行号
    private var column:Int;              // 当前列号
    
    // 缩进跟踪
    private var indentStack:Array<Int>;  // 缩进级别栈
    private var pendingIndent:Int;       // 待处理的缩进
    
    /**
     * 构造函数
     */
    public function new() {
        reset();
    }
    
    /**
     * 重置词法分析器状态
     */
    public function reset():Void {
        source = "";
        tokens = [];
        start = 0;
        current = 0;
        line = 1;
        column = 1;
        indentStack = [0];
        pendingIndent = 0;
    }
    
    /**
     * 设置源代码
     * @param source 源代码字符串
     */
    public function setSource(source:String):Void {
        reset();
        this.source = source;
    }
    
    /**
     * 执行词法分析
     * @return Token序列
     */
    public function tokenize():Array<Token> {
        
        while (!isAtEnd()) {
            start = current;
            scanToken();
        }
        
        // 添加EOF Token
        addToken(TokenType.EOF, null);
        
        return tokens;
    }
    
    /**
     * 扫描单个Token
     */
    private function scanToken():Void {
        var c = advance();
        
        switch (c) {
            // 空白字符
            case ' ', '\t', '\r':
                // 跳过空白字符
                skipWhitespace();
                
            // 换行符
            case '\n':
                handleNewline();
                
            // 单字符Token
            case '(': addToken(TokenType.LPAREN, null); 
            case ')': addToken(TokenType.RPAREN, null); 
            case '[': addToken(TokenType.LBRACKET, null); 
            case ']': addToken(TokenType.RBRACKET, null); 
            case '{': addToken(TokenType.LBRACE, null); 
            case '}': addToken(TokenType.RBRACE, null); 
            case ',': addToken(TokenType.COMMA, null); 
            case ':': addToken(TokenType.COLON, null); 
            case ';': addToken(TokenType.SEMICOLON, null); 
            case '#': 
                skipComment();
                return; 
            case '.': 
                if (match('.')) {
                    if (match('.')) {
                        addToken(TokenType.ELLIPSIS, null); // ...
                    } else {
                        // 回退两个点
                        current -= 2;
                        addToken(TokenType.DOT, null);
                    }
                } else {
                    addToken(TokenType.DOT, null);
                }
            case '@': addToken(TokenType.AT, null); 
                
            // 一或两个字符Token
            case '+': 
                if (match('=')) addToken(TokenType.PLUS_ASSIGN, null);
                else addToken(TokenType.PLUS, "+");
            case '-': 
                if (match('=')) addToken(TokenType.MINUS_ASSIGN, null);
                else addToken(TokenType.MINUS, "-");
            case '*': 
                if (match('=')) addToken(TokenType.MULTIPLY_ASSIGN, null);
                else if (match('*')) addToken(TokenType.POWER, "**");
                else addToken(TokenType.MULTIPLY, "*");
            case '/': 
                if (match('=')) addToken(TokenType.DIVIDE_ASSIGN, null);
                else if (match('/')) addToken(TokenType.FLOOR_DIVIDE, "//");
                else if (match('*')) {
                    // 处理 /* */ 注释
                    skipBlockComment();
                } else {
                    addToken(TokenType.DIVIDE, "/");
                }
            case '%': 
                if (match('=')) addToken(TokenType.MODULO_ASSIGN, null);
                else addToken(TokenType.MODULO, "%");
            case '=': 
                if (match('=')) addToken(TokenType.EQUALS, "==");
                else addToken(TokenType.ASSIGN, "=");
            case '!': 
                if (match('=')) addToken(TokenType.NOT_EQUALS, "!=");
                else addToken(TokenType.NOT, "!");
            case '<': 
                if (match('=')) addToken(TokenType.LESS_EQUAL, "<=");
                else if (match('<')) {
                    if (match('=')) addToken(TokenType.LSHIFT_ASSIGN, "<<=");
                    else addToken(TokenType.LSHIFT, "<<");
                } else addToken(TokenType.LESS, "<");
            case '>': 
                if (match('=')) addToken(TokenType.GREATER_EQUAL, ">=");
                else if (match('>')) {
                    if (match('=')) addToken(TokenType.RSHIFT_ASSIGN, ">>=");
                    else addToken(TokenType.RSHIFT, ">>");
                } else addToken(TokenType.GREATER, ">");
            case '&': 
                if (match('=')) addToken(TokenType.AND_ASSIGN, null);
                else addToken(TokenType.BIT_AND, null);
            case '|': 
                if (match('=')) addToken(TokenType.OR_ASSIGN, null);
                else addToken(TokenType.BIT_OR, null);
            case '^': 
                if (match('=')) addToken(TokenType.XOR_ASSIGN, null);
                else addToken(TokenType.BIT_XOR, null);
            case '~': addToken(TokenType.BIT_NOT, null); 
                
            // 字符串字面量
            case '"', '\'':
                scanString();
                
            // 数字字面量
            default:
                if (isDigit(c)) {
                    scanNumber();
                } else if (isAlpha(c)) {
                    scanIdentifier();
                } else {
                    error("Unexpected character: " + c);
                }
        }
    }
    
    /**
     * 扫描字符串字面量
     */
    private function scanString():Void {
        var quote = source.charAt(start); // 获取引号类型
        var value = "";
        
        while (!isAtEnd() && source.charAt(current) != quote) {
            var c = advance();
            
            // 处理转义字符
            if (c == '\\') {
                if (isAtEnd()) {
                    error("Unterminated string escape sequence");
                    return;
                }
                
                var escaped = advance();
                switch (escaped) {
                    case 'n': value += "\n";
                    case 't': value += "\t";
                    case 'r': value += "\r";
                    case '\\': value += "\\";
                    case '\'': value += "'";
                    case '"': value += "\"";
                    default: value += escaped;
                }
            } else {
                value += c;
            }
        }
        
        if (isAtEnd()) {
            error("Unterminated string");
            return;
        }
        
        advance(); // 消耗结束引号
        addToken(TokenType.STRING, value);
    }
    
    /**
     * 扫描数字字面量
     */
    private function scanNumber():Void {
        // 第一个数字已经被advance()消耗了，需要从previous()获取
        var value = peekPrev();
        var isFloat = false;
        var hasExponent = false;
        
        // 整数部分
        while (!isAtEnd() && isDigit(peek())) {
            value += advance();
        }
        
        // 小数部分
        if (!isAtEnd() && peek() == '.' && isDigit(peekNext())) {
            isFloat = true;
            value += advance(); // 消耗小数点
            
            while (!isAtEnd() && isDigit(peek())) {
                value += advance();
            }
        }
        
        // 指数部分
        if (!isAtEnd() && (peek() == 'e' || peek() == 'E')) {
            hasExponent = true;
            value += advance(); // 消耗e/E
            
            // 可选的+/-符号
            if (!isAtEnd() && (peek() == '+' || peek() == '-')) {
                value += advance();
            }
            
            // 指数数字
            while (!isAtEnd() && isDigit(peek())) {
                value += advance();
            }
        }
        
        // 根据类型添加Token
        if (isFloat || hasExponent) {
            addToken(TokenType.FLOAT, Std.parseFloat(value));
        } else {
            // 检查是否是其他进制的数字
            if (value.length > 1 && value.charAt(0) == '0') {
                var secondChar = value.charAt(1);
                if (secondChar == 'x' || secondChar == 'X') {
                    // 十六进制
                    var hexValue = value.substr(2);
                    addToken(TokenType.INT, Std.parseInt("0x" + hexValue));
                } else if (secondChar == 'b' || secondChar == 'B') {
                    // 二进制
                    var binValue = value.substr(2);
                    addToken(TokenType.INT, Std.parseInt("0b" + binValue));
                } else if (secondChar == 'o' || secondChar == 'O') {
                    // 八进制
                    var octValue = value.substr(2);
                    addToken(TokenType.INT, Std.parseInt("0o" + octValue));
                } else {
                    // 普通十进制
                    addToken(TokenType.INT, Std.parseInt(value));
                }
            } else {
                addToken(TokenType.INT, Std.parseInt(value));
            }
        }
    }
    
    /**
     * 扫描标识符或关键字
     */
    private function scanIdentifier():Void {
        // 第一个字符已经被advance()消耗了，需要从previous()获取
        var value = peekPrev();
        
        while (!isAtEnd() && isAlphaNumeric(peek())) {
            value += advance();
        }
        
        // 检查是否是关键字
        var type = TokenType.IDENTIFIER;
        switch (value) {
            case "and": type = TokenType.AND; 
            case "as": type = TokenType.AS; 
            case "assert": type = TokenType.ASSERT; 
            case "async": type = TokenType.ASYNC; 
            case "await": type = TokenType.AWAIT; 
            case "break": type = TokenType.BREAK; 
            case "class": type = TokenType.CLASS; 
            case "continue": type = TokenType.CONTINUE; 
            case "def": type = TokenType.DEF; 
            case "del": type = TokenType.DEL; 
            case "elif": type = TokenType.ELIF; 
            case "else": type = TokenType.ELSE; 
            case "except": type = TokenType.EXCEPT; 
            case "False": type = TokenType.FALSE; 
            case "finally": type = TokenType.FINALLY; 
            case "for": type = TokenType.FOR; 
            case "from": type = TokenType.FROM; 
            case "global": type = TokenType.GLOBAL; 
            case "if": type = TokenType.IF; 
            case "import": type = TokenType.IMPORT; 
            case "in": type = TokenType.IN; 
            case "is": type = TokenType.IS; 
            case "lambda": type = TokenType.LAMBDA; 
            case "None": type = TokenType.NONE; 
            case "nonlocal": type = TokenType.NONLOCAL; 
            case "not": type = TokenType.NOT; 
            case "or": type = TokenType.OR; 
            case "pass": type = TokenType.PASS; 
            case "raise": type = TokenType.RAISE; 
            case "return": type = TokenType.RETURN; 
            case "True": type = TokenType.TRUE; 
            case "try": type = TokenType.TRY; 
            case "while": type = TokenType.WHILE; 
            case "with": type = TokenType.WITH; 
            case "yield": type = TokenType.YIELD; 
        }
        
        addToken(type, value);
    }
    
    /**
     * 处理换行符
     */
    private function handleNewline():Void {
        line++;
        column = 1;
        
        // 检查缩进变化
        var indentLevel = 0;
        var tempPos = current;
        
        // 计算当前行的缩进级别
        while (tempPos < source.length) {
            var c = source.charAt(tempPos);
            if (c == ' ') {
                indentLevel++;
            } else if (c == '\t') {
                indentLevel += 4; // 假设制表符为4个空格
            } else {
                break;
            }
            tempPos++;
        }
        
        // 比较缩进级别
        var currentIndent = indentStack[indentStack.length - 1];
        
        if (indentLevel > currentIndent) {
            // 增加缩进
            indentStack.push(indentLevel);
            addToken(TokenType.INDENT, null);
        } else if (indentLevel < currentIndent) {
            // 减少缩进
            while (indentStack.length > 1 && indentStack[indentStack.length - 1] > indentLevel) {
                indentStack.pop();
                addToken(TokenType.DEDENT, null);
            }
        }
        
        // 添加换行Token
        addToken(TokenType.NEWLINE, null);
    }
    
    /**
     * 跳过空白字符
     */
    private function skipWhitespace():Void {
        while (!isAtEnd() && isWhitespace(peek())) {
            advance();
        }
    }
    
    /**
     * 跳过块注释
     */
    private function skipBlockComment():Void {
        while (!isAtEnd() && !(peek() == '*' && peekNext() == '/')) {
            if (peek() == '\n') {
                handleNewline();
            } else {
                advance();
            }
        }
        
        if (isAtEnd()) {
            error("Unterminated block comment");
            return;
        }
        
        advance(); // 消耗 *
        advance(); // 消耗 /
    }
    
    /**
     * 跳过行注释 # ...
     */
    private function skipComment():Void {
        while (!isAtEnd() && peek() != '\n') {
            advance();
        }
    }
    
    /**
     * 添加Token
     * @param type Token类型
     * @param value Token值
     */
    private function addToken(type:TokenType, value:Dynamic):Void {
        var text = source.substring(start, current);
        tokens.push(new Token(type, value, line, column - (current - start), current - start));
    }
    
    /**
     * 检查是否到达文件末尾
     * @return 是否到达末尾
     */
    private function isAtEnd():Bool {
        return current >= source.length;
    }
    
    /**
     * 获取当前字符并前进
     * @return 当前字符
     */
    private function advance():String {
        if (isAtEnd()) return "";
        column++;
        return source.charAt(current++);
    }
    
    /**
     * 查看当前字符但不前进
     * @return 当前字符
     */
    private function peek():String {
        if (isAtEnd()) return "";
        return source.charAt(current);
    }
    
    /**
     * 查看下一个字符但不前进
     * @return 下一个字符
     */
    private function peekNext():String {
        if (current + 1 >= source.length) return "";
        return source.charAt(current + 1);
    }
    
    /**
     * 查看前一个字符
     * @return 前一个字符
     */
    private function peekPrev():String {
        if (current - 1 < 0) return "";
        return source.charAt(current - 1);
    }
    
    /**
     * 检查当前字符是否匹配期望字符
     * @param expected 期望的字符
     * @return 是否匹配
     */
    private function match(expected:String):Bool {
        if (isAtEnd()) return false;
        if (source.charAt(current) != expected) return false;
        
        current++;
        column++;
        return true;
    }
    
    /**
     * 创建Token
     * @param type Token类型
     * @param value Token值
     * @return 创建的Token
     */
    private function makeToken(type:TokenType, value:Dynamic):Token {
        var text = source.substring(start, current);
        return new Token(type, value, line, column - (current - start), current - start);
    }
    
    /**
     * 报告错误
     * @param message 错误消息
     */
    private function error(message:String):Void {
        var token = makeToken(TokenType.ERROR, message);
        tokens.push(token);
    }
    
    /**
     * 检查字符是否为数字
     * @param c 要检查的字符
     * @return 是否为数字
     */
    private function isDigit(c:String):Bool {
        return c >= "0" && c <= "9";
    }
    
    /**
     * 检查字符是否为字母
     * @param c 要检查的字符
     * @return 是否为字母
     */
    private function isAlpha(c:String):Bool {
        return (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || c == "_";
    }
    
    /**
     * 检查字符是否为字母或数字
     * @param c 要检查的字符
     * @return 是否为字母或数字
     */
    private function isAlphaNumeric(c:String):Bool {
        return isAlpha(c) || isDigit(c);
    }
    
    /**
     * 检查字符是否为空白字符
     * @param c 要检查的字符
     * @return 是否为空白字符
     */
    private function isWhitespace(c:String):Bool {
        return c == " " || c == "\t" || c == "\r";
    }
}
