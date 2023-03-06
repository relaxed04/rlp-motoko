import Buffer "mo:base/Buffer";

type Uint8Array = Buffer.Buffer<Nat8>;

type Input = {
  #string : Text;
  #number: Nat;
  #Uint8Array : Uint8Array;
  #List: InputList;
  #Null;
  #Undefined;
};

type InputList = Buffer.Buffer<Input>;

type Decoded = {
  #Uint8Array: Uint8Array;
  #Nested: Buffer.Buffer<Decoded>;
};
