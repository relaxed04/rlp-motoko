# RLP Motoko

A Motoko implementation of [Recursive Length Prefix](https://eth.wiki/en/fundamentals/rlp) (RLP).

## INSTALL

Add the following to your `package-set.dhall` file
```
{ name = "rlp"
, version = "master"
, repo = "https://github.com/relaxed04/rlp-motoko"
, dependencies = [] : List Text
}
```
Include it in your `vessel.dhall` file dependencies:
```
  dependencies = [ "base", "rlp" ],
```

## USAGE

```motoko
import RLP "mo:rlp";

let result = switch(RLP.encode(#string("dog"))) {
  case(#ok(val)) { val };
  case(#err(val)) { 
    // Do something with the error
   };
};

```

## API

Both Encode and Decode functions accept an `Input` type.  
Type definitions for inputs and outputs are located in the `/src/types` module.

## TESTS

Tests runner is: [testing](https://github.com/internet-computer/testing) 

To run tests, install [npm](https://nodejs.org/en/download/), and run:
```
npm run test
```
