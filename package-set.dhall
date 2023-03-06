let base = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.8.2-20230217/package-set.dhall sha256:0a6f87bdacb4032f4b273d936225735ca4a0b0378de1f81e4bc4c6b4c5bad8a5
let baseEncodingCompatible = https://github.com/internet-computer/base-package-set/releases/download/moc-0.7.4/package-set.dhall sha256:3a20693fc597b96a8c7cf8645fda7a3534d13e5fbda28c00d01f0b7641efe494

let Package = { name : Text, version : Text, repo : Text, dependencies : List Text }

let additions = [
    { name = "array"
    , version = "v0.2.1"
    , repo = "https://github.com/aviate-labs/array.mo"
    , dependencies = [] : List Text
    },
    { name = "encoding" 
    , repo = "https://github.com/aviate-labs/encoding.mo"
    , version = "v0.4.1"
    , dependencies = [ "array" ]
  },
  { name = "testing"
    , version = "v0.1.1"
    , repo = "https://github.com/internet-computer/testing"
    , dependencies = [] : List Text
    }
] : List Package

in base # baseEncodingCompatible # additions 
