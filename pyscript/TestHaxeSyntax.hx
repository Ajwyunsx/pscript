package pyscript;

import pyscript.PScript;

class TestHaxeSyntax {
    static function main() {
        var script = new PScript("");
        
        try {
            trace("=== 测试 Haxe 语法转换 ===");
            
            // 测试1: 十六进制颜色值和链式方法调用
            trace("测试1: game.camGame.flash(0xFF0000, 1)");
            script.setVar("flashCommand", "game.camGame.flash(0xFF0000, 1)");
            var result1 = script.getVar("flashCommand");
            trace("转换结果: " + result1);
            
            // 测试2: 其他十六进制值
            trace("\n测试2: 0xFFFFFF");
            script.setVar("whiteColor", "0xFFFFFF");
            var result2 = script.getVar("whiteColor");
            trace("转换结果: " + result2);
            
            // 测试3: 多个参数的方法调用
            trace("\n测试3: game.camera.shake(5, 0.5, true)");
            script.setVar("shakeCommand", "game.camera.shake(5, 0.5, true)");
            var result3 = script.getVar("shakeCommand");
            trace("转换结果: " + result3);
            
            // 测试4: 普通字符串（不应该被转换）
            trace("\n测试4: 普通字符串");
            script.setVar("normalString", "Hello World");
            var result4 = script.getVar("normalString");
            trace("转换结果: " + result4);
            
            // 测试5: 数字值（不应该被转换）
            trace("\n测试5: 数字值");
            script.setVar("numberValue", 42);
            var result5 = script.getVar("numberValue");
            trace("转换结果: " + result5);
            
            trace("\n=== 所有测试完成 ===");
            
        } catch (e:Dynamic) {
            trace("测试失败: " + e);
            trace("错误类型: " + Type.typeof(e));
        }
    }
}