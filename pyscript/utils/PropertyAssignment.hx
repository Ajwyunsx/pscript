    private function handlePropertyAssignment(node:ASTNode):Dynamic {
        // 检查必要的属性
        if (node.object == null || node.property == null || node.value == null) {
            throw "属性赋值错误: 缺少必要的属性 (object、property 或 value)";
        }
        
        // 获取和验证属性名
        var prop:String = getPropertyName(node.property);
        if (prop == null || prop.length == 0) {
            throw "属性赋值错误: 无效的属性名";
        }
        
        // 获取要赋值的值
        var value = evaluate(node.value);
        
        // 处理嵌套属性赋值
        if (node.object.type == NodeType.PropertyAccess) {
            return handleNestedPropertyAssignment(node.object, prop, value);
        } else {
            // 处理简单属性赋值
            var obj = evaluate(node.object);
            return safeSetProperty(obj, prop, value);
        }
    }
    
    private function getPropertyName(property:Dynamic):String {
        if (property == null) return null;
        
        try {
            if (Std.isOfType(property, String)) {
                return property;
            } else if (Reflect.hasField(property, "name")) {
                var name = Reflect.field(property, "name");
                return name != null ? name : null;
            } else if (Reflect.hasField(property, "value")) {
                var value = Reflect.field(property, "value");
                return value != null ? safeToString(value) : null;
            }
            return safeToString(property);
        } catch (e:Dynamic) {
            throw "获取属性名失败: " + e;
        }
    }
    
    private function handleNestedPropertyAssignment(objectNode:ASTNode, finalProp:String, value:Dynamic):Dynamic {
        // 递归处理嵌套属性
        var parentObj = evaluate(objectNode.object);
        var parentProp = getPropertyName(objectNode.property);
        
        if (parentProp == null || parentProp.length == 0) {
            throw "嵌套属性赋值错误: 无效的父属性名";
        }
        
        // 处理父对象为空的情况
        if (parentObj == null) {
            parentObj = {};
            var grandParentObj = evaluate(objectNode.object);
            if (grandParentObj != null) {
                safeSetProperty(grandParentObj, parentProp, parentObj, "父对象");
            } else {
                trace("Warning: 创建新的父对象用于属性设置");
            }
        }
        
        // 设置最终属性
        return safeSetProperty(parentObj, finalProp, value, parentProp);
    }
