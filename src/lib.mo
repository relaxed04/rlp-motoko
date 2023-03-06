import RLPEncode "rlp/encode";
import RLPDecode "rlp/decode";
import Types "types";
import Result "mo:base/Result";

module {
  type Result<T,E> = Result.Result<T, E>;

  public func encode(input: Types.Input): Result<Types.Uint8Array,Text> {
    return RLPEncode.encode(input);
  };

  public func decode(input: Types.Input): Result<Types.Decoded, Text> {
    return RLPDecode.decode(input);
  };
}