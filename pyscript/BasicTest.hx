import pyscript.core.Interpreter;

class BasicTest {
    static function main() {
        var interp = new Interpreter();
        
        try {
            // First test: simple variable access
            trace("=== Test 1: Basic variable access ===");
            interp.run('
game = {"health": 100}
print("game.health:", game.health)
');
            
            // Second test: function without parameters
            trace("=== Test 2: Function without parameters ===");
            interp.run('
def test_func():
    print("Inside function, game.health:", game.health)

test_func()
');
            
            // Third test: the problematic case
            trace("=== Test 3: The problematic onUpdate function ===");
            interp.run('
def onUpdate():
    print("Before modification, game.health:", game.health)
    game.health = game.health - 1
    print("After modification, game.health:", game.health)

onUpdate()
');
            
            trace("All tests completed successfully!");
            
        } catch (e:Dynamic) {
            trace("Test failed with error: " + e);
            trace("Error type: " + Type.typeof(e));
        }
    }
}