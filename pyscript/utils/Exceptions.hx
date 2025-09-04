package pyscript.utils;

/**
 * 表示break语句的异常
 */
class BreakException {
    public function new() {}
}

/**
 * 表示continue语句的异常
 */
class ContinueException {
    public function new() {}
}

/**
 * 表示return语句的异常
 */
class ReturnException {
    public var value:Dynamic;
    public function new(value:Dynamic) {
        this.value = value;
    }
}

/**
 * 表示assert失败的异常
 */
class AssertionError {
    public var message:String;
    public function new(message:String) {
        this.message = message;
    }
}

/**
 * 表示Python内建异常的基类
 */
class PyException {
    public var message:String;
    public var type:String;
    public function new(message:String, ?type:String = "Exception") {
        this.message = message;
        this.type = type;
    }
    
    public function toString():String {
        return '${type}: ${message}';
    }
}

/**
 * 零除异常
 */
class ZeroDivisionError extends PyException {
    public function new(message:String) {
        super(message, "ZeroDivisionError");
    }
}

/**
 * 索引越界异常
 */
class IndexError extends PyException {
    public function new(message:String) {
        super(message, "IndexError");
    }
}

/**
 * 键错误
 */
class KeyError extends PyException {
    public function new(message:String) {
        super(message, "KeyError");
    }
}

/**
 * 类型错误
 */
class TypeError extends PyException {
    public function new(message:String) {
        super(message, "TypeError");
    }
}

/**
 * 值错误
 */
class ValueError extends PyException {
    public function new(message:String) {
        super(message, "ValueError");
    }
}

/**
 * 名称错误
 */
class NameError extends PyException {
    public function new(message:String) {
        super(message, "NameError");
    }
}

/**
 * 属性错误
 */
class AttributeError extends PyException {
    public function new(message:String) {
        super(message, "AttributeError");
    }
}

/**
 * IO错误
 */
class IOError extends PyException {
    public function new(message:String) {
        super(message, "IOError");
    }
}
