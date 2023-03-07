import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import D "mo:base/Debug";
import Hex "../hex";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Types "../types";


module {
  type Result<T,E> = Result.Result<T, E>;

  /** Transform anything into a Uint8Array */
  public func toBytes(v: Types.Input): Result<Types.Uint8Array, Text> {
    switch(v) {
      case(#Uint8Array(item)) {
        return #ok(item);
      };
      case(#string(item)) {
        if (isHexPrefixed(item)) {
          let result = switch(Hex.decode(padToEven(stripHexPrefix(item)))){
            case(#ok(val)){ val };
            case(#err(err)){ return #err("nat a valid hex") }
          };
          return #ok(toBuffer<Nat8>(result));
        };
        let str = Text.encodeUtf8(item);
        let buf = Buffer.fromArray<Nat8>(Blob.toArray(str));
        return #ok(buf);
      };
      case(#number(v)) {
        if(v == 0) {
          return #ok(Buffer.Buffer<Nat8>(1));
        } else {
          let byteArray = natToBytes(v);
          return #ok(Buffer.fromArray(byteArray));
        }
      };
      case(#Null) {
        return #ok(Buffer.Buffer<Nat8>(1));
      };
      case(#Undefined) {
        return #ok(Buffer.Buffer<Nat8>(1));
      };
      case(_){};
    };
    return #err("toBytes: received unsupported type ");
  };

  public func toBuffer<T>(x :[T]) : Buffer.Buffer<T> {
    let thisBuffer = Buffer.Buffer<T>(x.size());
    for(thisItem in x.vals()) {
      thisBuffer.add(thisItem);
    };
    return thisBuffer;
  };

    /** Transform an integer into its hexadecimal value */
  public func numberToHex(integer: Nat): Text {
    return(Hex.encode(natToBytes(integer)));
  };

  // Slices a Buffer<Nat8>, throws if the slice goes out-of-bounds of the Uint8Array.
  // E.g. `safeSlice(hexToBytes("aa"), 1, 2)` will throw.
  // @param input
  // @param start
  // @param end
  public func safeSlice(input: Types.Uint8Array, start: Nat, end: Nat) : Result<Types.Uint8Array, Text> {
    if (end > input.size()) { 
      return #err("invalid RLP (safeSlice): end slice of Uint8Array out-of-bounds");
    };
    if (start > (Nat.sub(input.size(), 1))) { 
      return #ok(Buffer.Buffer<Nat8>(1));
    };
    if(start > end) {
      return #ok(Buffer.Buffer<Nat8>(1));
    };
    let output = Buffer.Buffer<Nat8>(end - start);
    var tracker = 0;
    loop {
      if(tracker >= end) {
        return #ok(output);
      }  
      else if(tracker >= start) {
        output.add(input.get(tracker));
        tracker += 1;
      } else {
        tracker += 1;
      }
    };
  };

    /** Check if a string is prefixed by 0x */
  private func isHexPrefixed(str: Text): Bool {
    let charArray = Iter.toArray(str.chars());
    return if ((str.size() >= 2) and (charArray[0] == '0') and  (charArray[1] == 'x')) {
      true;
    } else {
      false;
    };
  };

  /** Removes 0x from a given String */
  private func stripHexPrefix(str: Text): Text { 
    return if (isHexPrefixed(str)) {
      switch(Text.stripStart(str, #text("0x"))){
        case(null){ str };
        case(?val){ val }}
    } else {
        str;
    }
  };

    /** Pad a string to be even */
  private func padToEven(a: Text): Text { 
    return if (a.size() % 2 == 1) {
      "0" # a;  
    } else { 
      a;
    };
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
}