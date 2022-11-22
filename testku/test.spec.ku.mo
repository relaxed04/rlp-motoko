import D "mo:base/Debug"
import Iter "mo:base/Iter"
import M "mo:matchers/Matchers"
import Nat64 "mo:base/Nat64"
import Option "mo:base/Option"
import Principal "mo:base/Principal"
import Result "mo:base/Result"
import S "mo:matchers/Suite"
import T "mo:matchers/Testable"
import Time "mo:base/Time"
import Types "../origyn_nft_reference/types"
import RLP "../src/lib"
import Conversions "mo:candy_0_1_10/Conversion"
import Hex "mo:encoding/Hex"

shared (deployer) actor class test_runner(dfx_ledger: Principal, dfx_ledger2: Principal)
  let it = C.Tester({ batchSize = 8 })

  public shared func test(canister_factory : Principal, storage_factory: Principal) : async {#success; #fail : Text} {
    

    // The tests below are taken from Geth
    // https://github.com/ethereum/go-ethereum/blob/99be62a9b16fd7b3d1e2e17f1e571d3bef34f122/rlp/decode_test.go

    let rlbtests = [
      S.test("emptystring", RLP.encode( ""), M.equals<Blob>(T.blob("0x80")))
      S.test("bytestring00", RLP.encode( "\u{0000}"), M.equals<Blob>(T.blob("0x00")))
      S.test("bytestring01", RLP.encode( "\u{0001}"), M.equals<Blob>(T.blob("0x01")))
      S.test("bytestring7F", RLP.encode( "\u{007F}"), M.equals<Blob>(T.blob("0x7f")))
      S.test("shortstring", RLP.encode( "dog"), M.equals<Blob>(T.blob("0x83646f67")))
      S.test("shortstring2", RLP.encode( "Lorem ipsum dolor sit amet, consectetur adipisicing eli"), M.equals<Blob>(T.blob("0xb74c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e7365637465747572206164697069736963696e6720656c69")))
      S.test("longstring", RLP.encode( "Lorem ipsum dolor sit amet, consectetur adipisicing elit"), M.equals<Blob>(T.blob("0xb8384c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e7365637465747572206164697069736963696e6720656c6974")))
      S.test("longstring2", RLP.encode( "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur mauris magna, suscipit sed vehicula non, iaculis faucibus tortor. Proin suscipit ultricies malesuada. Duis tortor elit, dictum quis tristique eu, ultrices at risus. Morbi a est imperdiet mi ullamcorper aliquet suscipit nec lorem. Aenean quis leo mollis, vulputate elit varius, consequat enim. Nulla ultrices turpis justo, et posuere urna consectetur nec. Proin non convallis metus. Donec tempor ipsum in mauris congue sollicitudin. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Suspendisse convallis sem vel massa faucibus, eget lacinia lacus tempor. Nulla quis ultricies purus. Proin auctor rhoncus nibh condimentum mollis. Aliquam consequat enim at metus luctus, a eleifend purus egestas. Curabitur at nibh metus. Nam bibendum, neque at auctor tristique, lorem libero aliquet arcu, non interdum tellus lectus sit amet eros. Cras rhoncus, metus ac ornare cursus, dolor justo ultrices metus, at ullamcorper volutpat"), M.equals<Blob>(T.blob("0xb904004c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e73656374657475722061646970697363696e6720656c69742e20437572616269747572206d6175726973206d61676e612c20737573636970697420736564207665686963756c61206e6f6e2c20696163756c697320666175636962757320746f72746f722e2050726f696e20737573636970697420756c74726963696573206d616c6573756164612e204475697320746f72746f7220656c69742c2064696374756d2071756973207472697374697175652065752c20756c7472696365732061742072697375732e204d6f72626920612065737420696d70657264696574206d6920756c6c616d636f7270657220616c6971756574207375736369706974206e6563206c6f72656d2e2041656e65616e2071756973206c656f206d6f6c6c69732c2076756c70757461746520656c6974207661726975732c20636f6e73657175617420656e696d2e204e756c6c6120756c74726963657320747572706973206a7573746f2c20657420706f73756572652075726e6120636f6e7365637465747572206e65632e2050726f696e206e6f6e20636f6e76616c6c6973206d657475732e20446f6e65632074656d706f7220697073756d20696e206d617572697320636f6e67756520736f6c6c696369747564696e2e20566573746962756c756d20616e746520697073756d207072696d697320696e206661756369627573206f726369206c756374757320657420756c74726963657320706f737565726520637562696c69612043757261653b2053757370656e646973736520636f6e76616c6c69732073656d2076656c206d617373612066617563696275732c2065676574206c6163696e6961206c616375732074656d706f722e204e756c6c61207175697320756c747269636965732070757275732e2050726f696e20617563746f722072686f6e637573206e69626820636f6e64696d656e74756d206d6f6c6c69732e20416c697175616d20636f6e73657175617420656e696d206174206d65747573206c75637475732c206120656c656966656e6420707572757320656765737461732e20437572616269747572206174206e696268206d657475732e204e616d20626962656e64756d2c206e6571756520617420617563746f72207472697374697175652c206c6f72656d206c696265726f20616c697175657420617263752c206e6f6e20696e74657264756d2074656c6c7573206c65637475732073697420616d65742065726f732e20437261732072686f6e6375732c206d65747573206163206f726e617265206375727375732c20646f6c6f72206a7573746f20756c747269636573206d657475732c20617420756c6c616d636f7270657220766f6c7574706174")))
      S.test("zero", RLP.encode( 0), M.equals<Blob>(T.blob("0x80")))
      S.test("smallint", RLP.encode( 1), M.equals<Blob>(T.blob("0x01")))
      S.test("smallint2", RLP.encode( 16), M.equals<Blob>(T.blob("0x10")))
      S.test("smallint3", RLP.encode( 79), M.equals<Blob>(T.blob("0x4f")))
      S.test("smallint4", RLP.encode( 127), M.equals<Blob>(T.blob("0x7f")))
      S.test("mediumint1", RLP.encode( 128), M.equals<Blob>(T.blob("0x8180")))
      S.test("mediumint2", RLP.encode( 1000), M.equals<Blob>(T.blob("0x8203e8")))
      S.test("mediumint3", RLP.encode( 100000), M.equals<Blob>(T.blob("0x830186a0")))
      S.test("mediumint4", RLP.encode( "#83729609699884896815286331701780722"), M.equals<Blob>(T.blob("0x8f102030405060708090a0b0c0d0e0f2")))
      S.test("mediumint5", RLP.encode( "#105315505618206987246253880190783558935785933862974822347068935681"), M.equals<Blob>(T.blob("0x9c0100020003000400050006000700080009000a000b000c000d000e01")))
      S.test("emptylist", RLP.encode( []), M.equals<Blob>(T.blob("0xc0")))
      S.test("stringlist", RLP.encode( ["dog", "god", "cat"]), M.equals<Blob>(T.blob("0xcc83646f6783676f6483636174")))
      S.test("multilist", RLP.encode( ["zw", [4], 1]), M.equals<Blob>(T.blob("0xc6827a77c10401")))
      S.test("shortListMax1", RLP.encode( [
        "asdf",
        "qwer",
        "zxcv",
        "asdf",
        "qwer",
        "zxcv",
        "asdf",
        "qwer",
        "zxcv",
        "asdf",
        "qwer"
      ]), M.equals<Blob>(T.blob("0xf784617364668471776572847a78637684617364668471776572847a78637684617364668471776572847a78637684617364668471776572")))
      S.test("longList1", RLP.encode( [
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"]
      ]), M.equals<Blob>(T.blob("0xf840cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376")))
      S.test("longList2", RLP.encode( [
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"],
        ["asdf", "qwer", "zxcv"]
      ]), M.equals<Blob>(T.blob("0xf90200cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376")))
      S.test("listsoflists", RLP.encode( [[[], []], []]), M.equals<Blob>(T.blob("0xc4c2c0c0c0")))
      S.test("listsoflists2", RLP.encode( [[], [[]], [[], [[]]]]), M.equals<Blob>(T.blob("0xc7c0c1c0c3c0c1c0")))
      S.test("dictTest1", RLP.encode( [
        ["key1", "val1"],
        ["key2", "val2"],
        ["key3", "val3"],
        ["key4", "val4"]
      ]), M.equals<Blob>(T.blob("0xecca846b6579318476616c31ca846b6579328476616c32ca846b6579338476616c33ca846b6579348476616c34")))
      S.test("bigint", RLP.encode( "#115792089237316195423570985008687907853269984665640564039457584007913129639936"), M.equals<Blob>(T.blob("0xa1010000000000000000000000000000000000000000000000000000000000000000")))
    ]

    let suite = S.suite("test rlp", rlbtests)

    S.run(suite)

    return #success
  }


// The tests below are taken from Geth
// https://github.com/ethereum/go-ethereum/blob/99be62a9b16fd7b3d1e2e17f1e571d3bef34f122/rlp/decode_test.go


const gethCases = [
  S.test("decode", RLP.decode("0x05"), M.equals<Blob>(T.blob("0x05")))
  S.test("decode", RLP.decode("0x80"), M.equals<Blob>(T.blob("0x")))
  S.test("decode", RLP.decode("0x01"), M.equals<Blob>(T.blob("0x01")))
  S.test("decode", RLP.decode("0x820505"), M.equals<Blob>(T.blob("0x0505")))
  S.test("decode", RLP.decode("0x83050505"), M.equals<Blob>(T.blob("0x050505")))
  S.test("decode", RLP.decode("0x8405050505"), M.equals<Blob>(T.blob("0x05050505")))
  S.test("decode", RLP.decode("0x850505050505"), M.equals<Blob>(T.blob("0x0505050505")))
  S.test("decode", RLP.decode("0xC0"), value: [])
  S.test("decode", RLP.decode("0x00"), M.equals<Blob>(T.blob("0x00")))
  S.test("decode", RLP.decode("0x820004"), M.equals<Blob>(T.blob("0x0004")))
  S.test("decode", RLP.decode("0xC80102030405060708"), value: ["01", "02", "03", "04", "05", "06", "07", "08"])
  S.test("decode", RLP.decode("0xC50102030405"), value: ["01", "02", "03", "04", "05"])
  S.test("decode", RLP.decode("0xC102"), value: ["02"])
  S.test("decode", RLP.decode("0x8D6162636465666768696A6B6C6D"), M.equals<Blob>(T.blob("0x6162636465666768696a6b6c6d")))
  S.test("decode", RLP.decode("0x86010203040506"), M.equals<Blob>(T.blob("0x010203040506")))
  S.test("decode", RLP.decode("0x89FFFFFFFFFFFFFFFFFF"), M.equals<Blob>(T.blob("0xffffffffffffffffff")))
  S.test("decode", RLP.decode("0xB848FFFFFFFFFFFFFFFFF800000000000000001BFFFFFFFFFFFFFFFFC8000000000000000045FFFFFFFFFFFFFFFFC800000000000000001BFFFFFFFFFFFFFFFFF8000000000000000001"), "0xfffffffffffffffff800000000000000001bffffffffffffffffc8000000000000000045ffffffffffffffffc800000000000000001bfffffffffffffffff8000000000000000001")))
  S.test("decode", RLP.decode("0x10"), M.equals<Blob>(T.blob("0x10")))
  S.test("decode", RLP.decode("0x820001"), M.equals<Blob>(T.blob("0x0001")))
  S.test("decode", RLP.decode("0xC50583343434"),  ["05", "343434"])
  S.test("decode", RLP.decode("0xC601C402C203C0"),  ["01", ["02", ["03", []]]])
  S.test("decode", RLP.decode("0xC58083343434"),  ["", "343434"])
  S.test("decode", RLP.decode("0xC105"),  ["05"])
  S.test("decode", RLP.decode("0xC7C50583343434C0"),  [["05", "343434"], []])
  S.test("decode", RLP.decode("0x83222222"),  "222222")
  S.test("decode", RLP.decode("0xC3010101"),  ["01", "01", "01"])
  S.test("decode", RLP.decode("0xC501C3C00000"),  ["01", [[], "00", "00"]])
  S.test("decode", RLP.decode("0xC103"),  ["03"])
  S.test("decode", RLP.decode("0xC50102C20102"),  ["01", "02", ["01", "02"]])
  S.test("decode", RLP.decode("0xC3010203"),  ["01", "02", "03"])
  S.test("decode", RLP.decode("0xC20102"),  ["01", "02"])
  S.test("decode", RLP.decode("0xC101"),  ["01"])
  S.test("decode", RLP.decode("0xC180"),  [""])
  S.test("decode", RLP.decode("0xC1C0"),  [[]])
  S.test("decode", RLP.decode("0xC103"),  ["03"])
  S.test("decode", RLP.decode("C2C103"),  [["03"]])
  S.test("decode", RLP.decode("0xC20102"),  ["01", "02"])
  S.test("decode", RLP.decode("0xC3010203"),  ["01", "02", "03"])
  S.test("decode", RLP.decode("0xC401020304"),  ["01", "02", "03", "04"])
  S.test("decode", RLP.decode("0xC20180"),  ["01", ""])
  S.test("decode", RLP.decode("0xC50183010203"),  ["01", "010203"])
  S.test("decode", RLP.decode("0x82FFFF"), M.equals<Blob>(T.blob("0xffff")))
  S.test("decode", RLP.decode("0x07"), M.equals<Blob>(T.blob("0x07")))
  S.test("decode", RLP.decode("0x8180"), M.equals<Blob>(T.blob("0x80")))
  S.test("decode", RLP.decode("0xC109"), value: ["09"])
  S.test("decode", RLP.decode("0xC58403030303"), value: ["03030303"] )
  S.test("decode", RLP.decode("0xC3808005"), value: ["", "", "05"])
  S.test("decode", RLP.decode("0xC50183040404"), value: ["01", "040404"])
]

function arrToStringArr(arr: any): any {
  return arr.map((a: any) => {
    if (Array.isArray(a)) {
      return arrToStringArr(a)
    }
    return bytesToHex(a)
  })
}

describe("geth tests", function () {
  for (const gethCase of gethCases) {
    const input = hexToBytes(gethCase.input)
    it("should pass Geth test", function (done) {
      try {
        const output = RLP.decode(input)
        if (Array.isArray(output)) {
          const arrayOutput = arrToStringArr(output)
          assert.strictEqual(
            JSON.stringify(arrayOutput),
            JSON.stringify(gethCase.value!),
            `invalid output: ${gethCase.input}`
          )
        } else {
          assert.strictEqual(
            bytesToHex(Uint8Array.from(output as any)),
            gethCase.value,
            `invalid output: ${gethCase.input}`
          )
        }
      } catch (e) {
        assert.fail(`should not throw: ${gethCase.input}`)
      } finally {
        done()
      }
    })
  }
})