import TestLib = "mo:testing/Suite";
import D "mo:base/Debug";
import Nat8 "mo:base/Nat8";
import RLP "../src";
import Hex "../src/hex";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import List "mo:base/List";
import Types "../src/types";

let { describe; it; Suite } = TestLib;

let suite = Suite();

let testCases: [(Text, Types.Input, Text)] = [
  ("integer0", #number(0), "80"),
  ("integer1", #number(1), "01"),
  ("integer127", #number(127), "7f"),
  ("integer128", #number(128), "8180"),
  ("integer256", #number(256), "820100"),
  ("integer1024", #number(1024), "820400"),
  ("integerLargeHex1", #number(0xFFFFFF), "83ffffff"),
  ("integerLargeHex2", #number(0xFFFFFFFF), "84ffffffff"),
  ("integerLargeHex3", #number(0xFFFFFFFFFF), "85ffffffffff"),
  ("integerLargeHex4", #number(0xFFFFFFFFFFFF), "86ffffffffffff"),
  ("integerLargeHex5", #number(0xFFFFFFFFFFFFFF), "87ffffffffffffff"),
  ("integerLargeHex6", #number(0xFFFFFFFFFFFFFFFF), "88ffffffffffffffff"),

  ("byteArrayEmpty", #Uint8Array(Buffer.fromArray<Nat8>([])), "80"),
  ("byteArray0", #Uint8Array(Buffer.fromArray<Nat8>([0])), "00"),
  ("byteArray1", #Uint8Array(Buffer.fromArray<Nat8>([1])), "01"),
  ("byteArray7F", #Uint8Array(Buffer.fromArray<Nat8>([0x7F])), "7f"),
  ("byteArray80", #Uint8Array(Buffer.fromArray<Nat8>([0x80])), "8180"),
  ("byteArrayFF", #Uint8Array(Buffer.fromArray<Nat8>([0xFF])), "81ff"),
  ("byteArraySize3", #Uint8Array(Buffer.fromArray<Nat8>([1, 2, 3])), "83010203"),

  ("hexString00", #string("0x00"), "00"),
  ("hexString7F", #string("0x7F"), "7f"),
  ("hexString80", #string("0x80"), "8180"),
  ("hexStringFF", #string("0xFF"), "81ff"),

  ("emptyString", #string(""), "80"),
  ("byteString00", #string("\u{0000}"), "00"),
  ("byteString01", #string("\u{0001}"), "01"),
  ("byteString7F", #string("\u{007F}"), "7f"),
  ("byteString80", #string("\u{0080}"), "82c280"),
  ("byteStringFF", #string("\u{00FF}"), "82c3bf"),
  ("shortString", #string("dog"), "83646f67"),
  ("shortString2", #string("Lorem ipsum dolor sit amet, consectetur adipisicing eli"), "b74c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e7365637465747572206164697069736963696e6720656c69"),
  ("shortString3", #string("Lorem ipsum dolor sit amet, consectetur adipisicing elit"), "b8384c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e7365637465747572206164697069736963696e6720656c6974"),
  ("longString", #string("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur mauris magna, suscipit sed vehicula non, iaculis faucibus tortor. Proin suscipit ultricies malesuada. Duis tortor elit, dictum quis tristique eu, ultrices at risus. Morbi a est imperdiet mi ullamcorper aliquet suscipit nec lorem. Aenean quis leo mollis, vulputate elit varius, consequat enim. Nulla ultrices turpis justo, et posuere urna consectetur nec. Proin non convallis metus. Donec tempor ipsum in mauris congue sollicitudin. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Suspendisse convallis sem vel massa faucibus, eget lacinia lacus tempor. Nulla quis ultricies purus. Proin auctor rhoncus nibh condimentum mollis. Aliquam consequat enim at metus luctus, a eleifend purus egestas. Curabitur at nibh metus. Nam bibendum, neque at auctor tristique, lorem libero aliquet arcu, non interdum tellus lectus sit amet eros. Cras rhoncus, metus ac ornare cursus, dolor justo ultrices metus, at ullamcorper volutpat"), "b904004c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e73656374657475722061646970697363696e6720656c69742e20437572616269747572206d6175726973206d61676e612c20737573636970697420736564207665686963756c61206e6f6e2c20696163756c697320666175636962757320746f72746f722e2050726f696e20737573636970697420756c74726963696573206d616c6573756164612e204475697320746f72746f7220656c69742c2064696374756d2071756973207472697374697175652065752c20756c7472696365732061742072697375732e204d6f72626920612065737420696d70657264696574206d6920756c6c616d636f7270657220616c6971756574207375736369706974206e6563206c6f72656d2e2041656e65616e2071756973206c656f206d6f6c6c69732c2076756c70757461746520656c6974207661726975732c20636f6e73657175617420656e696d2e204e756c6c6120756c74726963657320747572706973206a7573746f2c20657420706f73756572652075726e6120636f6e7365637465747572206e65632e2050726f696e206e6f6e20636f6e76616c6c6973206d657475732e20446f6e65632074656d706f7220697073756d20696e206d617572697320636f6e67756520736f6c6c696369747564696e2e20566573746962756c756d20616e746520697073756d207072696d697320696e206661756369627573206f726369206c756374757320657420756c74726963657320706f737565726520637562696c69612043757261653b2053757370656e646973736520636f6e76616c6c69732073656d2076656c206d617373612066617563696275732c2065676574206c6163696e6961206c616375732074656d706f722e204e756c6c61207175697320756c747269636965732070757275732e2050726f696e20617563746f722072686f6e637573206e69626820636f6e64696d656e74756d206d6f6c6c69732e20416c697175616d20636f6e73657175617420656e696d206174206d65747573206c75637475732c206120656c656966656e6420707572757320656765737461732e20437572616269747572206174206e696268206d657475732e204e616d20626962656e64756d2c206e6571756520617420617563746f72207472697374697175652c206c6f72656d206c696265726f20616c697175657420617263752c206e6f6e20696e74657264756d2074656c6c7573206c65637475732073697420616d65742065726f732e20437261732072686f6e6375732c206d65747573206163206f726e617265206375727375732c20646f6c6f72206a7573746f20756c747269636573206d657475732c20617420756c6c616d636f7270657220766f6c7574706174"),
  ("longHexString", #string("0x0102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556"), "b8380102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556"),

  ("null", #Null, "80"),
  ("undefined", #Undefined, "80"),

  ("listEmpty", #List(Buffer.fromArray<Types.Input>([])), "c0"),
  ("listHexString", #List(Buffer.fromArray<Types.Input>([#string("0x01")])), "c101"),
  ("listIntegerSize3", #List(Buffer.fromArray<Types.Input>([#number(1), #number(2), #number(3)])), "c3010203"),

  ("listString", #List(Buffer.fromArray<Types.Input>([#string("aaa"), #string("bbb"), #string("ccc"), #string("ddd"), #string("eee"), #string("fff"), #string("ggg"), #string("hhh"), #string("iii"), #string("jjj"), #string("kkk"), #string("lll"), #string("mmm"), #string("nnn"), #string("ooo")])), "f83c836161618362626283636363836464648365656583666666836767678368686883696969836a6a6a836b6b6b836c6c6c836d6d6d836e6e6e836f6f6f"),
  ("listListListEmpty", #List(Buffer.fromArray<Types.Input>([
    #List(Buffer.fromArray<Types.Input>([
      #List(Buffer.fromArray<Types.Input>([])),
      #List(Buffer.fromArray<Types.Input>([]))
    ])),
    #List(Buffer.fromArray<Types.Input>([]))
  ])) , "c4c2c0c0c0"),
  ("listListString", #List(Buffer.fromArray<Types.Input>([
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
    #List(Buffer.fromArray<Types.Input>([#string("asdf"), #string("qwer"), #string("zxcv")])),
  ])), "f90200cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376"),
  ("longList", #List(Buffer.fromArray<Types.Input>([
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
    ])), "f8380102030405060708091011121314151617181920212223242526272829303132333435363738394041424344454647484950515253545556")
];


func convertNat8BufferToHexText(buffer : Buffer.Buffer<Nat8>): Text {
  return Buffer.foldLeft<Text, Nat8>(buffer, "", func (acc, curr) { acc # Hex.encodeW8(curr) });
};

let testCasesIterable = Iter.fromArray(testCases);

let encodingTests = Iter.map(testCasesIterable, func ((name: Text, input: Types.Input, expectedHexText: Text)): TestLib.NamedTest {
  return it(name, func () : Bool {
    let encoded = RLP.encode(input);
    switch(encoded) {
      case(#ok(val)) {
        let encodedHexText = convertNat8BufferToHexText(val);
        return encodedHexText == expectedHexText; 
      };
      case(#err(val)) { return false };
    };
  });
});

suite.run([
    describe("RLP Encoding", Iter.toArray(encodingTests))
]);
