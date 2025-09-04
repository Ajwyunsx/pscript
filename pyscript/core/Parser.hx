package pyscript.core;

import pyscript.utils.Token;
import pyscript.utils.TokenType;
import pyscript.ast.ASTNode;
import pyscript.ast.NodeType;

/**
 * Python语法分析器
 * 将Token序列转换为AST
 */
class Parser {
    // Token序列和当前位置
    private var tokens:Array<Token>;
    private var current:Int;
    
    // 解析状态
    private var panicMode:Bool;
    private var hadError:Bool;
    private var functionDepth:Int;
    private var classDepth:Int;
    private var loopDepth:Int;
    
    /**
     * 构造函数
     */
    public function new() {
        reset();
    }
    
    /**
     * 重置解析器状态
     */
    public function reset():Void {
        tokens = [];
        current = 0;
        panicMode = false;
        hadError = false;
        functionDepth = 0;
        classDepth = 0;
        loopDepth = 0;
    }
    
    /**
     * 设置Token序列
     * @param tokens Token序列
     */
    public function setTokens(tokens:Array<Token>):Void {
        reset();
        this.tokens = tokens;
    }
    
    /**
     * 执行语法分析
     * @return AST根节点
     */
    public function parse():ASTNode {
        try {
            var statements = new Array<ASTNode>();
            
            
            while (!isAtEnd()) {
                
                var stmt = declaration();
                if (stmt != null) {
                    statements.push(stmt);
                    
                } else {
                    
                }
            }
            
            var node = createASTNode(NodeType.Program);
            node.body = statements;
            return node;
            
        } catch (e:String) {
            error(e);
            return null;
        } catch (e:Dynamic) {
            return null;
        }
    }
    
    /**
     * Create AST node with line number information
     * @param type Node type
     * @return AST node with line number set
     */
    private function createASTNode(type:NodeType):ASTNode {
        var node = new ASTNode(type);
        // Set line number from current token
        if (!isAtEnd()) {
            var token = peek();
            node.startLine = token.line;
            node.startColumn = token.column;
        }
        return node;
    }
    
    /**
     * 解析声明
     * @return 声明节点
     */
    private function declaration():ASTNode {
        try {
            // 跳过空行（只有换行符的行）
            while (match(TokenType.NEWLINE)) {}
            
            if (isAtEnd()) return null;
            
            if (match(TokenType.CLASS)) return classDeclaration();
            if (match(TokenType.DEF)) return functionDeclaration();
            if (match(TokenType.AT)) return decoratedDeclaration();
            if (match(TokenType.IMPORT)) return importDeclaration();
            if (match(TokenType.FROM)) return fromImportDeclaration();
            
            return statement();
        } catch (e:String) {
            synchronize();
            return null;
        } catch (e:Dynamic) {
            synchronize();
            return null;
        }
    }
    
    /**
     * 解析装饰器声明
     * @return 装饰器声明节点
     */
    private function decoratedDeclaration():ASTNode {
        var decorators = new Array<ASTNode>();
        
        // 解析所有装饰器
        do {
            var decorator = createASTNode(NodeType.Decorator);
            decorator.expression = expression();
            decorators.push(decorator);
            
            // 消耗换行
            while (match(TokenType.NEWLINE)) {}
        } while (match(TokenType.AT));
        
        // 解析被装饰的声明
        var declaration:ASTNode;
        if (match(TokenType.DEF)) {
            declaration = functionDeclaration();
        } else if (match(TokenType.CLASS)) {
            declaration = classDeclaration();
        } else {
            error("Decorator must be followed by function or class definition");
            return null;
        }
        
        // 将装饰器添加到声明
        declaration.decorators = decorators;
        
        return declaration;
    }
    
    /**
     * 解析类声明
     * @return 类声明节点
     */
    private function classDeclaration():ASTNode {
        var node = createASTNode(NodeType.ClassDef);
        
        // 类名
        node.name = consume(TokenType.IDENTIFIER, "Expected class name").value;
        
        // 继承列表
        if (match(TokenType.LPAREN)) {
            node.bases = new Array<ASTNode>();
            if (!check(TokenType.RPAREN)) {
                do {
                    node.bases.push(expression());
                } while (match(TokenType.COMMA));
            }
            consume(TokenType.RPAREN, "Expected ')' after base classes");
        }
        
        // 类体
        consume(TokenType.COLON, "Expected ':' before class body");
        classDepth++;
        node.body = parseBody();
        classDepth--;
        
        return node;
    }
    
    /**
     * 解析函数声明
     * @return 函数声明节点
     */
    private function functionDeclaration():ASTNode {
        var node = createASTNode(NodeType.FunctionDef);
        
        // 函数名
        node.name = consume(TokenType.IDENTIFIER, "Expected function name").value;
        
        // 参数列表
        consume(TokenType.LPAREN, "Expected '(' after function name");
        node.parameters = parseParameters();
        consume(TokenType.RPAREN, "Expected ')' after parameters");
        
        // 返回值标注
        if (match(TokenType.ARROW)) {
            node.returns = expression();
        }
        
        // 函数体
        consume(TokenType.COLON, "Expected ':' before function body");
        functionDepth++;
        node.body = parseBody();
        functionDepth--;
        
        return node;
    }
    
    /**
     * 解析import声明
     * @return import声明节点
     */
    private function importDeclaration():ASTNode {
        var node = createASTNode(NodeType.ImportStatement);
        node.names = new Array<{name:String, asname:String}>();
        
        do {
            var name = consumeDottedName();
            var asname = null;
            
            if (match(TokenType.AS)) {
                asname = consume(TokenType.IDENTIFIER, "Expected name after 'as'").value;
            }
            
            node.names.push({name: name, asname: asname});
        } while (match(TokenType.COMMA));
        
        return node;
    }
    
    /**
     * 解析from-import声明
     * @return from-import声明节点
     */
    private function fromImportDeclaration():ASTNode {
        var node = createASTNode(NodeType.FromImport);
        
        // 相对导入级别
        node.level = 0;
        while (match(TokenType.DOT)) {
            node.level++;
        }
        
        // 模块路径
        node.module = consumeDottedName();
        
        consume(TokenType.IMPORT, "Expected 'import' in from-import statement");
        
        // 导入项
        if (match(TokenType.MULTIPLY)) {
            // from mod import *
            node.names = [{name: "*", asname: null}];
        } else {
            // from mod import name1 [as alias1], name2 [as alias2]
            node.names = new Array<{name:String, asname:String}>();
            
            do {
                var name = consume(TokenType.IDENTIFIER, "Expected name to import").value;
                var asname = null;
                
                if (match(TokenType.AS)) {
                    asname = consume(TokenType.IDENTIFIER, "Expected name after 'as'").value;
                }
                
                node.names.push({name: name, asname: asname});
            } while (match(TokenType.COMMA));
        }
        
        return node;
    }
    
    /**
     * 解析语句
     * @return 语句节点
     */
    private function statement():ASTNode {
        if (match(TokenType.IF)) return ifStatement();
        if (match(TokenType.WHILE)) return whileStatement();
        if (match(TokenType.FOR)) return forStatement();
        if (match(TokenType.RETURN)) return returnStatement();
        if (match(TokenType.BREAK)) return breakStatement();
        if (match(TokenType.CONTINUE)) return continueStatement();
        if (match(TokenType.PASS)) return passStatement();
        if (match(TokenType.RAISE)) return raiseStatement();
        if (match(TokenType.TRY)) return tryStatement();
        if (match(TokenType.WITH)) return withStatement();
        if (match(TokenType.ASSERT)) return assertStatement();
        if (match(TokenType.GLOBAL)) return globalStatement();
        if (match(TokenType.NONLOCAL)) return nonlocalStatement();
        
        return expressionStatement();
    }
    
    /**
     * 解析if语句
     * @return if语句节点
     */
    private function ifStatement():ASTNode {
        var node = createASTNode(NodeType.IfStatement);
        
        // if条件
        node.test = expression();
        consume(TokenType.COLON, "Expected ':' after if condition");
        
        // 特殊处理if语句的body，以支持elif和else
        node.body = parseIfBody();
        
        // elif分支
        node.elifBranches = new Array<ASTNode>();
        
        // 消耗NEWLINE token以到达ELIF
        consumeNewline();
        
        while (match(TokenType.ELIF)) {
            var elifNode = createASTNode(NodeType.ElifBranch);
            elifNode.test = expression();
            consume(TokenType.COLON, "Expected ':' after elif condition");
            elifNode.body = parseIfBody();
            node.elifBranches.push(elifNode);
        }
        
        // else分支
        if (match(TokenType.ELSE)) {
            consume(TokenType.COLON, "Expected ':' after else");
            node.orelse = wrapInBlock(parseIfBody());
        }
        
        return node;
    }
    
    /**
     * 解析if/elif/else语句的body，只解析到下一个elif/else或dedent
     * @return 语句列表
     */
    private function parseIfBody():Array<ASTNode> {
        var statements = new Array<ASTNode>();
        
        // 跳过块开始的换行
        consumeNewline();
        
        // 必须以缩进开始
        consume(TokenType.INDENT, "Expected indented block");
        
        // 解析语句直到遇到反缩进、elif或else
        while (!isAtEnd() && !check(TokenType.DEDENT)) {
            // 检查是否遇到了elif或else（它们应该与if在同一级别）
            if (check(TokenType.ELIF) || check(TokenType.ELSE)) {
                break;
            }
            
            try {
                var stmt = declaration();
                if (stmt != null) {
                    statements.push(stmt);
                }
            } catch (e:String) {
                synchronize();
            }
        }
        
        // 消耗DEDENT（如果存在）
        if (check(TokenType.DEDENT)) {
            advance();
        }
        
        return statements;
    }
    
    /**
     * 解析while语句
     * @return while语句节点
     */
    private function whileStatement():ASTNode {
        var node = createASTNode(NodeType.WhileStatement);
        
        // while条件
        node.test = expression();
        consume(TokenType.COLON, "Expected ':' after while condition");
        
        // 循环体
        loopDepth++;
        node.body = parseBody();
        loopDepth--;
        
        // else子句
        if (match(TokenType.ELSE)) {
            consume(TokenType.COLON, "Expected ':' after else");
            node.orelse = wrapInBlock(parseBody());
        }
        
        return node;
    }
    
    /**
     * 解析for语句
     * @return for语句节点
     */
    private function forStatement():ASTNode {
        var node = createASTNode(NodeType.ForStatement);
        
        // for目标
        node.target = expression();
        consume(TokenType.IN, "Expected 'in' after for target");
        
        // 迭代对象
        node.iter = expression();
        consume(TokenType.COLON, "Expected ':' after for clause");
        
        // 循环体
        loopDepth++;
        node.body = parseBody();
        loopDepth--;
        
        // else子句
        if (match(TokenType.ELSE)) {
            consume(TokenType.COLON, "Expected ':' after else");
            node.orelse = wrapInBlock(parseBody());
        }
        
        return node;
    }
    
    /**
     * 解析try语句
     * @return try语句节点
     */
    private function tryStatement():ASTNode {
        var node = createASTNode(NodeType.TryStatement);
        
        // try块
        consume(TokenType.COLON, "Expected ':' after try");
        node.body = parseBody();
        
        // except处理器
        node.handlers = new Array<ASTNode>();
        
        // 消耗NEWLINE token（如果有）
        consumeNewline();
        
        while (match(TokenType.EXCEPT)) {
            var handler = createASTNode(NodeType.ExceptHandler);
            
            // 异常类型
            if (!check(TokenType.COLON)) {
                handler.exctype = expression();
                
                // as子句
                if (match(TokenType.AS)) {
                    var excNode = createASTNode(NodeType.Identifier);
                    excNode.name = consume(TokenType.IDENTIFIER, "Expected name after 'as'").value;
                    handler.exc = excNode;
                }
            }
            
            consume(TokenType.COLON, "Expected ':' after except clause");
            handler.body = parseBody();
            node.handlers.push(handler);
        }
        
        // else子句
        if (match(TokenType.ELSE)) {
            consume(TokenType.COLON, "Expected ':' after else");
            node.orelse = wrapInBlock(parseBody());
        }
        
        // finally子句
        if (match(TokenType.FINALLY)) {
            consume(TokenType.COLON, "Expected ':' after finally");
            node.finalbody = wrapInBlock(parseBody());
        }
        
        return node;
    }
    
    /**
     * 解析with语句
     * @return with语句节点
     */
    private function withStatement():ASTNode {
        var node = createASTNode(NodeType.WithStatement);
        node.items = new Array<{context_expr:ASTNode, optional_vars:ASTNode}>();
        
        // with项
        do {
            var item = createASTNode(NodeType.WithItem);
            item.contextExpr = expression();
            
            if (match(TokenType.AS)) {
                item.optionalVars = expression();
            }
            
            node.items.push({context_expr: item.contextExpr, optional_vars: item.optionalVars});
        } while (match(TokenType.COMMA));
        
        // with体
        consume(TokenType.COLON, "Expected ':' after with clause");
        node.body = parseBody();
        
        return node;
    }
    
    /**
     * 解析return语句
     * @return return语句节点
     */
    private function returnStatement():ASTNode {
        if (functionDepth == 0) {
            error("'return' outside function");
        }
        
        var node = createASTNode(NodeType.ReturnStatement);
        
        // return值(可选)
        if (!check(TokenType.NEWLINE)) {
            node.value = expression();
        }
        
        return node;
    }
    
    /**
     * 解析break语句
     * @return break语句节点
     */
    private function breakStatement():ASTNode {
        if (loopDepth == 0) {
            error("'break' outside loop");
        }
        return createASTNode(NodeType.BreakStatement);
    }
    
    /**
     * 解析continue语句
     * @return continue语句节点
     */
    private function continueStatement():ASTNode {
        if (loopDepth == 0) {
            error("'continue' outside loop");
        }
        return createASTNode(NodeType.ContinueStatement);
    }
    
    /**
     * 解析pass语句
     * @return pass语句节点
     */
    private function passStatement():ASTNode {
        return createASTNode(NodeType.PassStatement);
    }
    
    /**
     * 解析raise语句
     * @return raise语句节点
     */
    private function raiseStatement():ASTNode {
        var node = createASTNode(NodeType.RaiseStatement);
        
        // 异常实例(可选)
        if (!check(TokenType.NEWLINE)) {
            node.exc = expression();
            
            // from子句
            if (match(TokenType.FROM)) {
                node.cause = expression();
            }
        }
        
        return node;
    }
    
    /**
     * 解析assert语句
     * @return assert语句节点
     */
    private function assertStatement():ASTNode {
        var node = createASTNode(NodeType.AssertStatement);
        
        node.test = expression();
        
        if (match(TokenType.COMMA)) {
            node.msg = expression();
        }
        
        return node;
    }
    
    /**
     * 解析global语句
     * @return global语句节点
     */
    private function globalStatement():ASTNode {
        var node = createASTNode(NodeType.GlobalStatement);
        node.identifierNames = new Array<String>();
        
        do {
            node.identifierNames.push(consume(TokenType.IDENTIFIER, "Expected name in global statement").value);
        } while (match(TokenType.COMMA));
        
        return node;
    }
    
    /**
     * 解析nonlocal语句
     * @return nonlocal语句节点
     */
    private function nonlocalStatement():ASTNode {
        if (functionDepth == 0) {
            error("'nonlocal' outside function");
        }
        
        var node = createASTNode(NodeType.NonlocalStatement);
        node.identifierNames = new Array<String>();
        
        do {
            node.identifierNames.push(consume(TokenType.IDENTIFIER, "Expected name in nonlocal statement").value);
        } while (match(TokenType.COMMA));
        
        return node;
    }
    
    /**
     * 解析表达式语句
     * @return 表达式语句节点
     */
    private function expressionStatement():ASTNode {
        var node = createASTNode(NodeType.ExpressionStatement);
        node.expression = expression();
        
        // 消耗语句末尾的换行符
        while (match(TokenType.NEWLINE)) {}
        
        return node;
    }
    
    /**
     * 解析表达式
     * @return 表达式节点
     */
    private function expression():ASTNode {
        return assignment();
    }
    
    /**
     * 解析赋值表达式
     * @return 赋值表达式节点
     */
    private function assignment():ASTNode {
        var expr = logicalOr();
        
        // 检查各种赋值操作符
        var assignOp:TokenType = null;
        if (match(TokenType.ASSIGN)) assignOp = TokenType.ASSIGN;
        else if (match(TokenType.PLUS_ASSIGN)) assignOp = TokenType.PLUS_ASSIGN;
        else if (match(TokenType.MINUS_ASSIGN)) assignOp = TokenType.MINUS_ASSIGN;
        else if (match(TokenType.MULTIPLY_ASSIGN)) assignOp = TokenType.MULTIPLY_ASSIGN;
        else if (match(TokenType.DIVIDE_ASSIGN)) assignOp = TokenType.DIVIDE_ASSIGN;
        else if (match(TokenType.MODULO_ASSIGN)) assignOp = TokenType.MODULO_ASSIGN;
        else if (match(TokenType.POWER_ASSIGN)) assignOp = TokenType.POWER_ASSIGN;
        
        if (assignOp != null) {
            var value = assignment();
            
            if (expr.type == NodeType.Identifier) {
                var node = createASTNode(NodeType.Assignment);
                node.name = expr.name;
                node.value = value;
                // 存储操作符类型，用于Interpreter处理复合赋值
                node.op = switch(assignOp) {
                    case TokenType.PLUS_ASSIGN: "+=";
                    case TokenType.MINUS_ASSIGN: "-=";
                    case TokenType.MULTIPLY_ASSIGN: "*=";
                    case TokenType.DIVIDE_ASSIGN: "/=";
                    case TokenType.MODULO_ASSIGN: "%=";
                    case TokenType.POWER_ASSIGN: "**=";
                    default: "=";
                }
                return node;
            } else if (expr.type == NodeType.PropertyAccess) {
                var node = createASTNode(NodeType.PropertyAssignment);
                node.object = expr.object;
                node.attr = expr.attr;
                node.value = value;
                // 存储操作符类型，用于Interpreter处理复合赋值
                node.op = switch(assignOp) {
                    case TokenType.PLUS_ASSIGN: "+=";
                    case TokenType.MINUS_ASSIGN: "-=";
                    case TokenType.MULTIPLY_ASSIGN: "*=";
                    case TokenType.DIVIDE_ASSIGN: "/=";
                    case TokenType.MODULO_ASSIGN: "%=";
                    case TokenType.POWER_ASSIGN: "**=";
                    default: "=";
                }
                return node;
            } else if (expr.type == NodeType.IndexAccess) {
                var node = createASTNode(NodeType.IndexAssignment);
                node.object = expr.object;
                node.index = expr.index;
                node.value = value;
                // 存储操作符类型，用于Interpreter处理复合赋值
                node.op = switch(assignOp) {
                    case TokenType.PLUS_ASSIGN: "+=";
                    case TokenType.MINUS_ASSIGN: "-=";
                    case TokenType.MULTIPLY_ASSIGN: "*=";
                    case TokenType.DIVIDE_ASSIGN: "/=";
                    case TokenType.MODULO_ASSIGN: "%=";
                    case TokenType.POWER_ASSIGN: "**=";
                    default: "=";
                }
                return node;
            }
            
            throw "Invalid assignment target";
        }
        
        return expr;
    }
    
    /**
     * 解析逻辑OR表达式
     * @return 表达式节点
     */
    private function logicalOr():ASTNode {
        var expr = logicalAnd();
        
        while (match(TokenType.OR)) {
            var op = previous();
            var right = logicalAnd();
            var node = createASTNode(NodeType.BinaryOp);
            node.left = expr;
            node.op = op.value;
            node.right = right;
            expr = node;
        }
        
        return expr;
    }
    
    /**
     * 解析逻辑AND表达式
     * @return 表达式节点
     */
    private function logicalAnd():ASTNode {
        var expr = equality();
        
        while (match(TokenType.AND)) {
            var op = previous();
            var right = equality();
            var node = createASTNode(NodeType.BinaryOp);
            node.left = expr;
            node.op = op.value;
            node.right = right;
            expr = node;
        }
        
        return expr;
    }
    
    /**
     * 解析相等性表达式
     * @return 表达式节点
     */
    private function equality():ASTNode {
        var expr = comparison();
        
        while (match(TokenType.EQUALS) || match(TokenType.NOT_EQUALS)) {
            var op = previous();
            var right = comparison();
            var node = createASTNode(NodeType.BinaryOp);
            node.left = expr;
            node.op = op.value;
            node.right = right;
            expr = node;
        }
        
        return expr;
    }
    
    /**
     * 解析比较表达式
     * @return 表达式节点
     */
    private function comparison():ASTNode {
        var expr = addition();
        
        while (match(TokenType.GREATER) || match(TokenType.GREATER_EQUAL) ||
               match(TokenType.LESS) || match(TokenType.LESS_EQUAL) ||
               match(TokenType.EQUALS) || match(TokenType.NOT_EQUALS)) {
            var op = previous();
            var right = addition();
            var node = createASTNode(NodeType.BinaryOp);
            node.left = expr;
            node.op = op.value;
            node.right = right;
            expr = node;
        }
        
        return expr;
    }
    
    /**
     * 解析加法表达式
     * @return 表达式节点
     */
    private function addition():ASTNode {
        var expr = multiplication();
        
        while (match(TokenType.PLUS) || match(TokenType.MINUS)) {
            var op = previous();
            var right = multiplication();
            var node = createASTNode(NodeType.BinaryOp);
            node.left = expr;
            node.op = op.value;
            node.right = right;
            expr = node;
        }
        
        return expr;
    }
    
    /**
     * 解析乘法表达式
     * @return 表达式节点
     */
    private function multiplication():ASTNode {
        var expr = power();
        
        while (match(TokenType.MULTIPLY) || match(TokenType.DIVIDE) || 
               match(TokenType.FLOOR_DIVIDE) || match(TokenType.MODULO)) {
            var op = previous();
            var right = power();
            var node = createASTNode(NodeType.BinaryOp);
            node.left = expr;
            node.op = op.value;
            node.right = right;
            expr = node;
        }
        
        return expr;
    }
    
    /**
     * 解析幂运算表达式
     * @return 表达式节点
     */
    private function power():ASTNode {
        var expr = unary();
        
        while (match(TokenType.POWER)) {
            var op = previous();
            var right = unary();
            var node = createASTNode(NodeType.BinaryOp);
            node.left = expr;
            node.op = op.value;
            node.right = right;
            expr = node;
        }
        
        return expr;
    }
    
    /**
     * 解析一元表达式
     * @return 表达式节点
     */
    private function unary():ASTNode {
        if (match(TokenType.NOT) || match(TokenType.MINUS)) {
            var op = previous();
            var right = unary();
            var node = createASTNode(NodeType.UnaryOp);
            node.op = op.value;
            node.operand = right;
            return node;
        }
        
        return call();
    }
    
    /**
     * 解析函数调用和属性访问
     * @return 表达式节点
     */
    private function call():ASTNode {
        var expr = primary();
        
        while (true) {
            if (match(TokenType.LPAREN)) {
                // 函数调用
                var arguments = new Array<ASTNode>();
                
                if (!check(TokenType.RPAREN)) {
                    do {
                        arguments.push(expression());
                    } while (match(TokenType.COMMA));
                }
                
                consume(TokenType.RPAREN, "Expected ')' after arguments");
                
                var node = createASTNode(NodeType.FunctionCall);
                if (expr.type == NodeType.PropertyAccess) {
                    // 如果是属性访问，则是方法调用
                    node.object = expr.object;
                    node.name = expr.attr;
                } else {
                    node.object = expr;
                }
                node.arguments = arguments;
                expr = node;
            } else if (match(TokenType.DOT)) {
                // 属性访问
                var propertyToken = consume(TokenType.IDENTIFIER, "Expected property name after '.'");
                var node = createASTNode(NodeType.PropertyAccess);
                node.object = expr;
                node.attr = propertyToken.value;
                expr = node;
            } else if (match(TokenType.LBRACKET)) {
                // 索引访问或切片
                // 检查是否是切片（包含冒号）
                var isSlice = false;
                var savePos = current;
                
                // 尝试解析表达式，然后看是否有冒号
                if (!check(TokenType.RBRACKET)) {
                    if (check(TokenType.COLON)) {
                        isSlice = true;
                    } else {
                        // 消耗一个表达式
                        expression();
                        if (match(TokenType.COLON)) {
                            isSlice = true;
                        }
                    }
                }
                
                // 回退位置
                current = savePos;
                
                if (isSlice) {
                    // 这是切片
                    var sliceNode = parseSlice();
                    sliceNode.object = expr;
                    expr = sliceNode;
                } else {
                    // 这是普通索引
                    var index = expression();
                    consume(TokenType.RBRACKET, "Expected ']' after index");
                    var node = createASTNode(NodeType.IndexAccess);
                    node.object = expr;
                    node.index = index;
                    expr = node;
                }
            } else {
                break;
            }
        }
        
        return expr;
    }
    
    /**
     * 解析基本表达式
     * @return 表达式节点
     */
    private function primary():ASTNode {
        if (match(TokenType.TRUE)) {
            var node = createASTNode(NodeType.Literal);
            node.value = true;
            return node;
        }
        
        if (match(TokenType.FALSE)) {
            var node = createASTNode(NodeType.Literal);
            node.value = false;
            return node;
        }
        
        if (match(TokenType.NONE)) {
            var node = createASTNode(NodeType.Literal);
            node.value = null;
            return node;
        }
        
        if (match(TokenType.INT) || match(TokenType.FLOAT)) {
            var node = createASTNode(NodeType.Literal);
            node.value = previous().value;
            return node;
        }
        
        if (match(TokenType.STRING)) {
            var node = createASTNode(NodeType.Literal);
            node.value = previous().value;
            return node;
        }
        
        if (match(TokenType.IDENTIFIER)) {
            var node = createASTNode(NodeType.Identifier);
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
    
    /**
     * 解析字典字面量
     * @return 字典字面量节点
     */
    private function parseDictLiteral():ASTNode {
        var node = createASTNode(NodeType.DictLiteral);
        node.keys = new Array<ASTNode>();
        node.values = new Array<ASTNode>();
        
        if (!check(TokenType.RBRACE)) {
            do {
                var key = parseDictKey();
                consume(TokenType.COLON, "Expected ':' after dictionary key");
                var value = expression();
                node.keys.push(key);
                node.values.push(value);
            } while (match(TokenType.COMMA));
        }
        
        consume(TokenType.RBRACE, "Expected '}' after dictionary");
        return node;
    }
    
    /**
     * 解析字典键
     * @return 键节点
     */
    private function parseDictKey():ASTNode {
        // 检查是否是标识符（不带引号的键）
        if (match(TokenType.IDENTIFIER)) {
            var identifier = previous();
            var node = createASTNode(NodeType.Literal);
            node.value = identifier.value;
            return node;
        }
        
        // 否则按普通表达式解析
        return expression();
    }
    
    /**
     * 解析列表字面量
     * @return 列表字面量节点
     */
    private function parseListLiteral():ASTNode {
        var node = createASTNode(NodeType.ListLiteral);
        node.elements = new Array<ASTNode>();
        
        if (!check(TokenType.RBRACKET)) {
            do {
                node.elements.push(expression());
            } while (match(TokenType.COMMA));
        }
        
        consume(TokenType.RBRACKET, "Expected ']' after list");
        return node;
    }
    
    /**
     * 解析参数列表
     * @return 参数列表
     */
    private function parseParameters():Array<ASTNode> {
        var params = new Array<ASTNode>();
        
        if (!check(TokenType.RPAREN)) {
            do {
                var param = createASTNode(NodeType.Parameter);
                
                // 处理 *args
                if (match(TokenType.MULTIPLY)) {
                    param.type = NodeType.VarArgsParameter;
                    param.name = consume(TokenType.IDENTIFIER, "Expected parameter name after '*'").value;
                }
                // 处理 **kwargs
                else if (match(TokenType.POWER)) {
                    param.type = NodeType.KwargsParameter;
                    param.name = consume(TokenType.IDENTIFIER, "Expected parameter name after '**'").value;
                }
                // 普通参数
                else {
                    param.name = consume(TokenType.IDENTIFIER, "Expected parameter name").value;
                    
                    // 类型标注
                    if (match(TokenType.COLON)) {
                        param.annotation = expression();
                    }
                    
                    // 默认值
                    if (match(TokenType.ASSIGN)) {
                        param.defaultValue = expression();
                    }
                }
                
                params.push(param);
            } while (match(TokenType.COMMA));
        }
        
        return params;
    }
    
    /**
     * 解析代码块
     * @return 代码块的语句列表
     */
    private function parseBody():Array<ASTNode> {
        var statements = new Array<ASTNode>();
        
        // 跳过块开始的换行
        consumeNewline();
        
        // 必须以缩进开始
        consume(TokenType.INDENT, "Expected indented block");
        
        // 解析语句直到遇到反缩进
        while (!isAtEnd() && !check(TokenType.DEDENT)) {
            try {
                var stmt = declaration();
                if (stmt != null) {
                    statements.push(stmt);
                }
            } catch (e:String) {
                synchronize();
            }
        }
        
        // 必须以反缩进结束
        consume(TokenType.DEDENT, "Expected dedent after block");
        
        return statements;
    }
    
    /**
     * 将语句数组包装为块节点
     * @param statements 语句数组
     * @return 块节点
     */
    private function wrapInBlock(statements:Array<ASTNode>):ASTNode {
        var block = createASTNode(NodeType.Block);
        block.statements = statements;
        return block;
    }
    
    /**
     * 消耗点号分隔的标识符
     * @return 标识符文本
     */
    private function consumeDottedName():String {
        var parts = new Array<String>();
        
        do {
            parts.push(consume(TokenType.IDENTIFIER, "Expected name").value);
        } while (match(TokenType.DOT));
        
        return parts.join(".");
    }
    
    /**
     * 消耗换行Token
     */
    private function consumeNewline():Void {
        while (match(TokenType.NEWLINE)) {}
    }
    
    /**
     * 错误处理: 标记错误
     * @param message 错误消息
     */
    private function error(message:String):Void {
        if (panicMode) return;
        
        hadError = true;
        panicMode = true;
        
        var token = peek();
        throw 'Error at line ${token.line}, column ${token.column}: ${message}';
    }
    
    /**
     * 错误恢复: 同步到下一个语句开始
     */
    private function synchronize():Void {
        panicMode = false;
        
        while (!isAtEnd()) {
            // 在类体或函数体内，不能只在NEWLINE处停止
            if (previous().type == TokenType.NEWLINE) {
                // 检查下一个token是否是声明开始
                switch (peek().type) {
                    case TokenType.CLASS, TokenType.DEF,
                         TokenType.FOR, TokenType.IF, TokenType.WHILE,
                         TokenType.RETURN, TokenType.IMPORT, TokenType.FROM:
                        return;
                    default:
                        // 继续跳过
                        advance();
                        continue;
                }
            }
            
            switch (peek().type) {
                case TokenType.CLASS, TokenType.DEF,
                     TokenType.FOR, TokenType.IF, TokenType.WHILE,
                     TokenType.RETURN, TokenType.IMPORT, TokenType.FROM:
                    return;
                    
                default:
                    advance();
            }
        }
    }
    
    /**
     * 工具方法: 检查当前Token是否匹配期望类型
     */
    private function check(type:TokenType):Bool {
        if (isAtEnd()) return false;
        return peek().type == type;
    }
    
    /**
     * 工具方法: 匹配并消耗期望类型的Token
     */
    private function match(type:TokenType):Bool {
        if (check(type)) {
            advance();
            return true;
        }
        return false;
    }
    
    /**
     * 工具方法: 前进到下一个Token
     * @return 前一个Token
     */
    private function advance():Token {
        if (!isAtEnd()) current++;
        return previous();
    }
    
    /**
     * 工具方法: 获取当前Token
     * @return 当前Token
     */
    private function peek():Token {
        if (tokens == null || tokens.length == 0 || current >= tokens.length) {
            return new Token(TokenType.EOF, "", 0, 0, 0);
        }
        return tokens[current];
    }
    
    /**
     * 工具方法: 获取前一个Token
     * @return 前一个Token
     */
    private function previous():Token {
        return tokens[current - 1];
    }
    
    /**
     * 工具方法: 检查是否到达Token序列末尾
     * @return 是否到达末尾
     */
    private function isAtEnd():Bool {
        return peek().type == TokenType.EOF;
    }
    
    /**
     * 解析切片
     * @return 切片节点
     */
    private function parseSlice():ASTNode {
        var node = createASTNode(NodeType.Slice);
        
        // 解析开始部分
        if (!check(TokenType.COLON)) {
            node.start = expression();
        }
        
        // 必须有冒号
        consume(TokenType.COLON, "Expected ':' in slice");
        
        // 解析结束部分
        if (!check(TokenType.RBRACKET) && !check(TokenType.COLON)) {
            node.end = expression();
        }
        
        // 解析步长（可选）
        if (match(TokenType.COLON)) {
            if (!check(TokenType.RBRACKET)) {
                node.step = expression();
            }
        }
        
        consume(TokenType.RBRACKET, "Expected ']' after slice");
        
        return node;
    }
    
    /**
     * 工具方法: 消耗期望类型的Token
     * @param type 期望的Token类型
     * @param message 错误消息
     * @return 消耗的Token
     */
    private function consume(type:TokenType, message:String):Token {
        if (check(type)) return advance();
        error('${message} (got ${peek().type})');
        return null;
    }
}
