// Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

function valueTypeWichAlwaysTrue() returns string {
    int x = 10;
    if (x is int) {
        return "int";
    }

    return "n/a";
}

function valueTypeWichAlwaysFalse() returns string {
    int x = 10;
    if (x is float) {
        return "int";
    }

    return "n/a";
}

function valueTypeAgainstUnionTypeWhichAlwaysTrue() returns string {
    int x = 10;
    if (x is float|int) {
        return "float|int";
    }

    return "n/a";
}

function valueTypeAgainstUnionTypeWhichAlwaysFalse() returns string {
    int x = 10;
    if (x is string|float) {
        return "string|float";
    }

    return "n/a";
}

function unionTypeAgainstUnionTypeWhichAlwaysTrue_1() returns string {
    int|string x = "hello";
    if (x is int|string) {
        return "int|string";
    }

    return "n/a";
}

function unionTypeAgainstUnionTypeWhichAlwaysTrue_2() returns string {
    int|string x = "hello";
    if (x is int|string|float) {
        return "int|string|float";
    }

    return "n/a";
}

function unionTypeAgainstUnionTypeWhichAlwaysFalse() returns string {
    int|string x = "hello";
    if (x is boolean|float) {
        return "boolean|float";
    }

    return "n/a";
}

type A record {
    int x;
    string y;
};

type B record {
    int x;
};

function testSimpleRecordTypes() returns string {
    A a = {};
    if (a is B) {
        return "a is B";
    } else if (a is A) {
        return "a is A";
    }

    // checking against undefined type
    if (a is C) {
    
    }
    return "n/a";
}

type X record {
    int p;
    string q;
    A r;
};

type Y record {
    int p;
    string q;
    B r;
};

function testNestedRecordTypes() returns string {
    X x = {};
    if (x is Y) {
        return "x is B";
    } else if (x is X) {
        return "x is A";
    }

    return "n/a";
}

function testArrays() {
    int[] x = [1, 2, 3];
    int[][] y = [[1, 2, 3], [4, 5, 6]];

    boolean b0 = x is int[] && y is int[][];
    boolean b1 = x is float[];
    boolean b2 = y is json;
    boolean b3 = y is json[];
    boolean b4 = y is json[][];
}

function testTuples() {
    (int, string) a = (4, "hello");

    boolean b0 = a is (int, string);
    boolean b1 = a is (float, boolean);
    boolean b2 = a is (any, any);
    boolean b3 = a is (json, json);
}

function testTupleWithAssignableTypes() returns (boolean, boolean, boolean) {
    (X, Y) a = ({}, {});
    boolean b0 = a is (X, X);
    boolean b1 = a is (X, Y);
    boolean b2 = a is (Y, Y);
    return (b0, b1, b2);
}

function testSimpleConstrainedMap() returns (boolean, boolean, boolean, boolean, boolean) {
    map<string> m = {"key1": "value1"};
    boolean b0 = m is map;
    boolean b1 = m is map<any>;
    boolean b2 = m is map<string>;
    boolean b3 = m is json;
    boolean b4 = m is map<json>;
    return (b0, b1, b2, b3, b4);
}

type A3 record {
    int x;
};

type B3 record {
    int x;
    !...
};

function testSealedRecordTypes() returns string {
    A3 a = {};
     if (a is B3) {
        return "a is B3";
    } else if (a is A3) {
        return "a is A3";
    }

    return "n/a";
}

function testRecordArrays() returns (boolean, boolean) {
    A[] a = [{}, {}];
    A[][] b = [[{}, {}], [{}, {}]];
    return (a is B[], b is B[][]);
}
