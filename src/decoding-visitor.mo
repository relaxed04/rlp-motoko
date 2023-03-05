import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Hex "mo:encoding/Hex";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import List "mo:base/List";
import Nat8 "mo:base/Nat8";
import Nat "mo:base/Nat";
import NumberItem "item-number";
import StringItem "item-string";
import ListItem "item-list";
import Visitor "visitor";

type Result<T,E> = Result.Result<T, E>;
type Uint8Array = Buffer.Buffer<Nat8>;

type Decoded = {
  #Uint8Array: Uint8Array;
  #Nested: Buffer.Buffer<Decoded>;
};

class DecodingVisitor(): Visitor.Visitor<Decoded> {

  let threshold : Nat8 = 127; // 7f
  let threshold2 : Nat8 = 183; // b7
  let threshold3 : Nat8 = 247;// f7
 
  let threshold4 : Nat8 = 182; // b6
  let threshold5 : Nat8 = 191; // bf
  let nullbyte : Nat8 = 128; // 80


  public func visitNumber(numberItem: Visitor.Item<Nat, Decoded>, visitor: DecodingVisitor): Result<Decoded, Text> {
    if(numberItem.getInput() == 0) { 
      return #ok(#Uint8Array(Buffer.Buffer(1)));
    };
    let inputBytes = switch(numberItem.toBytes()) {
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

  public func visitString(stringItem: Visitor.Item<Text, Decoded>, visitor: DecodingVisitor): Result<Decoded, Text> {
    if(stringItem.getInput().size() == 0) { 
      return #ok(#Uint8Array(Buffer.Buffer(1)));
    };
    let inputBytes = switch(stringItem.toBytes()) {
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


  public func visitUint8Array(uint8ArrayItem: Visitor.Item<Uint8Array, Decoded>, visitor: DecodingVisitor): Result<Decoded, Text> {
     if(uint8ArrayItem.getInput().size() == 0) {
          return #ok(#Uint8Array(Buffer.Buffer(1)));
        };
    let inputBytes = switch(uint8ArrayItem.toBytes()) {
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

  public func visitList(listItem : Visitor.Item<Buffer.Buffer<Visitor.Item<Any, Decoded>>, Decoded>, visitor: DecodingVisitor): Result<Decoded, Text> {
    if(listItem.getInput().size() == 0) { 
      return #ok(#Uint8Array(Buffer.Buffer(1)));
    };
    return #err "";
  };

  type Output = {
    data : Decoded;
    remainder : Buffer.Buffer<Nat8>;
  };

  private func decodeSingleByteInput(input: Uint8Array): Result<Output, Text> {
    let inputSlice = switch(safeSlice(input, 0, 1)) {
        case(#ok(val)) { val };
        case(#err(val)) { return #err(val) };
      };
    let _remainder = if (input.size() > 1) { // test this with > 1
        switch(safeSlice(input, 1, input.size())) {
          case(#ok(val)) { val };
          case(#err(val)) { return #err(val) };
        };
      } else {
        Buffer.Buffer<Nat8>(1);
      };
    return #ok({
      data = #Uint8Array(inputSlice);
      remainder = _remainder
    });
  };

  private func _decode(input: Uint8Array): Result<Output, Text> {
    
    var decoded = [];
    var firstByte = input.get(0);

    // a single byte whose value is in the [0x00, 0x7f] range, that byte is its own RLP encoding.
    if (firstByte <= threshold) {
      return decodeSingleByteInput(input);
    }
    else if (firstByte <= threshold2) {
      // string is 0-55 bytes long. A single byte with value 0x80 plus the length of the string followed by the string
      // The range of the first byte is [0x80, 0xb7]
      let length :  Nat8 = firstByte - threshold;

      // set 0x80 null to 0
      let data = if (firstByte == nullbyte) {
        Buffer.Buffer<Nat8>(1);
      }
      else {
        switch(safeSlice(input, 1, Nat8.toNat(length))) {
          case(#ok(val)) { val };
          case(#err(val)) { return #err(val) };
        };
      };

      if (length == 2 and data.get(0) < nullbyte) { 
        return #err("invalid RLP encoding: invalid prefix, single byte < 0x80 are not prefixed");
      };

      let remainderSlice = switch(safeSlice(input, Nat8.toNat(length), input.size())) {
          case(#ok(val)) { val };
          case(#err(val)) { return #err(val) };
        };
      
      return #ok({
        data = #Uint8Array(data);
        remainder = remainderSlice;
      });
    }
    else if (firstByte <= threshold5) {
      // string is greater than 55 bytes long. A single byte with the value (0xb7 plus the length of the length),
      // followed by the length, followed by the string
      let llength = firstByte - threshold4;
      if (Nat.sub(input.size(),1) < Nat8.toNat(llength)) {
        return #err("invalid RLP: not enough bytes for string length");
      };
      let inputSlice = switch(safeSlice(input, 1, Nat8.toNat(llength))) {
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

      let data = switch(safeSlice(input, Nat8.toNat(llength), Nat8.toNat(length + llength))) {
        case(#ok(val)) { val };
        case(#err(val)) { return #err(val) };
      };
      let _remainder = if (input.size() > Nat8.toNat(length + llength)) {
          switch(safeSlice(input, Nat8.toNat(length + llength), input.size())) {
            case(#ok(val)) { val };
            case(#err(val)) { return #err(val) };
          };
        } else {
          Buffer.Buffer<Nat8>(1);
        };

      return #ok({
        data = #Uint8Array(data);
        remainder = _remainder;
      });
    }
    else if (firstByte <= threshold3) {
      // a list between  0-55 bytes long
      let length = firstByte - threshold5;
      var innerRemainder = switch(safeSlice(input, 1, Nat8.toNat(length))) {
            case(#ok(val)) { val };
            case(#err(val)) { return #err(val) };
          };
      let decoded = Buffer.Buffer<Decoded>(1);
      while (innerRemainder.size() > 0) {

        let d = switch(_decode(innerRemainder)) {
          case(#ok(val)) { val };
          case(#err(val)) { return #err(val)};
        };
        
        decoded.add(d.data);
        innerRemainder := d.remainder;
      };

      let _remainder = if (input.size() > Nat8.toNat(length)) {
          switch(safeSlice(input, Nat8.toNat(length), input.size())) {
            case(#ok(val)) { val };
            case(#err(val)) { return #err(val) };
          };
        } else {
          Buffer.Buffer<Nat8>(1);
        };

      return #ok({
        data = #Nested(decoded);
        remainder = _remainder;
      });
    }
    else {
      // a list  over 55 bytes long
      let llength = firstByte - threshold4;
      let inputSlice = switch(safeSlice(input, 1, Nat8.toNat(llength))) {
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
      if (Nat8.toNat(totalLength) > input.size()) {
        return #err("invalid RLP: total length is larger than the data");
      };

      var innerRemainder = switch(safeSlice(input,Nat8.toNat( llength), Nat8.toNat(totalLength))) {
        case(#ok(val)) { val };
        case(#err(val)) { return #err(val) };
      };

      let decoded = Buffer.Buffer<Decoded>(1);
      while (innerRemainder.size() > 0) {
        let d = switch(_decode(innerRemainder)) {
          case(#ok(val)) { val };
          case(#err(val)) { return #err(val)};
        };
        decoded.add(d.data);
        innerRemainder := d.remainder;
      };
      let _remainder = if (input.size() > Nat8.toNat(totalLength)) {
          switch(safeSlice(input, Nat8.toNat(totalLength), input.size())) {
            case(#ok(val)) { val };
            case(#err(val)) { return #err(val) };
          };
        } else {
          Buffer.Buffer<Nat8>(1);
        };
      return #ok({
        data = #Nested(decoded);
        remainder = _remainder;
      });
    };
  };

  // Slices a Buffer<Nat8>, throws if the slice goes out-of-bounds of the Uint8Array.
  // E.g. `safeSlice(hexToBytes("aa"), 1, 2)` will throw.
  // @param input
  // @param start
  // @param end

//fix this so that i dont have to check wether size() > start in client. see how ethereuemjs just slices regardless;
  private func safeSlice(input: Uint8Array, start: Nat, end: Nat) : Result<Uint8Array, Text> {
    if (end > input.size()) { 
      return #err("invalid RLP (safeSlice): end slice of Uint8Array out-of-bounds");
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

  /*
  * Parse integers. Check if there is no leading zeros
  * @param v The value to parse
  * @param base The base to parse the integer into
  */
  private func decodeLength(v: Uint8Array): Result<Nat8, Text> {
    if (v.get(0) == 0 and v.get(1) == 0) {
      return #err("invalid RLP: extra zeros");
    };
    return switch(Hex.decode(Hex.encode(Buffer.toArray(v)))){
      case(#ok(val)){ #ok(val[0]) };
      case(#err(err)){ return #err("not a valid hex") }
    };
  };
};
