/** * Module : Hex.mo * Description : Hexadecimal encoding and decoding routines. * Copyright : 2020 Enzo Haussecker * License : Apache 2.0 with LLVM Exception * Maintainer : Enzo Haussecker * Stability : Stable */
// Module copied, fixed, and refactored from: https://internetcomputer.org/assets/files/hex-a1b74299525308f13cbad7f66a257944.mo
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Nat8 "mo:base/Nat8";
import Char "mo:base/Char";
import Result "mo:base/Result";
module {
  type Result<T,E> = Result.Result<T, E>;
  
  private let base : Nat8 = 0x10;
  private let symbols = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];

  private func toLower(c : Char) : Char {
    switch (c) {
        case ('A') { 'a' };
        case ('B') { 'b' };
        case ('C') { 'c' };
        case ('D') { 'd' };
        case ('E') { 'e' };
        case ('F') { 'f' };
        case (_)   { c;  };
    };
  };

   /** * Encode an array of unsigned 8-bit integers in hexadecimal format. */ 
  public func encode(array : [Nat8]) : Text {
    Array.foldLeft<Nat8, Text>(array, "", func(accum: Text, w8: Nat8) { accum # encodeW8(w8) });
  }; 
  
  /** * Encode an unsigned 8-bit integer in hexadecimal format. */ 
  public func encodeW8(w8 : Nat8) : Text {
    let c1 = symbols[Nat8.toNat(w8 / base)];
    let c2 = symbols[Nat8.toNat(w8 % base)];
    Char.toText(c1) # Char.toText(c2);
  }; 
  
  /** * Decode an array of unsigned 8-bit integers in hexadecimal format. */ 
  public func decode(text : Text) : Result<[Nat8], Text> {
    let next = text.chars().next;
    func parse() : Result<Nat8, Text> {
      Option.get (do ? { 
        let c1 = next()!; 
        let c2 = next()!; 
        Result.chain<Nat8, Nat8, Text>(decodeW4(c1), func(x1: Nat8) {
          Result.chain<Nat8, Nat8, Text>(decodeW4(c2), func(x2: Nat8) { 
            #ok(x1 * base + x2);
          });
        });
      }, #err("Not enough input!"));
    };
    var i = 0;
    let n = text.size() / 2 + text.size() % 2;
    let array = Array.init<Nat8>(n, 0);
    while (i != n) {
      switch (parse()) {
        case (#ok w8) { array[i] := w8; i += 1 };
        case (#err err) { return #err err };
      };
    };
    #ok(Array.freeze(array));
  }; 
  
  /** * Decode an unsigned 4-bit integer in hexadecimal format. */ 
  private func decodeW4(char : Char) : Result<Nat8, Text> {
    let lowerCaseChar = toLower(char);
    for (i in Iter.range(0, 15)) {
      let symbol = symbols[i];
      if (symbol == char or symbol == lowerCaseChar) { return #ok(Nat8.fromNat(i)) };
    };
    let str = "Unexpected character: " # Char.toText(char);
    #err(str);
  };
};
