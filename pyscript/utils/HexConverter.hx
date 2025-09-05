package pyscript.utils;

/**
 * Hexadecimal conversion utilities
 * Handles conversion between different hexadecimal formats and values
 */
class HexConverter {
    /**
     * Convert a hexadecimal string to an integer value
     * @param hexString The hexadecimal string to convert (e.g., "0xFFFFFF" or "FFFFFF")
     * @return The integer value of the hexadecimal string
     */
    public static function hexToInt(hexString:String):Int {
        if (hexString == null) {
            throw "Invalid hexadecimal value: null";
        }
        
        // Remove 0x prefix if present
        var cleanHex = hexString;
        if (StringTools.startsWith(hexString, "0x")) {
            cleanHex = hexString.substr(2);
        }
        
        // Validate hexadecimal characters
        if (!~/^[0-9a-fA-F]+$/.match(cleanHex)) {
            throw "Invalid hexadecimal value: " + hexString;
        }
        
        // Convert to integer
        return Std.parseInt("0x" + cleanHex);
    }
    
    /**
     * Convert an integer to a hexadecimal string
     * @param value The integer value to convert
     * @param withPrefix Whether to include the 0x prefix (default: true)
     * @return The hexadecimal string representation
     */
    public static function intToHex(value:Int, withPrefix:Bool = true):String {
        var hex = StringTools.hex(value);
        if (withPrefix) {
            return "0x" + hex;
        }
        return hex;
    }
    
    /**
     * Convert an integer to an octal string
     * @param value The integer value to convert
     * @return The octal string representation
     */
    public static function intToOctal(value:Int):String {
        if (value == 0) return "0";
        
        var result = "";
        var num = value;
        
        while (num > 0) {
            result = Std.string(num & 7) + result;
            num = num >> 3;
        }
        
        return result;
    }
    
    /**
     * Convert an integer to a binary string
     * @param value The integer value to convert
     * @return The binary string representation
     */
    public static function intToBinary(value:Int):String {
        if (value == 0) return "0";
        
        var result = "";
        var num = value;
        
        while (num > 0) {
            result = Std.string(num & 1) + result;
            num = num >> 1;
        }
        
        return result;
    }
    
    /**
     * Check if a string is a valid hexadecimal value
     * @param value The string to check
     * @return True if the string is a valid hexadecimal value
     */
    public static function isHexValue(value:String):Bool {
        if (value == null) return false;
        
        // Check if it starts with 0x followed by hex digits, or just hex digits
        return ~/^(0x)?[0-9a-fA-F]+$/.match(value);
    }
    
    /**
     * Convert a value to the appropriate type if it's a hexadecimal string
     * @param value The value to convert
     * @return The converted value or the original value if not a hexadecimal string
     */
    public static function convertHexValue(value:Dynamic):Dynamic {
        if (Std.isOfType(value, String)) {
            var strValue:String = cast value;
            if (isHexValue(strValue)) {
                try {
                    return hexToInt(strValue);
                } catch (e:Dynamic) {
                    // If conversion fails, return the original value
                    return value;
                }
            }
        }
        return value;
    }
    
    /**
     * Process an array of values, converting any hexadecimal strings to integers
     * @param args The array of values to process
     * @return A new array with hexadecimal strings converted to integers
     */
    public static function processHexValues(args:Array<Dynamic>):Array<Dynamic> {
        if (args == null) return [];
        
        var result:Array<Dynamic> = [];
        for (arg in args) {
            result.push(convertHexValue(arg));
        }
        return result;
    }
    
    /**
     * Convert hexadecimal numbers in a string to integer values
     * @param code The string containing hexadecimal numbers
     * @return The string with hexadecimal numbers converted
     */
    public static function convertHexInString(code:String):String {
        if (code == null) return null;
        
        // This is a simplified conversion that just ensures hex values are uppercase
        // In a more complex implementation, this could convert hex literals to decimal literals
        var result = code;
        
        // Replace common lowercase hex patterns with uppercase
        var hexPatterns = [
            "0x([0-9a-f]+)" => "0x$1" // This will be processed by the regex below
        ];
        
        // Use regex to find and convert hex values
        var hexRegex = ~/0x([0-9a-fA-F]+)/g;
        var newResult = new StringBuf();
        var pos = 0;
        
        while (hexRegex.matchSub(result, pos)) {
            // Add the text before the match
            newResult.addSub(result, pos, hexRegex.matchedPos().pos - pos);
            
            var hexMatch = hexRegex.matched(1);
            try {
                var intValue = hexToInt("0x" + hexMatch);
                newResult.add(Std.string(intValue));
            } catch (e:Dynamic) {
                // If conversion fails, keep the original hex value
                newResult.add("0x" + hexMatch);
            }
            
            // Update position to after the match
            pos = hexRegex.matchedPos().pos + hexRegex.matchedPos().len;
        }
        
        // Add the remaining text
        if (pos < result.length) {
            newResult.addSub(result, pos, result.length - pos);
        }
        
        result = newResult.toString();
        
        return result;
    }
}