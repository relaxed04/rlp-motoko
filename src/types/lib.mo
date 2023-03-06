import Buffer "mo:base/Buffer";

module {
  public type Uint8Array = Buffer.Buffer<Nat8>;

  public type Input = {
    #string : Text;
    #number: Nat;
    #Uint8Array : Uint8Array;
    #List: InputList;
    #Null;
    #Undefined;
  };

  public type InputList = Buffer.Buffer<Input>;

  public type Decoded = {
    #Uint8Array: Uint8Array;
    #Nested: Buffer.Buffer<Decoded>;
  };
}

