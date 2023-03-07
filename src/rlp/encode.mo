import Buffer "mo:base/Buffer";
import Hex "../hex";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Result "mo:base/Result";
import Utils "utils";
import Types "../types";

module {
  type Result<T,E> = Result.Result<T, E>;

  public func encode(input: Types.Input) : Result<Types.Uint8Array,Text> {
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
    let inputBuf = switch(Utils.toBytes(input)) {
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

  private func encodeLength(len: Nat, offset: Nat): Result<Types.Uint8Array, Text> {
    if (len < 56) {
      return #ok(Buffer.fromArray([Nat8.fromNat(len) + Nat8.fromNat(offset)]));
    };
    let hexLength = Utils.numberToHex(len);
    let lLength = hexLength.size() / 2;
    let firstByte = Utils.numberToHex(offset + 55 + lLength);
    let result = switch(Hex.decode(firstByte # hexLength)){
      case(#ok(val)){ val };
      case(#err(err)){
        return #err("not a valid hex")
      }};
    let output = Utils.toBuffer<Nat8>(result);

    return #ok(output);
  };
}
