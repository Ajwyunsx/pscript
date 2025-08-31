package pyscript;

import pyscript.Token.TokenType;
import pyscript.ASTNode.NodeType;

class Parser {
    private var tokens:Array<Token>;
    private var current:Int;
    
    public function new(tokens:Array<Token>) {
        this.tokens = tokens;
        this.current = 0;
    }
    
    public function parse():ASTNode {
        var statements = [];
        
        while (!isAtEnd()) {
            if (match(TokenType.NEWLINE)) {
                continue;
            }
            
            var stmt = statement();
            if (stmt != null) {
                statements.push(stmt);
            }
        }
        
        return new ASTNode(NodeType.Program, statements);
    }
    
    private function statement():ASTNode {
        if (match(TokenType.DEF)) {
            return functionStatement();
        }
        if (match(TokenType.CLASS)) {
            return classStatement();
        }
        if (match(TokenType.RETURN)) {
            return returnStatement();
        }
        if (match(TokenType.GLOBAL)) {
            return globalStatement();
        }
        if (match(TokenType.IMPORT)) {
            return importStatement();
        }
        if (match(TokenType.FROM)) {
            return fromImportStatement();
        }
        if (match(TokenType.IF)) {
            return ifStatement();
        }
        if (match(TokenType.FOR)) {
            return forStatement();
        }
        if (match(TokenType.WHILE)) {
            return whileStatement();
        }
        
        return expressionStatement();
    }
    
    
    private function classStatement():ASTNode {
        var name = consume(TokenType.IDENTIFIER, "Expected class name").value;
        
        // 可选的父类
        var superclass = null;
        if (match(TokenType.LPAREN)) {
            superclass = consume(TokenType.IDENTIFIER, "Expected superclass name").value;
            consume(TokenType.RPAREN, "Expected ')' after superclass");
        }
        
        consume(TokenType.COLON, "Expected ':' after class declaration");
        
        // 跳过换行符
        while (match(TokenType.NEWLINE)) {}
        
        // 解析类体 - 解析多个语句
        var statements = [];
        
        // 简单的方法：继续解析def语句直到不是def为止
        while (check(TokenType.DEF)) {
            var stmt = statement();
            if (stmt != null) {
                statements.push(stmt);
            }
            // 跳过换行符
            while (match(TokenType.NEWLINE)) {}
        }
        
        // 创建类体块
        var body = new ASTNode(NodeType.Block);
        body.statements = statements;
        
        var node = new ASTNode(NodeType.ClassDef);
        node.name = name;
        node.superclass = superclass;
        node.body = body;
        
        return node;
    }
    
    private function functionStatement():ASTNode {
        var name = consume(TokenType.IDENTIFIER, "Expected function name").value;
        
        consume(TokenType.LPAREN, "Expected '(' after function name");
        
        var parameters = [];
        if (!check(TokenType.RPAREN)) {
            do {
                var param = consume(TokenType.IDENTIFIER, "Expected parameter name").value;
                parameters.push(param);
            } while (match(TokenType.COMMA));
        }
        
        consume(TokenType.RPAREN, "Expected ')' after parameters");
        consume(TokenType.COLON, "Expected ':' after function signature");
        
        // 跳过换行符
        while (match(TokenType.NEWLINE)) {}
        
        // 解析函数体 - 支持多个语句
        var statements = [];
        
        // 继续解析语句直到遇到下一个def、class或文件结束
        while (!isAtEnd() && !check(TokenType.DEF) && !check(TokenType.CLASS)) {
            // 跳过空行
            if (match(TokenType.NEWLINE)) {
                continue;
            }
            
            var stmt = statement();
            if (stmt != null) {
                statements.push(stmt);
            }
            
            // 如果下一个token是同级别的def或class，停止解析
            if (check(TokenType.DEF) || check(TokenType.CLASS)) {
                break;
            }
        }
        
        // 创建函数体块
        var body = new ASTNode(NodeType.Block);
        body.statements = statements;
        
        var node = new ASTNode(NodeType.FunctionDef);
        node.name = name;
        node.parameters = parameters;
        node.body = body;
        
        return node;
    }
    
    private function returnStatement():ASTNode {
        var value = null;
        if (!check(TokenType.NEWLINE) && !isAtEnd()) {
            value = expression();
        }
        
        var node = new ASTNode(NodeType.ReturnStatement);
        node.value = value;
        
        return node;
    }
    
    private function globalStatement():ASTNode {
        var names = [];
        do {
            var name = consume(TokenType.IDENTIFIER, "Expected variable name after 'global'").value;
            names.push(name);
        } while (match(TokenType.COMMA));
        
        var node = new ASTNode(NodeType.GlobalStatement);
        node.names = names;
        
        return node;
    }
    
    private function importStatement():ASTNode {
        // 解析模块名，支持点号分隔的路径（如 haxe.Math）
        var module = consume(TokenType.IDENTIFIER, "Expected module name after 'import'").value;
        
        // 继续解析点号分隔的路径
        while (match(TokenType.DOT)) {
            var nextPart = consume(TokenType.IDENTIFIER, "Expected identifier after '.'").value;
            module += "." + nextPart;
        }
        
        var alias = null;
        if (match(TokenType.AS)) {
            alias = consume(TokenType.IDENTIFIER, "Expected alias name after 'as'").value;
        }
        
        // 检查是否是Haxe模块
        // 1. 首字母大写的模块名（Math, Sys, String等）
        // 2. 包含点号的路径，且最后一部分首字母大写（haxe.Math, sys.FileSystem等）
        var isHaxeModule = false;
        if (module.indexOf('.', 0) >= 0) {
            // 有路径的情况，检查最后一部分
            var parts = module.split('.');
            var lastPart = parts[parts.length - 1];
            isHaxeModule = lastPart.charAt(0) >= 'A' && lastPart.charAt(0) <= 'Z';
        } else {
            // 无路径的情况，检查整个模块名
            isHaxeModule = module.charAt(0) >= 'A' && module.charAt(0) <= 'Z';
        }
        
        var node = new ASTNode(isHaxeModule ? NodeType.HaxeImportStatement : NodeType.ImportStatement);
        node.module = module;
        node.alias = alias;
        node.statements = []; // 初始化statements数组
        
        return node;
    }
    
    private function fromImportStatement():ASTNode {
        var module = consume(TokenType.IDENTIFIER, "Expected module name after 'from'").value;
        consume(TokenType.IMPORT, "Expected 'import' after module name");
        
        var importNames = [];
        var importAliases = [];
        
        do {
            var name = consume(TokenType.IDENTIFIER, "Expected import name").value;
            importNames.push(name);
            
            if (match(TokenType.AS)) {
                var alias = consume(TokenType.IDENTIFIER, "Expected alias name after 'as'").value;
                importAliases.push(alias);
            } else {
                importAliases.push(name); // 默认使用原名
            }
        } while (match(TokenType.COMMA));
        
        var node = new ASTNode(NodeType.FromImportStatement);
        node.module = module;
        node.importNames = importNames;
        node.importAliases = importAliases;
        
        return node;
    }
    
    private function expressionStatement():ASTNode {
        var expr = expression();
        
        var node = new ASTNode(NodeType.ExpressionStatement);
        node.expression = expr;
        
        return node;
    }
    
    private function expression():ASTNode {
        return assignment();
    }
    
    private function assignment():ASTNode {
        var expr = logicalOr();
        
        if (match(TokenType.ASSIGN)) {
            var value = assignment();
            
            if (expr.type == NodeType.Identifier) {
                var node = new ASTNode(NodeType.Assignment);
                node.name = expr.name;
                node.value = value;
                return node;
            } else if (expr.type == NodeType.PropertyAccess) {
                // 属性赋值：obj.attr = value
                var node = new ASTNode(NodeType.PropertyAssignment);
                node.object = expr.object;
                node.property = expr.property;
                node.value = value;
                return node;
            }
            
            throw "Invalid assignment target";
        } else if (matchAny([TokenType.PLUS_ASSIGN, TokenType.MINUS_ASSIGN, TokenType.MULTIPLY_ASSIGN, 
                           TokenType.DIVIDE_ASSIGN, TokenType.MODULO_ASSIGN])) {
            var op = previous().value;
            var value = assignment();
            
            if (expr.type == NodeType.Identifier) {
                // 将 x += y 转换为 x = x + y
                var opType = "";
                switch (op) {
                    case "+=": opType = "+";
                    case "-=": opType = "-";
                    case "*=": opType = "*";
                    case "/=": opType = "/";
                    case "%=": opType = "%";
                }
                
                // 创建二元运算节点
                var binaryOp = new ASTNode(NodeType.BinaryOp);
                var leftExpr = new ASTNode(NodeType.Identifier);
                leftExpr.name = expr.name;
                binaryOp.left = leftExpr;
                binaryOp.op = opType;
                binaryOp.right = value;
                
                // 创建赋值节点
                var node = new ASTNode(NodeType.Assignment);
                node.name = expr.name;
                node.value = binaryOp;
                return node;
            }
            
            throw "Invalid assignment target";
        }
        
        return expr;
    }
    
    private function logicalOr():ASTNode {
        var expr = logicalAnd();
        
        while (match(TokenType.OR)) {
            var op = previous().value;
            var right = logicalAnd();
            
            var node = new ASTNode(NodeType.BinaryOp);
            node.left = expr;
            node.op = op;
            node.right = right;
            expr = node;
        }
        
        return expr;
    }
    
    private function logicalAnd():ASTNode {
        var expr = equality();
        
        while (match(TokenType.AND)) {
            var op = previous().value;
            var right = equality();
            
            var node = new ASTNode(NodeType.BinaryOp);
            node.left = expr;
            node.op = op;
            node.right = right;
            expr = node;
        }
        
        return expr;
    }
    
    private function equality():ASTNode {
        var expr = comparison();
        
        while (matchAny([TokenType.EQUALS, TokenType.NOT_EQUALS])) {
            var op = previous().value;
            var right = comparison();
            
            var node = new ASTNode(NodeType.BinaryOp);
            node.left = expr;
            node.op = op;
            node.right = right;
            expr = node;
        }
        
        return expr;
    }
    
    private function comparison():ASTNode {
        var expr = term();
        
        while (matchAny([TokenType.GREATER_THAN, TokenType.GREATER_EQUAL, TokenType.LESS_THAN, TokenType.LESS_EQUAL])) {
            var op = previous().value;
            var right = term();
            
            var node = new ASTNode(NodeType.BinaryOp);
            node.left = expr;
            node.op = op;
            node.right = right;
            expr = node;
        }
        
        return expr;
    }
    
    private function term():ASTNode {
        var expr = factor();
        
        while (matchAny([TokenType.MINUS, TokenType.PLUS])) {
            var op = previous().value;
            var right = factor();
            
            var node = new ASTNode(NodeType.BinaryOp);
            node.left = expr;
            node.op = op;
            node.right = right;
            expr = node;
        }
        
        return expr;
    }
    
    private function factor():ASTNode {
        var expr = power();
        
        while (matchAny([TokenType.DIVIDE, TokenType.MULTIPLY, TokenType.MODULO, TokenType.FLOOR_DIVIDE])) {
            var op = previous().value;
            var right = power();
            
            var node = new ASTNode(NodeType.BinaryOp);
            node.left = expr;
            node.op = op;
            node.right = right;
            expr = node;
        }
        
        return expr;
    }
    
    private function power():ASTNode {
        var expr = unary();
        
        if (match(TokenType.POWER)) {
            var op = previous().value;
            var right = power(); // 右结合性
            
            var node = new ASTNode(NodeType.BinaryOp);
            node.left = expr;
            node.op = op;
            node.right = right;
            return node;
        }
        
        return expr;
    }
    
    private function unary():ASTNode {
        if (matchAny([TokenType.NOT, TokenType.MINUS, TokenType.PLUS])) {
            var op = previous().value;
            var right = unary();
            
            var node = new ASTNode(NodeType.UnaryOp);
            node.op = op;
            node.operand = right;
            
            return node;
        }
        
        return call();
    }
    
    private function call():ASTNode {
        var expr = primary();
        
        while (true) {
            if (match(TokenType.LPAREN)) {
                // 函数调用
                var arguments = [];
                
                if (!check(TokenType.RPAREN)) {
                    do {
                        arguments.push(expression());
                    } while (match(TokenType.COMMA));
                }
                
                consume(TokenType.RPAREN, "Expected ')' after arguments");
                
                var node = new ASTNode(NodeType.FunctionCall);
                if (expr.type == NodeType.PropertyAccess) {
                    // 如果是属性访问，则是方法调用
                    node.object = expr.object;
                    node.name = expr.property;
                } else {
                    node.name = expr.name;
                }
                node.arguments = arguments;
                expr = node;
            } else if (match(TokenType.DOT)) {
                // 属性访问
                var property = consume(TokenType.IDENTIFIER, "Expected property name after '.'").value;
                var node = new ASTNode(NodeType.PropertyAccess);
                node.object = expr;
                node.property = property;
                expr = node;
            } else if (match(TokenType.LBRACKET)) {
                // 索引访问
                var index = expression();
                consume(TokenType.RBRACKET, "Expected ']' after index");
                var node = new ASTNode(NodeType.IndexAccess);
                node.object = expr;
                node.index = index;
                expr = node;
            } else {
                break;
            }
        }
        
        return expr;
    }
    
    private function primary():ASTNode {
        if (match(TokenType.TRUE)) {
            return new ASTNode(NodeType.Literal, true);
        }
        
        if (match(TokenType.FALSE)) {
            return new ASTNode(NodeType.Literal, false);
        }
        
        if (match(TokenType.NONE)) {
            return new ASTNode(NodeType.Literal, null);
        }
        
        if (match(TokenType.INT)) {
            return new ASTNode(NodeType.Literal, previous().value);
        }
        
        if (match(TokenType.FLOAT)) {
            return new ASTNode(NodeType.Literal, previous().value);
        }
        
        if (match(TokenType.STRING)) {
            return new ASTNode(NodeType.Literal, previous().value);
        }
        
        if (match(TokenType.IDENTIFIER)) {
            var node = new ASTNode(NodeType.Identifier);
            node.name = previous().value;
            return node;
        }
        
        if (match(TokenType.LPAREN)) {
            var expr = expression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return expr;
        }
        
        if (match(TokenType.LBRACE)) {
            return parseDictLiteral();
        }
        
        if (match(TokenType.LBRACKET)) {
            return parseListLiteral();
        }
        
        throw "Unexpected token: " + peek().type;
    }
    
    private function match(type:TokenType):Bool {
        if (check(type)) {
            advance();
            return true;
        }
        return false;
    }
    
    private function matchAny(types:Array<TokenType>):Bool {
        for (type in types) {
            if (check(type)) {
                advance();
                return true;
            }
        }
        return false;
    }
    
    private function check(type:TokenType):Bool {
        if (isAtEnd()) return false;
        return peek().type == type;
    }
    
    private function advance():Token {
        if (!isAtEnd()) current++;
        return previous();
    }
    
    private function isAtEnd():Bool {
        return peek().type == TokenType.EOF;
    }
    
    private function peek():Token {
        return tokens[current];
    }
    
    private function previous():Token {
        return tokens[current - 1];
    }
    
    private function consume(type:TokenType, message:String):Token {
        if (check(type)) return advance();
        
        throw message + " at " + peek().type + " '" + peek().value + "'";
    }
    
    private function ifStatement():ASTNode {
        var condition = expression();
        consume(TokenType.COLON, "Expected ':' after if condition");
        
        // 跳过换行符
        while (match(TokenType.NEWLINE)) {}
        
        var thenBranch = statement();
        
        // 跳过换行符，检查是否有elif或else
        while (match(TokenType.NEWLINE)) {}
        
        var elseBranch = null;
        
        // 处理elif链
        if (match(TokenType.ELIF)) {
            // elif被当作嵌套的if-else处理
            elseBranch = ifStatement(); // 递归处理elif
        } else if (match(TokenType.ELSE)) {
            consume(TokenType.COLON, "Expected ':' after else");
            while (match(TokenType.NEWLINE)) {}
            elseBranch = statement();
        }
        
        var node = new ASTNode(NodeType.IfStatement);
        node.condition = condition;
        node.thenBranch = thenBranch;
        node.elseBranch = elseBranch;
        return node;
    }
    
    private function forStatement():ASTNode {
        // for variable in iterable:
        var variable = consume(TokenType.IDENTIFIER, "Expected variable name in for loop").value;
        consume(TokenType.IN, "Expected 'in' after for variable");
        var iterable = expression();
        consume(TokenType.COLON, "Expected ':' after for clause");
        
        // 跳过换行符
        while (match(TokenType.NEWLINE)) {}
        
        var body = statement();
        
        var node = new ASTNode(NodeType.ForLoop);
        node.variable = variable;
        node.iterable = iterable;
        node.body = body;
        
        return node;
    }
    
    private function whileStatement():ASTNode {
        var condition = expression();
        consume(TokenType.COLON, "Expected ':' after while condition");
        
        // 跳过换行符
        while (match(TokenType.NEWLINE)) {}
        
        var body = statement();
        
        var node = new ASTNode(NodeType.WhileLoop);
        node.condition = condition;
        node.body = body;
        
        return node;
    }
    
    private function parseDictLiteral():ASTNode {
        var node = new ASTNode(NodeType.DictLiteral);
        node.elements = [];
        
        // 跳过换行符
        while (match(TokenType.NEWLINE)) {}
        
        if (!check(TokenType.RBRACE)) {
            do {
                // 跳过换行符
                while (match(TokenType.NEWLINE)) {}
                
                var key = expression();
                consume(TokenType.COLON, "Expected ':' after dictionary key");
                var value = expression();
                
                var pair = new ASTNode(NodeType.KeyValue);
                pair.key = key;
                pair.value = value;
                node.elements.push(pair);
                
                // 跳过换行符
                while (match(TokenType.NEWLINE)) {}
            } while (match(TokenType.COMMA));
        }
        
        // 跳过换行符
        while (match(TokenType.NEWLINE)) {}
        consume(TokenType.RBRACE, "Expected '}' after dictionary");
        return node;
    }
    
    private function parseListLiteral():ASTNode {
        var node = new ASTNode(NodeType.ListLiteral);
        node.elements = [];
        
        // 跳过换行符
        while (match(TokenType.NEWLINE)) {}
        
        if (!check(TokenType.RBRACKET)) {
            do {
                // 跳过换行符
                while (match(TokenType.NEWLINE)) {}
                
                node.elements.push(expression());
                
                // 跳过换行符
                while (match(TokenType.NEWLINE)) {}
            } while (match(TokenType.COMMA));
        }
        
        // 跳过换行符
        while (match(TokenType.NEWLINE)) {}
        consume(TokenType.RBRACKET, "Expected ']' after list");
        return node;
    }
}
