import pyscript.Interpreter;

class FlixelPyScriptExample {
    public static function main() {
        var interpreter = new Interpreter();
        
        // 设置parent对象（模拟FlxState）
        var mockParent = {
            add: function(obj:Dynamic) {
                trace("Added object to parent: " + obj);
            }
        };
        interpreter.parent = mockParent;
        
        var code = '
# FlxSprite example in PyScript
import FlxSprite
import FlxText
import FlxTween

# Create a sprite
spr = FlxSprite()
spr.loadGraphic("assets/yes.png")
spr.scale.set(2, 2)
spr.updateHitbox()
spr.screenCenter()
parent.add(spr)

# Create text
txt = FlxText(0, 0, 0, "This text was made with PyScript!\\nAlong with the sprite in the background.", 24)
txt.screenCenter()
txt.y = txt.y - 50
parent.add(txt)

# Create tween
FlxTween.tween(txt, {"y": txt.y + 100}, 0.5, {"ease": "quadOut", "type": 4})
';
        
        try {
            interpreter.run(code);
            trace("FlxSprite PyScript example executed successfully!");
        } catch (e:Dynamic) {
            trace("Error: " + e);
        }
    }
}