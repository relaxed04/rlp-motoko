import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Hex "mo:encoding/Hex";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import List "mo:base/List";
import Nat8 "mo:base/Nat8";
import Nat "mo:base/Nat";
import Visitor "visitor";

type Uint8Array = Buffer.Buffer<Nat8>;
type Result<T,E> = Result.Result<T, E>;

class StringItem<T> (input: Text): Visitor.Item<Text, T> {

  public func getInput(): Text {
    return input;
  };

  private func toBuffer<T>(x :[T]) : Buffer.Buffer<T> {
    let thisBuffer = Buffer.Buffer<T>(x.size());
    for(thisItem in x.vals()) {
      thisBuffer.add(thisItem);
    };
    return thisBuffer;
  };

    /** Removes 0x from a given String */
  public func stripHexPrefix(str: Text): Text { 
    return if (isHexPrefixed(str))
        switch(Text.stripStart(str, #text("0x"))){
          case(null){ str };
          case(?val){ val }}
      else 
        str;
  };

    /** Pad a string to be even */
  public func padToEven(a: Text): Text { 
    return if (a.size() % 2 == 1) {
      "0" # a;  
    }
    else { 
      a;
    };
  };

  /** Check if a string is prefixed by 0x */
  public func isHexPrefixed(str: Text): Bool {
    let charArray = Iter.toArray(str.chars());
    return if ((str.size() >= 2) and (charArray[0] == '0') and  (charArray[1] == 'x')) {
      true;
    }
    else {
      false;
    };
  };

  public func toBytes (): Result<Uint8Array, Text> { 
    if (isHexPrefixed(input)) {
      let result = switch(Hex.decode(padToEven(stripHexPrefix(input)))){
        case(#ok(val)){ val };
        case(#err(err)){ return #err("nat a valid hex") }};
      return #ok(toBuffer<Nat8>(result));
    };
    let str = Text.encodeUtf8(input);
    let buf = Buffer.fromArray<Nat8>(Blob.toArray(str));
    return #ok(buf);
    };

  private func natToBytes(n : Nat) : [Nat8] { 
    var a : Nat8 = 0;
    var b : Nat = n;
    var bytes = List.nil<Nat8>();
    var test = true;
    while(test) {
      a := Nat8.fromNat(b % 256);
      b := b / 256;
      bytes := List.push<Nat8>(a, bytes);
      test := b > 0;
    };
    List.toArray<Nat8>(bytes);
  };

  public func accept(visitor: Visitor.Visitor<T>): Result<T, Text> {
    return visitor.visitString(StringItem<T>(input), visitor);
  } 
};
