package pyscript.utils;

/**
 * Token类型枚举
 * 包含Python语言的所有Token类型
 */
enum TokenType {
    // 字面量
    INT;            // 整数: 123, 0xFF, 0b1010, 0o777
    FLOAT;          // 浮点数: 123.456, 1e-10
    STRING;         // 字符串: "hello", 'world', """doc"""
    BYTES;          // 字节串: b"bytes"
    TRUE;           // 布尔值: True
    FALSE;          // 布尔值: False
    NONE;           // None值
    IDENTIFIER;     // 标识符: foo, bar
    
    // 运算符(数学)
    PLUS;           // +  加法
    MINUS;          // -  减法
    MULTIPLY;       // *  乘法
    DIVIDE;         // /  除法
    FLOOR_DIVIDE;   // // 整除
    MODULO;         // %  取模
    POWER;          // ** 幂运算
    MATMULT;        // @  矩阵乘法
    
    // 运算符(赋值)
    ASSIGN;         // =   赋值
    PLUS_ASSIGN;    // +=  加赋值
    MINUS_ASSIGN;   // -=  减赋值
    MULTIPLY_ASSIGN;// *=  乘赋值
    DIVIDE_ASSIGN;  // /=  除赋值
    MODULO_ASSIGN;  // %=  取模赋值
    POWER_ASSIGN;   // **= 幂赋值
    AND_ASSIGN;     // &=  按位与赋值
    OR_ASSIGN;      // |=  按位或赋值
    XOR_ASSIGN;     // ^=  按位异或赋值
    LSHIFT_ASSIGN;  // <<= 左移赋值
    RSHIFT_ASSIGN;  // >>= 右移赋值
    
    // 运算符(位)
    BIT_AND;        // &  按位与
    BIT_OR;         // |  按位或
    BIT_XOR;        // ^  按位异或
    BIT_NOT;        // ~  按位取反
    LSHIFT;         // << 左移
    RSHIFT;         // >> 右移
    
    // 运算符(比较)
    EQUALS;         // ==  等于
    NOT_EQUALS;     // !=  不等于
    LESS;           // <   小于
    GREATER;        // >   大于
    LESS_EQUAL;     // <=  小于等于
    GREATER_EQUAL;  // >=  大于等于
    
    // 运算符(逻辑)
    AND;            // and 逻辑与
    OR;             // or  逻辑或
    NOT;            // not 逻辑非
    IN;             // in  成员测试
    NOT_IN;         // not in 非成员测试
    IS;             // is  标识测试
    IS_NOT;         // is not 非标识测试
    
    // 分隔符
    LPAREN;         // (  左圆括号
    RPAREN;         // )  右圆括号
    LBRACKET;       // [  左方括号
    RBRACKET;       // ]  右方括号
    LBRACE;         // {  左大括号
    RBRACE;         // }  右大括号
    COMMA;          // ,  逗号
    COLON;          // :  冒号
    DOT;            // .  点号
    SEMICOLON;      // ;  分号
    AT;             // @  装饰器
    ELLIPSIS;       // ... 省略号
    ARROW;          // -> 函数返回标注
    
    // 关键字(基础)
    PASS;           // pass    空操作
    DEL;            // del     删除
    IMPORT;         // import  导入
    FROM;           // from    从...导入
    AS;             // as      别名
    
    // 关键字(控制流)
    IF;             // if      条件
    ELIF;           // elif    否则如果
    ELSE;           // else    否则
    FOR;            // for     循环
    WHILE;          // while   循环
    BREAK;          // break   跳出
    CONTINUE;       // continue 继续
    RETURN;         // return  返回
    
    // 关键字(函数和类)
    DEF;            // def     函数定义
    CLASS;          // class   类定义
    LAMBDA;         // lambda  匿名函数
    YIELD;          // yield   生成器
    YIELD_FROM;     // yield from 委托生成器
    
    // 关键字(异常)
    TRY;            // try     尝试
    EXCEPT;         // except  捕获
    FINALLY;        // finally 善后
    RAISE;          // raise   抛出
    ASSERT;         // assert  断言
    
    // 关键字(上下文)
    WITH;           // with    上下文管理
    ASYNC;          // async   异步
    AWAIT;          // await   等待
    
    // 关键字(作用域)
    GLOBAL;         // global  全局
    NONLOCAL;       // nonlocal 非局部
    
    // 结构控制
    INDENT;         // 缩进增加
    DEDENT;         // 缩进减少
    NEWLINE;        // 换行
    EOF;            // 文件结束
    
    // 错误
    ERROR;          // 词法错误
    
    // 特殊导入语法
    SCRIPT_IMPORT;   // script:import
    HAXE_IMPORT;     // haxe:import
}
