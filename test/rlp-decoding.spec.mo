import TestLib = "mo:testing/Suite";
import D "mo:base/Debug";
import Nat8 "mo:base/Nat8";
import RLP "../src/rlp";
import Hex "mo:encoding/Hex";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import List "mo:base/List";
import Result "mo:base/Result";

type Result<T,E> = Result.Result<T, E>;

let { describe; it; Suite } = TestLib;

let suite = Suite();

let testCases: [(Text, RLP.Input, Result<RLP.Decoded, Text>)] = [
  ("integer0",  #number(0), #ok(#Uint8Array(Buffer.fromArray<Nat8>([])))),
  ("integer1",  #number(1), #ok(#Uint8Array(Buffer.fromArray<Nat8>([1])))),
  ("integer127",  #number(127), #ok(#Uint8Array(Buffer.fromArray<Nat8>([127])))),
  ("integer128",  #number(128),#ok( #Uint8Array(Buffer.fromArray<Nat8>([])))),
  ("integerEmptyList",  #number(192), #ok(#Nested(Buffer.fromArray<RLP.Decoded>([])))),

  ("hexString7f",  #string("0x7f"), #ok(#Uint8Array(Buffer.fromArray<Nat8>([127])))),
  ("hexString80",  #string("0x80"), #ok(#Uint8Array(Buffer.fromArray<Nat8>([])))),
  ("hexString8180",  #string("0x8180"), #ok(#Uint8Array(Buffer.fromArray<Nat8>([128])))),
  ("hexString81ff",  #string("0x81ff"), #ok(#Uint8Array(Buffer.fromArray<Nat8>([255])))),
  ("hexString123",  #string("0x83010203"), #ok(#Uint8Array(Buffer.fromArray<Nat8>([1,2,3])))),
  ("hexStringEmptyList",  #string("0xc0"), #ok(#Nested(Buffer.fromArray<RLP.Decoded>([])))),
  ("hexShortString",  #string("0x83646f67"), #ok(#Uint8Array(Buffer.fromArray<Nat8>([ 100, 111, 103 ])))),
  ("hexStringNestedEmptyList",  #string("0xc4c2c0c0c0"), // [[[], []], []]
    #ok(#Nested(Buffer.fromArray<RLP.Decoded>([
      #Nested(Buffer.fromArray<RLP.Decoded>([
        #Nested(Buffer.fromArray<RLP.Decoded>([])),
        #Nested(Buffer.fromArray<RLP.Decoded>([]))
      ])),
      #Nested(Buffer.fromArray<RLP.Decoded>([]))
    ])))
  ),
  ("hexStringNestedList",  #string("0xc7c4c101c102c103"), // [[[1], [2]], [3]]
    #ok(#Nested(Buffer.fromArray<RLP.Decoded>([
      #Nested(Buffer.fromArray<RLP.Decoded>([
        #Nested(Buffer.fromArray<RLP.Decoded>([
          #Uint8Array(Buffer.fromArray<Nat8>([01]))
        ])),
        #Nested(Buffer.fromArray<RLP.Decoded>([
          #Uint8Array(Buffer.fromArray<Nat8>([02]))
        ]))
      ])),
      #Nested(Buffer.fromArray<RLP.Decoded>([
        #Uint8Array(Buffer.fromArray<Nat8>([03]))
      ]))
    ])))
  ),

  ("hexStringError7f7f",  #string("0x7f7f"), #err("invalid RLP: remainder must be zero")),


  ("byteArray7f",  #Uint8Array(Buffer.fromArray<Nat8>([127])), #ok(#Uint8Array(Buffer.fromArray<Nat8>([127])))),
  ("byteArray80", #Uint8Array(Buffer.fromArray<Nat8>([128])), #ok(#Uint8Array(Buffer.fromArray<Nat8>([])))),
  ("byteArray8180", #Uint8Array(Buffer.fromArray<Nat8>([129, 128])), #ok(#Uint8Array(Buffer.fromArray<Nat8>([128])))),
  ("byteArray81ff", #Uint8Array(Buffer.fromArray<Nat8>([129, 255])), #ok(#Uint8Array(Buffer.fromArray<Nat8>([255])))),
  ("byteArray123",  #Uint8Array(Buffer.fromArray<Nat8>([131,1,2,3])), #ok(#Uint8Array(Buffer.fromArray<Nat8>([1,2,3])))),
  ("byteArrayNestedEmptyLists",  
    #Uint8Array(Buffer.fromArray<Nat8>([196,194,192,192,192])), // [[[], []], []]
    #ok(#Nested(Buffer.fromArray<RLP.Decoded>([
      #Nested(Buffer.fromArray<RLP.Decoded>([
        #Nested(Buffer.fromArray<RLP.Decoded>([])),
        #Nested(Buffer.fromArray<RLP.Decoded>([]))
      ])),
      #Nested(Buffer.fromArray<RLP.Decoded>([]))
  ])))
  ),
  ("byteArrayNestedLists",
    #Uint8Array(Buffer.fromArray<Nat8>([199, 196, 193, 1, 193, 2, 193, 3])), // [[[1], [2]], [3]]
    #ok(#Nested(Buffer.fromArray<RLP.Decoded>([
      #Nested(Buffer.fromArray<RLP.Decoded>([
        #Nested(Buffer.fromArray<RLP.Decoded>([
          #Uint8Array(Buffer.fromArray<Nat8>([01]))
        ])),
        #Nested(Buffer.fromArray<RLP.Decoded>([
          #Uint8Array(Buffer.fromArray<Nat8>([02]))
        ]))
      ])),
      #Nested(Buffer.fromArray<RLP.Decoded>([
        #Uint8Array(Buffer.fromArray<Nat8>([03]))
      ]))
    ])))
  ),
  ("byteArrayNestedListsOfDifferentTypes",
    #Uint8Array(Buffer.fromArray<Nat8>([ 210, 207, 200, 131, 100, 111, 103, 131,  99,  97, 116, 197, 132,  98, 105, 114, 100, 193, 3 ])), // [[["dog", "cat"], ["bird"]], [3]]
    #ok(#Nested(Buffer.fromArray<RLP.Decoded>([
      #Nested(Buffer.fromArray<RLP.Decoded>([
        #Nested(Buffer.fromArray<RLP.Decoded>([
          #Uint8Array(Buffer.fromArray<Nat8>([100, 111, 103])),
          #Uint8Array(Buffer.fromArray<Nat8>([99, 97, 116]))
        ])),
        #Nested(Buffer.fromArray<RLP.Decoded>([
          #Uint8Array(Buffer.fromArray<Nat8>([98, 105, 114, 100]))
        ]))
      ])),
      #Nested(Buffer.fromArray<RLP.Decoded>([
        #Uint8Array(Buffer.fromArray<Nat8>([03]))
      ]))
    ])))
  ),
];

func compareUint8Array(output: RLP.Uint8Array, expected: RLP.Uint8Array): Bool {
  let result = Buffer.compare<Nat8>(output, expected, Nat8.compare);
  return switch(result) {
    case(#equal) { true };
    case(_) { false };
  };
};

// TODO clean this up and move to test utils
func compareDecodedOutput(output: RLP.Decoded, expected: RLP.Decoded): Bool {
  return switch(output) {
    case(#Uint8Array(outputVal)) { 
      switch(expected) {
        case(#Uint8Array(expectedVal)) {  compareUint8Array(outputVal, expectedVal)  };
        case(#Nested(val)) { 
          return false;
        }; 
      };
    };
    case(#Nested(outputVal)) { 
      switch(expected) {
        case(#Uint8Array(val)) { 
          return false;
        }; 
        case(#Nested(expectedVal)) {
          if(outputVal.size() != expectedVal.size()) {
            return false;
          };
          if(outputVal.size() == 0) {
            return true;
          };

          var i = 0;
          var result = true;
          while (i < outputVal.size()) {
            result := result and compareDecodedOutput(outputVal.get(i), expectedVal.get(i));
            i += 1;
          };
          return result;
        };
      };
     };
  };
};

func convertNat8BufferToHexText(buffer : Buffer.Buffer<Nat8>): Text {
  var result = "";
  for(byte in buffer.vals()) {
    result #= Hex.encodeByte(byte); 
  };
  return result;
};

func flattenResult(result: RLP.Decoded): RLP.Uint8Array {
  return switch(result) {
    case(#Uint8Array(val)) { val };
    case(#Nested(val)) { 
      let output = Buffer.Buffer<Nat8>(1);
       for(thisItem in val.vals()) {
          output.append(flattenResult(thisItem));
        };
        output;
     };
  };
};

func testDecodingVal(name: Text, input: RLP.Input, expectedResult: Result<RLP.Decoded, Text>) : TestLib.NamedTest {
  return it(name, func () : Bool {
    let decoded = RLP.decode(input);
    switch(decoded) {
      case(#ok(val)) { 
        switch(expectedResult) {
          case(#ok(expected)) {
            let result = compareDecodedOutput(val, expected);
            if ( not result ) {
              let flattenedOutput = flattenResult(val);
              let flattenedExpected = flattenResult(expected);
              let outputText = convertNat8BufferToHexText(flattenedOutput);
              let expectedText = convertNat8BufferToHexText(flattenedExpected);
              Debug.print("expected: " # expectedText # " " # "result: " # outputText)
            };
            return result;
            };
          case(#err(err)) { return false };
        };
      };
      case(#err(val)) {
        switch(expectedResult) {
          case(#ok(expected)) { return false };
          case(#err(err)) { return true };
        };
      };
    };

});
};

let testCasesIterable = Iter.fromArray(testCases);

let decodingTests = Iter.map(testCasesIterable, func ((name: Text, input: RLP.Input, expected: Result<RLP.Decoded, Text>)): TestLib.NamedTest {
  return testDecodingVal(name, input, expected);
});

suite.run([
    describe("RLP Decoding", Iter.toArray(decodingTests))
]);
