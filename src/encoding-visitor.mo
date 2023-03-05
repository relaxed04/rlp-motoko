import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Hex "mo:encoding/Hex";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import List "mo:base/List";
import Nat8 "mo:base/Nat8";
import NumberItem "item-number";
import StringItem "item-string";
import ListItem "item-list";
import Visitor "visitor";

type Result<T,E> = Result.Result<T, E>;
type Uint8Array = Buffer.Buffer<Nat8>;

class EncodingVisitor(): Visitor.Visitor<Uint8Array> {

  private func toBuffer<T>(x :[T]) : Buffer.Buffer<T> {
    let thisBuffer = Buffer.Buffer<T>(x.size());
    for(thisItem in x.vals()) {
      thisBuffer.add(thisItem);
    };
    return thisBuffer;
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


  private func numberToHex(integer: Nat): Text {
    return(Hex.encode(natToBytes(integer)));
  };

  private func encodeLength(len: Nat, offset: Nat): Result<Uint8Array, Text> {
    if (len < 56) {
      return #ok(Buffer.fromArray([Nat8.fromNat(len) + Nat8.fromNat(offset)]));
    };
    let hexLength = numberToHex(len);
    let lLength = hexLength.size() / 2;
    let firstByte = numberToHex(offset + 55 + lLength);
    let result = switch(Hex.decode(firstByte # hexLength)){
      case(#ok(val)){ val };
      case(#err(err)){
        return #err("not a valid hex")
      }};
    let output = toBuffer<Nat8>(result);

    return #ok(output);
  };


  public func visitNumber(numberItem: Visitor.Item<Nat, Uint8Array>, visitor: EncodingVisitor): Result<Uint8Array, Text> {
    let inputBuf = switch(numberItem.toBytes()) {
      case(#ok(val)) { val };
      case(#err(val)) { return #err(val) };
    };
    if (inputBuf.size() == 1 and inputBuf.get(0) < 128) {
      return #ok(inputBuf);
    };

    switch(encodeLength(inputBuf.size(), 128)) {
      case(#ok(result)) { 
        result.append(inputBuf);
        return #ok(result);
      };
      case(#err(val)) { return #err(val)};
    };
  };

  public func visitString(stringItem: Visitor.Item<Text, Uint8Array>, visitor: EncodingVisitor): Result<Uint8Array, Text> {
    let inputBuf = switch(stringItem.toBytes()) {
      case(#ok(val)) { val };
      case(#err(val)) { return #err(val) };
    };
    if (inputBuf.size() == 1 and inputBuf.get(0) < 128) {
      return #ok(inputBuf);
    };

    switch(encodeLength(inputBuf.size(), 128)) {
      case(#ok(result)) { 
        result.append(inputBuf);
        return #ok(result);
      };
      case(#err(val)) { return #err(val)};
    };
  };

  public func visitUint8Array(uint8ArrayItem: Visitor.Item<Uint8Array, Uint8Array>, visitor: EncodingVisitor): Result<Uint8Array, Text> {
    let inputBuf = switch(uint8ArrayItem.toBytes()) {
      case(#ok(val)) { val };
      case(#err(val)) { return #err(val) };
    };
    if (inputBuf.size() == 1 and inputBuf.get(0) < 128) {
      return #ok(inputBuf);
    };

    switch(encodeLength(inputBuf.size(), 128)) {
      case(#ok(result)) { 
        result.append(inputBuf);
        return #ok(result);
      };
      case(#err(val)) { return #err(val)};
    };
  };

  public func visitList(listItem : Visitor.Item<Buffer.Buffer<Visitor.Item<Any, Uint8Array>>, Uint8Array>, visitor: EncodingVisitor): Result<Uint8Array, Text> {
    let inputs = listItem.getInput();
    let output = Buffer.Buffer<Nat8>(1);
    for(thisItem in inputs.vals()) {
      switch(thisItem.accept(visitor)) {
        case(#ok(val)) { output.append(val); };
        case(#err(val)) { return #err val};
      };
    };
    switch(encodeLength(output.size(), 192)) {
      case(#ok(result)) { 
        result.append(output);
        return #ok(result);
      };
      case(#err(val)) { return #err(val)};
    };
  }

};
