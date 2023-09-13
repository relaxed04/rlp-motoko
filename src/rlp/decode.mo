import Types "../types";
import Result "mo:base/Result";
import Utils "utils";
import Buffer "mo:base/Buffer";
import Nat8 "mo:base/Nat8";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Nat64 "mo:base/Nat64";
import Hex "../hex";

module {
  type Result<T,E> = Result.Result<T, E>;

  let threshold : Nat8 = 127; // 7f
  let threshold2 : Nat8 = 183; // b7
  let threshold3 : Nat8 = 247;// f7
 
  let threshold4 : Nat8 = 182; // b6
  let threshold5 : Nat8 = 191; // bf
  let threshold6: Nat8 = 246; // f6
  let nullbyte : Nat8 = 128; // 80

  public func decode(input: Types.Input): Result<Types.Decoded, Text> {
    switch(input) {
      case(#string(item)) {
        if(item.size() == 0) { 
          return #ok(#Uint8Array(Buffer.Buffer(1)));
        };
      };
      case(#number(item)) {
        if(item == 0) { 
          return #ok(#Uint8Array(Buffer.Buffer(1)));
        };
      };
      case(#Uint8Array(item)) {
        if(item.size() == 0) {
          return #ok(#Uint8Array(Buffer.Buffer(1)));
        };
      };
      case(#List(item)) {
        if(item.size() == 0) { 
          return #ok(#Uint8Array(Buffer.Buffer(1)));
        };
      };
      case(#Null) {
        return #ok(#Uint8Array(Buffer.Buffer(1)));
      };
      case(#Undefined) {
        return #ok(#Uint8Array(Buffer.Buffer(1)));
      };
    };

    let inputBytes = switch(Utils.toBytes(input)) {
      case(#ok(val)) { val };
      case(#err(val)) { return #err(val) };
    };
    
    let decoded = _decode(inputBytes);

    switch(_decode(inputBytes)) {
      case(#ok(decoded)) {     
        if (decoded.remainder.size() != 0) {
          return #err("invalid RLP: remainder must be zero");
        };
        return #ok(decoded.data); };
      case(#err(val)) { return #err(val) };
    };
  };

  private type Output = {
    data : Types.Decoded;
    remainder : Buffer.Buffer<Nat8>;
  };

  private func _decode(input: Types.Uint8Array): Result<Output, Text> {
    let firstByte = input.get(0);

    if (firstByte <= threshold) { // a single byte whose value is in the [0x00, 0x7f] range, that byte is its own RLP encoding.
      return decodeSingleByte(input);
    } 
    else if (firstByte <= threshold2) { // string is 0-55 bytes long. A single byte with value 0x80 plus the length of the string followed by the string
      return decodeShortString(input);
    }
    else if (firstByte <= threshold5) { // string is greater than 55 bytes long. A single byte with the value (0xb7 plus the length of the length), followed by the length, followed by the string   
      return decodeLongString(input);
    }
    else if (firstByte <= threshold3) { // a list between  0-55 bytes long
      return decodeShortList(input);
    }
    else { // a list  over 55 bytes long
      return decodeLongList(input);
    };
  };

  private func decodeSingleByte(input: Types.Uint8Array): Result<Output, Text> {
    let(left, right) = Buffer.split<Nat8>(input, 1);
    return #ok({
      data = #Uint8Array(left);
      remainder = right
    });
  };

  private func decodeShortString(input: Types.Uint8Array): Result<Output, Text> {
    let firstByte = input.get(0);
    let length = Nat8.toNat(firstByte - threshold);

    let dataSlice = if (firstByte == nullbyte) {
      Buffer.Buffer<Nat8>(1);
    }
    else {
      switch(Utils.safeSlice(input, 1, length)) {
        case(#ok(val)) { val };
        case(#err(val)) { return #err(val) };
      };
    };

    if (length == 2 and dataSlice.get(0) < nullbyte) { 
      return #err("invalid RLP encoding: invalid prefix, single byte < 0x80 are not prefixed");
    };

    let remainderSlice = switch(Utils.safeSlice(input, length, input.size())) {
      case(#ok(val)) { val };
      case(#err(val)) { return #err(val) };
    };
    
    return #ok({
      data = #Uint8Array(dataSlice);
      remainder = remainderSlice;
    });
  };

  private func decodeLongString(input: Types.Uint8Array): Result<Output, Text> {
    let firstByte = input.get(0);
    let llength = Nat8.toNat(firstByte - threshold4);
    if (Nat.sub(input.size(), 1) < llength) {
      return #err("invalid RLP: not enough bytes for string length");
    };
    let inputSlice = switch(Utils.safeSlice(input, 1, llength)) {
      case(#ok(val)) { val };
      case(#err(val)) { return #err(val) };
    };

    let length = switch(decodeLength(inputSlice)) {
      case(#ok(val)) { val };
      case(#err(val)) { return #err(val) };
    };
    if (length <= 55) {
      return #err("invalid RLP: expected string length to be greater than 55");
    };

    let data = switch(Utils.safeSlice(input, llength, length + llength)) {
      case(#ok(val)) { val };
      case(#err(val)) { return #err(val) };
    };
    let _remainder = switch(Utils.safeSlice(input, length + llength, input.size())) {
      case(#ok(val)) { val };
      case(#err(val)) { return #err(val) };
    };
      
    return #ok({
      data = #Uint8Array(data);
      remainder = _remainder;
    });
  };

  private func decodeShortList(input: Types.Uint8Array): Result<Output, Text> {
    let firstByte = input.get(0);
    let length = Nat8.toNat(firstByte - threshold);

    var innerRemainder = switch(Utils.safeSlice(input, 1, length)) {
      case(#ok(val)) { val };
      case(#err(val)) { return #err(val) };
    };
    let decoded = Buffer.Buffer<Types.Decoded>(1);
    while (innerRemainder.size() > 0) {
      let d = switch(_decode(innerRemainder)) {
        case(#ok(val)) { val };
        case(#err(val)) { return #err(val)};
      };
      decoded.add(d.data);
      innerRemainder := d.remainder;
    };

    let _remainder = switch(Utils.safeSlice(input, length, input.size())) {
      case(#ok(val)) { val };
      case(#err(val)) { return #err(val) };
    };
      
    return #ok({
      data = #Nested(decoded);
      remainder = _remainder;
    });
  };

  private func decodeLongList(input: Types.Uint8Array): Result<Output, Text> {
    let firstByte = input.get(0);
    let llength = Nat8.toNat(firstByte - threshold6);
    let inputSlice = switch(Utils.safeSlice(input, 1, llength)) {
      case(#ok(val)) { val };
      case(#err(val)) { return #err(val) };
    };
    let length = switch(decodeLength(inputSlice)) {
      case(#ok(val)) { val };
      case(#err(val)) { return #err(val) };
    };
    if (length < 56) {
      return #err("invalid RLP: encoded list too short");
    };
    let totalLength = llength + length;
    if (totalLength > input.size()) {
      return #err("invalid RLP: total length is larger than the data");
    };

    var innerRemainder = switch(Utils.safeSlice(input, llength, totalLength)) {
      case(#ok(val)) { val };
      case(#err(val)) { return #err(val) };
    };
    let decoded = Buffer.Buffer<Types.Decoded>(1);
    while (innerRemainder.size() > 0) {
      let d = switch(_decode(innerRemainder)) {
        case(#ok(val)) { val };
        case(#err(val)) { return #err(val)};
      };
      decoded.add(d.data);
      innerRemainder := d.remainder;
    };
    let _remainder = switch(Utils.safeSlice(input, totalLength, input.size())) {
      case(#ok(val)) { val };
      case(#err(val)) { return #err(val) };
    };
    
    return #ok({
      data = #Nested(decoded);
      remainder = _remainder;
    });
  };

  /*
  * Parse integers.
  * @param v The value to parse
  */
  private func decodeLength(v : Types.Uint8Array) : Result<Nat, Text> {
    if (v.size() > 8) return #err("input too long");

    var result : Nat64 = 0;
    for (i in Iter.range(0, v.size() - 1)) {
      result += (Nat64.fromNat(Nat8.toNat(v.get(i))) << Nat64.fromNat(8 * (v.size() - 1 - i)));
    };

    #ok(Nat64.toNat(result));
  };
}