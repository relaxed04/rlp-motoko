import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import D "mo:base/Debug";
import Hex "mo:encoding/Hex";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Result "mo:base/Result";
import Text "mo:base/Text";

module {

  public type Uint8Array = Buffer.Buffer<Nat8>;

  type Result<T,E> = Result.Result<T, E>;

  public type Input = {
    #string : Text;
    #number: Nat;
    #Uint8Array : Uint8Array;
    #List: InputList;
    #Null;
    #Undefined;
  };

  type InputList = Buffer.Buffer<Input>;

  public type Decoded = {
    #Uint8Array: Uint8Array;
    #Nested: Buffer.Buffer<Decoded>;
  };


/**
 * RLP Encoding based on https://eth.wiki/en/fundamentals/rlp
 * This function takes in data, converts it to Buffer<Nat8> if not,
 * and adds a length for recursion.
 * @param input Will be converted to Buffer<Nat8>
 * @returns Buffer<Nat8> of encoded data
 **/
  public func encode(input: Input) : Result<Uint8Array,Text> {
    switch(input) {
      case(#List(item)) {
        let output = Buffer.Buffer<Nat8>(1);
        for(thisItem in item.vals()) {
          switch(encode(thisItem)) {
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
      };
      case(_){};
    };
    let inputBuf = switch(toBytes(input)) {
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

  // Slices a Buffer<Nat8>, throws if the slice goes out-of-bounds of the Uint8Array.
  // E.g. `safeSlice(hexToBytes("aa"), 1, 2)` will throw.
  // @param input
  // @param start
  // @param end

  public func safeSlice(input: Uint8Array, start: Nat, end: Nat) : Result<Uint8Array, Text> {
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
  public func decodeLength(v: Uint8Array): Result<Nat8, Text> {
    if (v.get(0) == 0 and v.get(1) == 0) {
      return #err("invalid RLP: extra zeros");
    };
    return switch(Hex.decode(Hex.encode(Buffer.toArray(v)))){
      case(#ok(val)){ #ok(val[0]) };
      case(#err(err)){ return #err("not a valid hex") }
    };
  };

  public func encodeLength(len: Nat, offset: Nat): Result<Uint8Array, Text> {
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

  /**
  * RLP Decoding based on https://eth.wiki/en/fundamentals/rlp
  * @param input Will be converted to Uint8Array
  * @param stream Is the input a stream (false by default)
  * @returns decoded Array of Uint8Arrays containing the original message
  **/
  public func decode(input: Input): Result<Decoded, Text> {
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
      case(_){};
    };

    let inputBytes = switch(toBytes(input)) {
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

  let threshold : Nat8 = 127; // 7f
  let threshold2 : Nat8 = 183; // b7
  let threshold3 : Nat8 = 247;// f7
 
  let threshold4 : Nat8 = 182; // b6
  let threshold5 : Nat8 = 191; // bf
  let nullbyte : Nat8 = 128; // 80


  type Output = {
    data : Decoded;
    remainder : Buffer.Buffer<Nat8>;
  };

  /** Decode an input with RLP */
  private func _decode(input: Uint8Array): Result<Output, Text> {
    
    var decoded = [];
    var firstByte = input.get(0);

    // a single byte whose value is in the [0x00, 0x7f] range, that byte is its own RLP encoding.
    if (firstByte <= threshold) {
      let inputSlice = switch(safeSlice(input, 0, 1)) {
          case(#ok(val)) { val };
          case(#err(val)) { return #err(val) };
        };
      let _remainder = if (input.size() > 2) {
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

  /** Transform an integer into its hexadecimal value */
  public func numberToHex(integer: Nat): Text {
    return(Hex.encode(natToBytes(integer)));
  };

  public func natToBytes(n : Nat) : [Nat8] { 
            
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

  /** Removes 0x from a given String */
  public func stripHexPrefix(str: Text): Text { 
    return if (isHexPrefixed(str))
        switch(Text.stripStart(str, #text("0x"))){
          case(null){ str };
          case(?val){ val }}
      else 
        str;
  };

  /** Transform anything into a Uint8Array */
  public func toBytes(v: Input): Result<Uint8Array, Text> {
    switch(v) {
      case(#Uint8Array(item)) {
        return #ok(item);
      };
      case(#string(item)) {
        if (isHexPrefixed(item)) {
          let result = switch(Hex.decode(padToEven(stripHexPrefix(item)))){
            case(#ok(val)){ val };
            case(#err(err)){ return #err("nat a valid hex") }};
          return #ok(toBuffer<Nat8>(result));
        };
        let str = Text.encodeUtf8(item);
        let buf = Buffer.fromArray<Nat8>(Blob.toArray(str));
        return #ok(buf);
      };
      case(#number(v)) {
        if(v == 0) {
          return #ok(Buffer.Buffer<Nat8>(0));
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

  private func toBuffer<T>(x :[T]) : Buffer.Buffer<T> {
    let thisBuffer = Buffer.Buffer<T>(x.size());
    for(thisItem in x.vals()) {
      thisBuffer.add(thisItem);
    };
    return thisBuffer;
  };
};