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

class ListItem<T> (input: Buffer.Buffer<Visitor.Item<Any, T>>): Visitor.Item<Buffer.Buffer<Visitor.Item<Any, T>>, T> {
  public func toBytes (): Result<Uint8Array, Text> { 
    return #ok(Buffer.Buffer<Nat8>(0));
  };

  public func getInput(): Buffer.Buffer<Visitor.Item<Any, T>> {
    return input;
  };

  public func accept(visitor: Visitor.Visitor<T>): Result<T, Text> {
    return visitor.visitList(ListItem<T>(input), visitor);
  } 
};

