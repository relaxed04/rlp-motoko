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

import EncodingVisitor "encoding-visitor";
import DecodingVisitor "decoding-visitor";
import NumberItem "item-number";
import StringItem "item-string";
import Uint8ArrayItem "item-uint8array";
import ListItem "item-list";
import Visitor "visitor";

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

  private func inputToComposite<T>(input: Input): Visitor.Item<Any, T> {
    switch(input) {
      case(#string(val)) { return StringItem.StringItem(val); };
      case(#number(val)) { return NumberItem.NumberItem(val); };
      case(#Uint8Array(val)) { return Uint8ArrayItem.Uint8ArrayItem(val); };
      case(#List(val)) {
        let output = Buffer.Buffer<Visitor.Item<Any, T>>(1);
        for(thisItem in val.vals()) {
          output.add(inputToComposite(thisItem));
        };
        return ListItem.ListItem(output);
      }
    };
  };

  public func encode(input: Input) : Result<Uint8Array,Text> {
    let composite = inputToComposite<Uint8Array>(input);
    let encoding = EncodingVisitor.EncodingVisitor();
    return composite.accept(encoding);
  };

  public func decode(input: Input) : Result<Decoded,Text> {
    let composite = inputToComposite<Decoded>(input);
    let decoding = DecodingVisitor.DecodingVisitor();
    return composite.accept(decoding);
  }
};
