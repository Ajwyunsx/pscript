package pyscript;

import pyscript.Token.TokenType;

/**
 * Python词法分析器
 */
class Lexer {
    
    private var source:String;
    private var position:Int;
    private var line:Int;
    private var column:Int;
    private var tokens:Array<Token>;
    
    public function new(source:String) {
        this.source = source;
        this.position = 0;
        this.line = 1;
        this.column = 1;
        this.tokens = [];
    }
    
    public function tokenize():Array<Token> {
        while (position < source.length) {
            skipWhitespace();
            
            if (position >= source.length) break;
            
            var char = source.charAt(position);
            
            if (char == "#") {
                skipComment();
                continue;
            }
            
            if (char == '"' || char == "'") {
                tokenizeString();
                continue;
            }
            
            if (isDigit(char)) {
                tokenizeNumber();
                continue;
            }
            
            if (isAlpha(char) || char == "_") {
                tokenizeIdentifier();
                continue;
            }
            
            if (tokenizeOperator()) {
                continue;
            }
            
            if (char == "\n") {
                addToken(TokenType.NEWLINE, char);
                advance();
                line++;
                column = 1;
                continue;
            }
            
            throw "Unexpected character: " + char + " at line " + line + ", column " + column;
        }
        
        addToken(TokenType.EOF, null);
        return tokens;
    }
    
    private function skipWhitespace():Void {
        while (position < source.length) {
            var char = source.charAt(position);
            if (char == " " || char == "\t" || char == "\r") {
                advance();
            } else {
                break;
            }
        }
    }
    
    private function skipComment():Void {
        while (position < source.length && source.charAt(position) != "\n") {
            advance();
        }
    }
    
    private function tokenizeString():Void {
        var quote = source.charAt(position);
        advance();
        
        var value = "";
        while (position < source.length && source.charAt(position) != quote) {
            var char = source.charAt(position);
            if (char == "\\") {
                advance();
                if (position < source.length) {
                    var escaped = source.charAt(position);
                    switch (escaped) {
                        case "n": value += "\n";
                        case "t": value += "\t";
                        case "r": value += "\r";
                        case "\\": value += "\\";
                        case '"': value += '"';
                        case "'": value += "'";
                        default: value += escaped;
                    }
                    advance();
                }
            } else {
                value += char;
                advance();
            }
        }
        
        if (position >= source.length) {
            throw "Unterminated string at line " + line;
        }
        
        advance();
        addToken(TokenType.STRING, value);
    }
    
    private function tokenizeNumber():Void {
        var value = "";
        var isFloat = false;
        
        while (position < source.length && (isDigit(source.charAt(position)) || source.charAt(position) == ".")) {
            var char = source.charAt(position);
            if (char == ".") {
                if (isFloat) break;
                isFloat = true;
            }
            value += char;
            advance();
        }
        
        if (isFloat) {
            addToken(TokenType.FLOAT, Std.parseFloat(value));
        } else {
            addToken(TokenType.INT, Std.parseInt(value));
        }
    }
    
    private function tokenizeIdentifier():Void {
        var value = "";
        
        while (position < source.length && (isAlphaNumeric(source.charAt(position)) || source.charAt(position) == "_")) {
            value += source.charAt(position);
            advance();
        }
        
        // 检查是否是script:import语法
        if (value == "script" && position < source.length && source.charAt(position) == ":") {
            // 跳过冒号
            advance();
            
            // 读取import
            var importWord = "";
            while (position < source.length && (isAlphaNumeric(source.charAt(position)) || source.charAt(position) == "_")) {
                importWord += source.charAt(position);
                advance();
            }
            
            if (importWord == "import") {
                addToken(TokenType.SCRIPT_IMPORT, "script:import");
                return;
            } else {
                // 如果不是import，回退并按普通标识符处理
                position -= importWord.length + 1;
                column -= importWord.length + 1;
            }
        }
        
        var tokenType = getKeywordType(value);
        if (tokenType == null) {
            tokenType = TokenType.IDENTIFIER;
        }
        
        addToken(tokenType, value);
    }
    
    private function tokenizeOperator():Bool {
        var char = source.charAt(position);
        var nextChar = position + 1 < source.length ? source.charAt(position + 1) : "";
        
        // 双字符运算符
        var twoChar = char + nextChar;
        switch (twoChar) {
            case "==": addToken(TokenType.EQUALS, twoChar); advance(); advance(); return true;
            case "!=": addToken(TokenType.NOT_EQUALS, twoChar); advance(); advance(); return true;
            case "<=": addToken(TokenType.LESS_EQUAL, twoChar); advance(); advance(); return true;
            case ">=": addToken(TokenType.GREATER_EQUAL, twoChar); advance(); advance(); return true;
            case "//": addToken(TokenType.FLOOR_DIVIDE, twoChar); advance(); advance(); return true;
            case "**": addToken(TokenType.POWER, twoChar); advance(); advance(); return true;
            case "+=": addToken(TokenType.PLUS_ASSIGN, twoChar); advance(); advance(); return true;
            case "-=": addToken(TokenType.MINUS_ASSIGN, twoChar); advance(); advance(); return true;
            case "*=": addToken(TokenType.MULTIPLY_ASSIGN, twoChar); advance(); advance(); return true;
            case "/=": addToken(TokenType.DIVIDE_ASSIGN, twoChar); advance(); advance(); return true;
            case "%=": addToken(TokenType.MODULO_ASSIGN, twoChar); advance(); advance(); return true;
        }
        
        // 单字符运算符
        switch (char) {
            case "+": addToken(TokenType.PLUS, char); advance(); return true;
            case "-": addToken(TokenType.MINUS, char); advance(); return true;
            case "*": addToken(TokenType.MULTIPLY, char); advance(); return true;
            case "/": addToken(TokenType.DIVIDE, char); advance(); return true;
            case "%": addToken(TokenType.MODULO, char); advance(); return true;
            case "=": addToken(TokenType.ASSIGN, char); advance(); return true;
            case "<": addToken(TokenType.LESS_THAN, char); advance(); return true;
            case ">": addToken(TokenType.GREATER_THAN, char); advance(); return true;
            case "(": addToken(TokenType.LPAREN, char); advance(); return true;
            case ")": addToken(TokenType.RPAREN, char); advance(); return true;
            case "[": addToken(TokenType.LBRACKET, char); advance(); return true;
            case "]": addToken(TokenType.RBRACKET, char); advance(); return true;
            case "{": addToken(TokenType.LBRACE, char); advance(); return true;
            case "}": addToken(TokenType.RBRACE, char); advance(); return true;
            case ",": addToken(TokenType.COMMA, char); advance(); return true;
            case ":": addToken(TokenType.COLON, char); advance(); return true;
            case ";": addToken(TokenType.SEMICOLON, char); advance(); return true;
            case ".": addToken(TokenType.DOT, char); advance(); return true;
        }
        
        return false;
    }
    
    private function getKeywordType(word:String):TokenType {
        return switch (word) {
            case "def": TokenType.DEF;
            case "if": TokenType.IF;
            case "else": TokenType.ELSE;
            case "elif": TokenType.ELIF;
            case "while": TokenType.WHILE;
            case "for": TokenType.FOR;
            case "in": TokenType.IN;
            case "return": TokenType.RETURN;
            case "break": TokenType.BREAK;
            case "continue": TokenType.CONTINUE;
            case "pass": TokenType.PASS;
            case "True": TokenType.TRUE;
            case "False": TokenType.FALSE;
            case "None": TokenType.NONE;
            case "and": TokenType.AND;
            case "or": TokenType.OR;
            case "not": TokenType.NOT;
            case "is": TokenType.IS;
            case "class": TokenType.CLASS;
            case "import": TokenType.IMPORT;
            case "from": TokenType.FROM;
            case "as": TokenType.AS;
            case "try": TokenType.TRY;
            case "except": TokenType.EXCEPT;
            case "finally": TokenType.FINALLY;
            case "raise": TokenType.RAISE;
            case "with": TokenType.WITH;
            case "lambda": TokenType.LAMBDA;
            case "global": TokenType.GLOBAL;
            case "nonlocal": TokenType.NONLOCAL;
            default: null;
        }
    }
    
    private function addToken(type:TokenType, value:Dynamic):Void {
        tokens.push(new Token(type, value, line, column));
    }
    
    private function advance():String {
        if (position >= source.length) return "";
        var char = source.charAt(position);
        position++;
        column++;
        return char;
    }
    
    private function isDigit(char:String):Bool {
        return char >= "0" && char <= "9";
    }
    
    private function isAlpha(char:String):Bool {
        return (char >= "a" && char <= "z") || (char >= "A" && char <= "Z");
    }
    
    private function isAlphaNumeric(char:String):Bool {
        return isAlpha(char) || isDigit(char);
    }
}