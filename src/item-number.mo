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

class NumberItem<T> (input: Nat): Visitor.Item<Nat, T> {

  public func getInput(): Nat {
    return input;
  };

  public func toBytes (): Result<Uint8Array, Text> { 
      if(input == 0) {
          return #ok(Buffer.Buffer<Nat8>(0));
         } else {
          let byteArray = natToBytes(input);
          return #ok(Buffer.fromArray(byteArray));
      }
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
    return visitor.visitNumber(NumberItem<T>(input), visitor);
  } 
};

