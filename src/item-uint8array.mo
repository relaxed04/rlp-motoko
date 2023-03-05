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

class Uint8ArrayItem<T> (input: Uint8Array): Visitor.Item<Uint8Array, T> {

  public func getInput(): Uint8Array {
    return input;
  };

  public func toBytes (): Result<Uint8Array, Text> { 
      return #ok(getInput());
    };

  public func accept(visitor: Visitor.Visitor<T>): Result<T, Text> {
    return visitor.visitUint8Array(Uint8ArrayItem<T>(input), visitor);
  } 
};

