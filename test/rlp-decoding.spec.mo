import TestLib = "mo:testing/Suite";
import D "mo:base/Debug";
import Nat8 "mo:base/Nat8";
import RLP "../src/lib";
import Hex "mo:encoding/Hex";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import List "mo:base/List";

let { describe; it; Suite } = TestLib;

let suite = Suite();

let testCases: [(Text, RLP.Input, RLP.Output)] = [
  ("byteArray7f",  #Uint8Array(Buffer.fromArray<Nat8>([127])), #Uint8Array(Buffer.fromArray<Nat8>([127]))),
  ("byteArray80", #Uint8Array(Buffer.fromArray<Nat8>([128])), #Uint8Array(Buffer.fromArray<Nat8>([]))),
  ("byteArray8180", #Uint8Array(Buffer.fromArray<Nat8>([129, 128])), #Uint8Array(Buffer.fromArray<Nat8>([128]))),
  ("byteArray81ff", #Uint8Array(Buffer.fromArray<Nat8>([129, 255])), #Uint8Array(Buffer.fromArray<Nat8>([255]))),
  ("byteArray123",  #Uint8Array(Buffer.fromArray<Nat8>([131,1,2,3])), #Uint8Array(Buffer.fromArray<Nat8>([1,2,3]))),

  ("byteArrayNestedEmptyLists",  
    #Uint8Array(Buffer.fromArray<Nat8>([196,194,192,192,192])), // [[[], []], []]
    #Nested(Buffer.fromArray<RLP.Output>([
      #Nested(Buffer.fromArray<RLP.Output>([
        #Nested(Buffer.fromArray<RLP.Output>([])),
        #Nested(Buffer.fromArray<RLP.Output>([]))
      ])),
      #Nested(Buffer.fromArray<RLP.Output>([]))
  ]))
  ),

  ("byteArrayNestedLists",
    #Uint8Array(Buffer.fromArray<Nat8>([199, 196, 193, 1, 193, 2, 193, 3])), // [[[1], [2]], [3]]
    #Nested(Buffer.fromArray<RLP.Output>([
      #Nested(Buffer.fromArray<RLP.Output>([
        #Nested(Buffer.fromArray<RLP.Output>([
          #Uint8Array(Buffer.fromArray<Nat8>([01]))
        ])),
        #Nested(Buffer.fromArray<RLP.Output>([
          #Uint8Array(Buffer.fromArray<Nat8>([02]))
        ]))
      ])),
      #Nested(Buffer.fromArray<RLP.Output>([
        #Uint8Array(Buffer.fromArray<Nat8>([03]))
      ]))
    ]))
  ),

  ("byteArrayNestedListsOfDifferentTypes",
    #Uint8Array(Buffer.fromArray<Nat8>([ 210, 207, 200, 131, 100, 111, 103, 131,  99,  97, 116, 197, 132,  98, 105, 114, 100, 193, 3 ])), // [[["dog", "cat"], ["bird"]], [3]]
    #Nested(Buffer.fromArray<RLP.Output>([
      #Nested(Buffer.fromArray<RLP.Output>([
        #Nested(Buffer.fromArray<RLP.Output>([
          #Uint8Array(Buffer.fromArray<Nat8>([100, 111, 103])),
          #Uint8Array(Buffer.fromArray<Nat8>([99, 97, 116]))
        ])),
        #Nested(Buffer.fromArray<RLP.Output>([
          #Uint8Array(Buffer.fromArray<Nat8>([98, 105, 114, 100]))
        ]))
      ])),
      #Nested(Buffer.fromArray<RLP.Output>([
        #Uint8Array(Buffer.fromArray<Nat8>([03]))
      ]))
    ]))
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
func compareDecodedOutput(output: RLP.Output, expected: RLP.Output): Bool {
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

func testDecodingVal(name: Text, input: RLP.Input, expected: RLP.Output) : TestLib.NamedTest {
  return it(name, func () : Bool {
    let decoded = RLP.decode(input);
    let result = compareDecodedOutput(decoded, expected);
    return result;
});
};

let testCasesIterable = Iter.fromArray(testCases);

let decodingTests = Iter.map(testCasesIterable, func ((name: Text, input: RLP.Input, expected: RLP.Output)): TestLib.NamedTest {
  return testDecodingVal(name, input, expected);
});

suite.run([
    describe("RLP Decoding", Iter.toArray(decodingTests))
]);
