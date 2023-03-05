import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
  
type Result<T,E> = Result.Result<T, E>;
type Uint8Array = Buffer.Buffer<Nat8>;
type ItemBuffer = Buffer.Buffer<Item<Any, Any>>;

type Visitor<T> = {
  visitNumber: (numberItem: Item<Nat, T>, Visitor<T>) -> Result<T, Text>;
  visitString: (stringItem: Item<Text, T>, Visitor<T>) -> Result<T, Text>;
  visitList: (listItem: Item<Buffer.Buffer<Item<Any, T>>, T>, Visitor<T>) -> Result<T, Text>;
  visitUint8Array: (uint8ArrayItem: Item<Uint8Array, T>, Visitor<T>) -> Result<T, Text>;
};

type Item<T, K> = {
  getInput: () -> T;
  toBytes: () -> Result<Uint8Array, Text>;
  accept: (visitor: Visitor<K>) -> Result<K, Text>;
};

