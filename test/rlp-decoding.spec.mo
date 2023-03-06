import TestLib = "mo:testing/Suite";
import D "mo:base/Debug";
import Nat8 "mo:base/Nat8";
import RLP "../src";
import Hex "mo:encoding/Hex";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import List "mo:base/List";
import Result "mo:base/Result";
import Types "../src/types";
import Array "mo:base/Array";

type Result<T,E> = Result.Result<T, E>;

let { describe; it; Suite } = TestLib;

let suite = Suite();

let testCasesErrResult: [(Text, Types.Input, Result<Types.Decoded, Text>)] = [
  ("hexStringSingleByteError",  #string("0x7f7f"), #err("")),
  ("hexStringNullError",  #string("0x807f"), #err("")),
  ("hexStringLengthError1",  #string("0x830102"), #err("")),
  ("hexLongStringLengthError1",  #string("0xb8370102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556"), #err("")),
  ("hexLongStringLengthError2",  #string("0xb8390102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556"), #err("")),
  ("hexLongStringLengthError3",  #string("0xb803010203"), #err("")),

  ("hexStringListLengthError1",  #string("0xc30102"), #err("")),
  ("hexStringListLengthError2",  #string("0xc4830102"), #err("")),
  ("hexStringNestedListLengthError1",  #string("0xc4c101c10102"), #err("")),
  ("hexStringNestedListLengthError2",  #string("0xc4c101c101c101"), #err("")),
  ("hexStringNestedListLengthError3",  #string("0xc2c101c101"), #err("")),
  ("hexStringNestedListLengthError4",  #string("0xc6c101c101"), #err("")),

  ("hexStringLongListLengthError1",  #string("0xf8370102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556"), #err("")),
  ("hexStringLongListLengthError2",  #string("0xf838010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657"), #err("")),
  ("hexStringLongListLengthError3",  #string("0xf8390102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556"), #err("")),
  ("hexStringLongListLengthError4",  #string("0xf838010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657"), #err("")),
];

let testCasesOkResult: [(Text, Types.Input, Result<Types.Decoded, Text>)] = [
  ("integer0",  #number(0), #ok(#Uint8Array(Buffer.fromArray<Nat8>([])))),
  ("integer1",  #number(1), #ok(#Uint8Array(Buffer.fromArray<Nat8>([1])))),
  ("integer127",  #number(127), #ok(#Uint8Array(Buffer.fromArray<Nat8>([127])))),
  ("integer128",  #number(128),#ok( #Uint8Array(Buffer.fromArray<Nat8>([])))),
  ("integerEmptyList",  #number(192), #ok(#Nested(Buffer.fromArray<Types.Decoded>([])))),

  ("hexString7f",  #string("0x7f"), #ok(#Uint8Array(Buffer.fromArray<Nat8>([127])))),
  ("hexString80",  #string("0x80"), #ok(#Uint8Array(Buffer.fromArray<Nat8>([])))),
  ("hexString8180",  #string("0x8180"), #ok(#Uint8Array(Buffer.fromArray<Nat8>([128])))),
  ("hexString81ff",  #string("0x81ff"), #ok(#Uint8Array(Buffer.fromArray<Nat8>([255])))),
  ("hexString123",  #string("0x83010203"), #ok(#Uint8Array(Buffer.fromArray<Nat8>([1,2,3])))),
  ("hexStringEmptyList",  #string("0xc0"), #ok(#Nested(Buffer.fromArray<Types.Decoded>([])))),
  ("hexShortString",  #string("0x83646f67"), #ok(#Uint8Array(Buffer.fromArray<Nat8>([ 100, 111, 103 ])))),
  ("hexLongString", #string("0xb8380102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556"), 
    #ok(#Uint8Array(Buffer.fromArray<Nat8>([
      1,  2,  3,  4,  5,  6,  7,  8,  9, 16, 17, 18,
      19, 20, 21, 22, 23, 24, 25, 32, 33, 34, 35, 36,
      37, 38, 39, 40, 41, 48, 49, 50, 51, 52, 53, 54,
      55, 56, 57, 64, 65, 66, 67, 68, 69, 70, 71, 72,
      73, 80, 81, 82, 83, 84, 85, 86
    ])))), 

  ("hexStringNestedEmptyList",  #string("0xc4c2c0c0c0"), // [[[], []], []]
    #ok(#Nested(Buffer.fromArray<Types.Decoded>([
      #Nested(Buffer.fromArray<Types.Decoded>([
        #Nested(Buffer.fromArray<Types.Decoded>([])),
        #Nested(Buffer.fromArray<Types.Decoded>([]))
      ])),
      #Nested(Buffer.fromArray<Types.Decoded>([]))
    ])))
  ),
  ("hexStringNestedList",  #string("0xc7c4c101c102c103"), // [[[1], [2]], [3]]
    #ok(#Nested(Buffer.fromArray<Types.Decoded>([
      #Nested(Buffer.fromArray<Types.Decoded>([
        #Nested(Buffer.fromArray<Types.Decoded>([
          #Uint8Array(Buffer.fromArray<Nat8>([01]))
        ])),
        #Nested(Buffer.fromArray<Types.Decoded>([
          #Uint8Array(Buffer.fromArray<Nat8>([02]))
        ]))
      ])),
      #Nested(Buffer.fromArray<Types.Decoded>([
        #Uint8Array(Buffer.fromArray<Nat8>([03]))
      ]))
    ])))
  ),
  ("hexLongList",  
    #string("0xf8380102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556"), 
    #ok(#Nested(Buffer.fromArray<Types.Decoded>([
      #Uint8Array(Buffer.fromArray<Nat8>([01])), #Uint8Array(Buffer.fromArray<Nat8>([02])), #Uint8Array(Buffer.fromArray<Nat8>([03])), #Uint8Array(Buffer.fromArray<Nat8>([04])), #Uint8Array(Buffer.fromArray<Nat8>([05])), 
      #Uint8Array(Buffer.fromArray<Nat8>([06])), #Uint8Array(Buffer.fromArray<Nat8>([07])), #Uint8Array(Buffer.fromArray<Nat8>([08])), #Uint8Array(Buffer.fromArray<Nat8>([09])), #Uint8Array(Buffer.fromArray<Nat8>([16])),
      #Uint8Array(Buffer.fromArray<Nat8>([17])), #Uint8Array(Buffer.fromArray<Nat8>([18])), #Uint8Array(Buffer.fromArray<Nat8>([19])), #Uint8Array(Buffer.fromArray<Nat8>([20])), #Uint8Array(Buffer.fromArray<Nat8>([21])),
      #Uint8Array(Buffer.fromArray<Nat8>([22])), #Uint8Array(Buffer.fromArray<Nat8>([23])), #Uint8Array(Buffer.fromArray<Nat8>([24])), #Uint8Array(Buffer.fromArray<Nat8>([25])),#Uint8Array(Buffer.fromArray<Nat8>([32])), 
      #Uint8Array(Buffer.fromArray<Nat8>([33])), #Uint8Array(Buffer.fromArray<Nat8>([34])), #Uint8Array(Buffer.fromArray<Nat8>([35])), #Uint8Array(Buffer.fromArray<Nat8>([36])),#Uint8Array(Buffer.fromArray<Nat8>([37])), 
      #Uint8Array(Buffer.fromArray<Nat8>([38])), #Uint8Array(Buffer.fromArray<Nat8>([39])), #Uint8Array(Buffer.fromArray<Nat8>([40])), #Uint8Array(Buffer.fromArray<Nat8>([41])),#Uint8Array(Buffer.fromArray<Nat8>([48])), 
      #Uint8Array(Buffer.fromArray<Nat8>([49])), #Uint8Array(Buffer.fromArray<Nat8>([50])), #Uint8Array(Buffer.fromArray<Nat8>([51])), #Uint8Array(Buffer.fromArray<Nat8>([52])), #Uint8Array(Buffer.fromArray<Nat8>([53])),
      #Uint8Array(Buffer.fromArray<Nat8>([54])), #Uint8Array(Buffer.fromArray<Nat8>([55])), #Uint8Array(Buffer.fromArray<Nat8>([56])), #Uint8Array(Buffer.fromArray<Nat8>([57])),#Uint8Array(Buffer.fromArray<Nat8>([64])), 
      #Uint8Array(Buffer.fromArray<Nat8>([65])), #Uint8Array(Buffer.fromArray<Nat8>([66])), #Uint8Array(Buffer.fromArray<Nat8>([67])), #Uint8Array(Buffer.fromArray<Nat8>([68])), #Uint8Array(Buffer.fromArray<Nat8>([69])),
      #Uint8Array(Buffer.fromArray<Nat8>([70])), #Uint8Array(Buffer.fromArray<Nat8>([71])), #Uint8Array(Buffer.fromArray<Nat8>([72])), #Uint8Array(Buffer.fromArray<Nat8>([73])), #Uint8Array(Buffer.fromArray<Nat8>([80])), 
      #Uint8Array(Buffer.fromArray<Nat8>([81])), #Uint8Array(Buffer.fromArray<Nat8>([82])), #Uint8Array(Buffer.fromArray<Nat8>([83])), #Uint8Array(Buffer.fromArray<Nat8>([84])), #Uint8Array(Buffer.fromArray<Nat8>([85])), 
      #Uint8Array(Buffer.fromArray<Nat8>([86])),
    ])))), 

  ("byteArray7f",  #Uint8Array(Buffer.fromArray<Nat8>([127])), #ok(#Uint8Array(Buffer.fromArray<Nat8>([127])))),
  ("byteArray80", #Uint8Array(Buffer.fromArray<Nat8>([128])), #ok(#Uint8Array(Buffer.fromArray<Nat8>([])))),
  ("byteArray8180", #Uint8Array(Buffer.fromArray<Nat8>([129, 128])), #ok(#Uint8Array(Buffer.fromArray<Nat8>([128])))),
  ("byteArray81ff", #Uint8Array(Buffer.fromArray<Nat8>([129, 255])), #ok(#Uint8Array(Buffer.fromArray<Nat8>([255])))),
  ("byteArray123",  #Uint8Array(Buffer.fromArray<Nat8>([131,1,2,3])), #ok(#Uint8Array(Buffer.fromArray<Nat8>([1,2,3])))),
  ("byteArrayNestedEmptyLists",  
    #Uint8Array(Buffer.fromArray<Nat8>([196,194,192,192,192])), // [[[], []], []]
    #ok(#Nested(Buffer.fromArray<Types.Decoded>([
      #Nested(Buffer.fromArray<Types.Decoded>([
        #Nested(Buffer.fromArray<Types.Decoded>([])),
        #Nested(Buffer.fromArray<Types.Decoded>([]))
      ])),
      #Nested(Buffer.fromArray<Types.Decoded>([]))
  ])))
  ),
  ("byteArrayNestedLists",
    #Uint8Array(Buffer.fromArray<Nat8>([199, 196, 193, 1, 193, 2, 193, 3])), // [[[1], [2]], [3]]
    #ok(#Nested(Buffer.fromArray<Types.Decoded>([
      #Nested(Buffer.fromArray<Types.Decoded>([
        #Nested(Buffer.fromArray<Types.Decoded>([
          #Uint8Array(Buffer.fromArray<Nat8>([01]))
        ])),
        #Nested(Buffer.fromArray<Types.Decoded>([
          #Uint8Array(Buffer.fromArray<Nat8>([02]))
        ]))
      ])),
      #Nested(Buffer.fromArray<Types.Decoded>([
        #Uint8Array(Buffer.fromArray<Nat8>([03]))
      ]))
    ])))
  ),
  ("byteArrayNestedListsOfDifferentTypes",
    #Uint8Array(Buffer.fromArray<Nat8>([ 210, 207, 200, 131, 100, 111, 103, 131,  99,  97, 116, 197, 132,  98, 105, 114, 100, 193, 3 ])), // [[["dog", "cat"], ["bird"]], [3]]
    #ok(#Nested(Buffer.fromArray<Types.Decoded>([
      #Nested(Buffer.fromArray<Types.Decoded>([
        #Nested(Buffer.fromArray<Types.Decoded>([
          #Uint8Array(Buffer.fromArray<Nat8>([100, 111, 103])),
          #Uint8Array(Buffer.fromArray<Nat8>([99, 97, 116]))
        ])),
        #Nested(Buffer.fromArray<Types.Decoded>([
          #Uint8Array(Buffer.fromArray<Nat8>([98, 105, 114, 100]))
        ]))
      ])),
      #Nested(Buffer.fromArray<Types.Decoded>([
        #Uint8Array(Buffer.fromArray<Nat8>([03]))
      ]))
    ])))
  ),
];

func compareUint8Array(output: Types.Uint8Array, expected: Types.Uint8Array): Bool {
  let result = Buffer.compare<Nat8>(output, expected, Nat8.compare);
  return switch(result) {
    case(#equal) { true };
    case(_) { false };
  };
};

func compareDecodedOutput(output: Types.Decoded, expected: Types.Decoded): Bool {
  return switch(output) {
    case(#Uint8Array(outputVal)) { 
      switch(expected) {
        case(#Uint8Array(expectedVal)) {  
          compareUint8Array(outputVal, expectedVal);
        };
        case(#Nested(val)) {  return false; }; 
      };
    };
    case(#Nested(outputVal)) { 
      switch(expected) {
        case(#Uint8Array(val)) { return false; }; 
        case(#Nested(expectedVal)) {
          if(outputVal.size() != expectedVal.size()) {
            return false;
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

func testDecodingVal(name: Text, input: Types.Input, expectedResult: Result<Types.Decoded, Text>) : TestLib.NamedTest {
  return it(name, func () : Bool {
    let decoded = RLP.decode(input);
    switch(decoded) {
      case(#ok(val)) { 
        switch(expectedResult) {
          case(#ok(expected)) {
            let result = compareDecodedOutput(val, expected);
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

let testCases = Buffer.fromArray<(Text, Types.Input, Result<Types.Decoded, Text>)>(testCasesErrResult);
testCases.append(Buffer.fromArray(testCasesOkResult));

let decodingTests = Iter.map(testCases.vals(), func ((name: Text, input: Types.Input, expected: Result<Types.Decoded, Text>)): TestLib.NamedTest {
  return testDecodingVal(name, input, expected);
});

suite.run([
  describe("RLP Decoding", Iter.toArray(decodingTests))
]);
