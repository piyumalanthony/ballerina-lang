// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

// ------------------------------------------------------------------
//                  Generate Check Cast Methods
// ------------------------------------------------------------------

function generateCheckCast(jvm:MethodVisitor mv, bir:BType sourceType, bir:BType targetType) {
    if (targetType is bir:BTypeInt) {
        generateCheckCastToInt(mv, sourceType);
        return;
    } else if (targetType is bir:BTypeFloat) {
        generateCheckCastToFloat(mv, sourceType);
        return;
    } else if (targetType is bir:BTypeString) {
        generateCheckCastToString(mv, sourceType);
        return;
    } else if (targetType is bir:BTypeBoolean) {
        generateCheckCastToBoolean(mv, sourceType);
        return;
    } else if (targetType is bir:BTypeByte) {
        generateCheckCastToByte(mv, sourceType);
        return;
    } else if (targetType is bir:BTypeNil) {
        checkCast(mv, targetType);
        return;
    } else if (targetType is bir:BUnionType) {
        generateCheckCastToUnionType(mv, sourceType, targetType);
        return;
    } else if (targetType is bir:BTypeAnyData) {
        generateCheckCastToAnyData(mv, sourceType);
        return;
    } else if (targetType is bir:BTypeAny) {
        generateCastToAny(mv, sourceType);
        return;
    } else if (targetType is bir:BJSONType) {
        generateCheckCastToJSON(mv, sourceType);
        return;
    } else if (sourceType is bir:BXMLType && targetType is bir:BMapType) {
        generateXMLToAttributesMap(mv, sourceType);
        return;
    }

    // do the ballerina checkcast
    checkCast(mv, targetType);

    // cast to the specific java class
    string targetTypeClass = getTargetClass(sourceType, targetType);
    mv.visitTypeInsn(CHECKCAST, targetTypeClass);
}

function generateCheckCastToInt(jvm:MethodVisitor mv, bir:BType sourceType) {
    if (sourceType is bir:BTypeInt || sourceType is bir:BTypeByte) {
        // do nothing
    } else if (sourceType is bir:BTypeFloat) {
        mv.visitInsn(D2L);
    } else if (sourceType is bir:BTypeAny ||
            sourceType is bir:BTypeAnyData ||
            sourceType is bir:BUnionType ||
            sourceType is bir:BJSONType) {
        mv.visitMethodInsn(INVOKESTATIC, TYPE_CHECKER, "anyToInt", io:sprintf("(L%s;)J", OBJECT), false);
    } else {
        error err = error(io:sprintf("Casting is not supported from '%s' to 'int'", sourceType));
        panic err;
    }
}

function generateCheckCastToFloat(jvm:MethodVisitor mv, bir:BType sourceType) {
    if (sourceType is bir:BTypeFloat) {
        // do nothing
    } else if (sourceType is bir:BTypeInt) {
        mv.visitInsn(L2D);
    } else if (sourceType is bir:BTypeAny ||
            sourceType is bir:BTypeAnyData ||
            sourceType is bir:BUnionType ||
            sourceType is bir:BJSONType) {
        mv.visitMethodInsn(INVOKESTATIC, TYPE_CHECKER, "anyToFloat", io:sprintf("(L%s;)D", OBJECT), false);
    } else {
        error err = error(io:sprintf("Casting is not supported from '%s' to 'float'", sourceType));
        panic err;
    }
}

function generateCheckCastToString(jvm:MethodVisitor mv, bir:BType sourceType) {
    if (sourceType is bir:BTypeString) {
        // do nothing
    } else if (sourceType is bir:BTypeAny ||
            sourceType is bir:BTypeAnyData ||
            sourceType is bir:BUnionType ||
            sourceType is bir:BJSONType) {
        checkCast(mv, bir:TYPE_STRING);
        mv.visitTypeInsn(CHECKCAST, STRING_VALUE);
    } else if (sourceType is bir:BTypeInt) {
        mv.visitMethodInsn(INVOKESTATIC, LONG_VALUE, "toString", io:sprintf("(J)L%s;", STRING_VALUE), false);
    } else if (sourceType is bir:BTypeFloat) {
        mv.visitMethodInsn(INVOKESTATIC, DOUBLE_VALUE, "toString", io:sprintf("(D)L%s;", STRING_VALUE), false);
    } else {
        error err = error(io:sprintf("Casting is not supported from '%s' to 'string'", sourceType));
        panic err;
    }
}

function generateCheckCastToBoolean(jvm:MethodVisitor mv, bir:BType sourceType) {
    if (sourceType is bir:BTypeBoolean) {
        // do nothing
    } else if (sourceType is bir:BTypeAny ||
            sourceType is bir:BTypeAnyData ||
            sourceType is bir:BUnionType ||
            sourceType is bir:BJSONType) {
        mv.visitMethodInsn(INVOKESTATIC, TYPE_CHECKER, "anyToBoolean", io:sprintf("(L%s;)Z", OBJECT), false);
    } else {
        error err = error(io:sprintf("Casting is not supported from '%s' to 'boolean'", sourceType));
        panic err;
    }
}

function generateCheckCastToByte(jvm:MethodVisitor mv, bir:BType sourceType) {
    if (sourceType is bir:BTypeInt || sourceType is bir:BTypeByte) {
        // do nothing
    } else if (sourceType is bir:BTypeAny ||
            sourceType is bir:BTypeAnyData ||
            sourceType is bir:BUnionType) {
        mv.visitMethodInsn(INVOKESTATIC, TYPE_CHECKER, "anyToByte", io:sprintf("(L%s;)J", OBJECT), false);
    } else {
        error err = error(io:sprintf("Casting is not supported from '%s' to 'byte'", sourceType));
        panic err;
    }
}

function generateCheckCastToAnyData(jvm:MethodVisitor mv, bir:BType sourceType) {
    if (sourceType is bir:BTypeAny || sourceType is bir:BUnionType) {
        checkCast(mv, bir:TYPE_ANYDATA);
    } else {
        // if value types, then ad box instruction
        generateCastToAny(mv, sourceType);
    }
}

function generateCheckCastToJSON(jvm:MethodVisitor mv, bir:BType sourceType) {
    if (sourceType is bir:BTypeAny ||
        sourceType is bir:BUnionType ||
        sourceType is bir:BMapType) {
        checkCast(mv, bir:TYPE_JSON);
    } else {
        // if value types, then ad box instruction
        generateCastToAny(mv, sourceType);
    }
}

function generateCheckCastToUnionType(jvm:MethodVisitor mv, bir:BType sourceType, bir:BUnionType targetType) {
    if (sourceType is bir:BTypeAny ||
            sourceType is bir:BTypeAnyData ||
            sourceType is bir:BUnionType||
            sourceType is bir:BJSONType) {
        checkCast(mv, targetType);
    } else {
        // if value types, then ad box instruction
        generateCastToAny(mv, sourceType);
    }
}

function checkCast(jvm:MethodVisitor mv, bir:BType targetType) {
    loadType(mv, targetType);
    mv.visitMethodInsn(INVOKESTATIC, TYPE_CHECKER, "checkCast",
            io:sprintf("(L%s;L%s;)L%s;", OBJECT, BTYPE, OBJECT), false);
}

function getTargetClass(bir:BType sourceType, bir:BType targetType) returns string {
    string targetTypeClass = "";
    if (targetType is bir:BArrayType || targetType is bir:BTupleType) {
        targetTypeClass = ARRAY_VALUE;
    } else if (targetType is bir:BMapType) {
        targetTypeClass = MAP_VALUE;
    } else if (targetType is bir:BRecordType) {
        targetTypeClass = MAP_VALUE;
    } else if (targetType is bir:BObjectType) {
        targetTypeClass = OBJECT_VALUE;
    } else if (targetType is bir:BErrorType) {
        targetTypeClass = ERROR_VALUE;
    } else if (targetType is bir:BXMLType) {
        targetTypeClass = XML_VALUE;
    } else {
        error err = error(io:sprintf("Casting is not supported from '%s' to '%s'", sourceType, targetType));
        panic err;
    }

    return targetTypeClass;
}
// ------------------------------------------------------------------
//   Generate Cast Methods - Performs cast without type checking
// ------------------------------------------------------------------
function generateCast(jvm:MethodVisitor mv, bir:BType sourceType, bir:BType targetType) {
    if (targetType is bir:BTypeInt) {
        generateCastToInt(mv, sourceType);
        return;
    } else if (targetType is bir:BTypeFloat) {
        generateCastToFloat(mv, sourceType);
        return;
    } else if (targetType is bir:BTypeString) {
        generateCastToString(mv, sourceType);
        return;
    } else if (targetType is bir:BTypeBoolean) {
        generateCastToBoolean(mv, sourceType);
        return;
    } else if (targetType is bir:BTypeByte) {
        generateCastToByte(mv, sourceType);
        return;
    } else if (targetType is bir:BTypeNil) {
        // do nothing
        return;
    } else if (targetType is bir:BUnionType) {
        generateCastToAny(mv, sourceType);
        return;
    } else if (targetType is bir:BTypeAnyData) {
        generateCastToAny(mv, sourceType);
        return;
    } else if (targetType is bir:BTypeAny) {
        generateCastToAny(mv, sourceType);
        return;
    } else if (targetType is bir:BJSONType) {
        generateCastToAny(mv, sourceType);
        return;
    }

    // cast to the specific java class
    string targetTypeClass = getTargetClass(sourceType, targetType);
    mv.visitTypeInsn(CHECKCAST, targetTypeClass);
}

function generateCastToInt(jvm:MethodVisitor mv, bir:BType sourceType) {
    if (sourceType is bir:BTypeInt || sourceType is bir:BTypeByte) {
        // do nothing
    } else if (sourceType is bir:BTypeFloat) {
        mv.visitInsn(D2L);
    } else if (sourceType is bir:BTypeAny ||
            sourceType is bir:BTypeAnyData ||
            sourceType is bir:BUnionType ||
            sourceType is bir:BJSONType) {
        mv.visitTypeInsn(CHECKCAST, LONG_VALUE);
        mv.visitMethodInsn(INVOKEVIRTUAL, LONG_VALUE, "longValue", "()J", false);
    } else {
        error err = error(io:sprintf("Casting is not supported from '%s' to 'int'", sourceType));
        panic err;
    }
}

function generateCastToFloat(jvm:MethodVisitor mv, bir:BType sourceType) {
    if (sourceType is bir:BTypeFloat) {
        // do nothing
    } else if (sourceType is bir:BTypeInt) {
        mv.visitInsn(L2D);
    } else if (sourceType is bir:BTypeAny ||
            sourceType is bir:BTypeAnyData ||
            sourceType is bir:BUnionType ||
            sourceType is bir:BJSONType) {
        mv.visitTypeInsn(CHECKCAST, DOUBLE_VALUE);
        mv.visitMethodInsn(INVOKEVIRTUAL, DOUBLE_VALUE, "doubleValue", "()D", false);
    } else {
        error err = error(io:sprintf("Casting is not supported from '%s' to 'float'", sourceType));
        panic err;
    }
}

function generateCastToString(jvm:MethodVisitor mv, bir:BType sourceType) {
    if (sourceType is bir:BTypeString) {
        // do nothing
    } else if (sourceType is bir:BTypeInt) {
        mv.visitMethodInsn(INVOKESTATIC, LONG_VALUE, "toString", io:sprintf("(J)L%s;", STRING_VALUE), false);
    } else if (sourceType is bir:BTypeFloat) {
        mv.visitMethodInsn(INVOKESTATIC, DOUBLE_VALUE, "toString", io:sprintf("(D)L%s;", STRING_VALUE), false);
    } else if (sourceType is bir:BTypeAny ||
            sourceType is bir:BTypeAnyData ||
            sourceType is bir:BUnionType ||
            sourceType is bir:BJSONType) {
        mv.visitTypeInsn(CHECKCAST, STRING_VALUE);
    } else {
        error err = error(io:sprintf("Casting is not supported from '%s' to 'string'", sourceType));
        panic err;
    }
}

function generateCastToBoolean(jvm:MethodVisitor mv, bir:BType sourceType) {
    if (sourceType is bir:BTypeBoolean) {
        // do nothing
    } else if (sourceType is bir:BTypeAny ||
            sourceType is bir:BTypeAnyData ||
            sourceType is bir:BUnionType ||
            sourceType is bir:BJSONType) {
        mv.visitTypeInsn(CHECKCAST, BOOLEAN_VALUE);
        mv.visitMethodInsn(INVOKEVIRTUAL, BOOLEAN_VALUE, "booleanValue", "()Z", false);
    } else {
        error err = error(io:sprintf("Casting is not supported from '%s' to 'boolean'", sourceType));
        panic err;
    }
}

function generateCastToByte(jvm:MethodVisitor mv, bir:BType sourceType) {
    if (sourceType is bir:BTypeInt || sourceType is bir:BTypeByte) {
        // do nothing
    } else if (sourceType is bir:BTypeAny ||
            sourceType is bir:BTypeAnyData ||
            sourceType is bir:BUnionType) {
        mv.visitTypeInsn(CHECKCAST, LONG_VALUE);
        mv.visitMethodInsn(INVOKEVIRTUAL, LONG_VALUE, "longValue", "()J", false);
    } else {
        error err = error(io:sprintf("Casting is not supported from '%s' to 'byte'", sourceType));
        panic err;
    }
}

function generateCastToAny(jvm:MethodVisitor mv, bir:BType sourceType) {
    if (sourceType is bir:BTypeInt || sourceType is bir:BTypeByte) {
        mv.visitMethodInsn(INVOKESTATIC, LONG_VALUE, "valueOf", io:sprintf("(J)L%s;", LONG_VALUE), false);
    } else if (sourceType is bir:BTypeFloat) {
        mv.visitMethodInsn(INVOKESTATIC, DOUBLE_VALUE, "valueOf", io:sprintf("(D)L%s;", DOUBLE_VALUE), false);
    } else if (sourceType is bir:BTypeBoolean) {
        mv.visitMethodInsn(INVOKESTATIC, BOOLEAN_VALUE, "valueOf", io:sprintf("(Z)L%s;", BOOLEAN_VALUE), false);
    } else {
        // do nothing
        return;
    }
}

function generateXMLToAttributesMap(jvm:MethodVisitor mv, bir:BType sourceType) {
    mv.visitMethodInsn(INVOKEVIRTUAL, XML_VALUE, "getAttributesMap", 
            io:sprintf("()L%s;", MAP_VALUE), false);
}
