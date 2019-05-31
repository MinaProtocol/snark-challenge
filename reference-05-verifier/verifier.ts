/* This file contains specifications of the following functions
 * - `pedersenHash`
 * - `groupMap`
 * - `hashToGroup`
 *
 * These specifications are given as typescript code, assuming
 * implementations for field arithmetic mod q and mod r, where
 * q and r are as given here: https://coinlist.co/build/coda/pages/MNT6753
 */

// Represented using 24 32-bit limbs.
type Fq = Uint32Array

// This represents a scalar, which happens to be the
// same size as Fq
type Fr = Fq

/* These are dummy functions which exists for explanatory purposes in
 * specifying the functions `pedersenHash` and `groupMap` below.
 */
const Fq = {
  // Add two numbers mod q.
  add : (x:Fq, y:Fq) : Fq => {
    throw 'not implemented'
  },

  // Subtract two numbers mod q.
  sub : (x:Fq, y:Fq) : Fq => {
    throw 'not implemented'
  },

  // Negate a number mod q
  negate : (x:Fq) : Fq => {
    throw 'not implemented'
  },


  // Multiply two numbers mod q.
  mul : (x:Fq, y:Fq) : Fq => {
    throw 'not implemented'
  },

  // square(x) == mul(x, x)
  square : (x:Fq) : Fq => {
    throw 'not implemented'
  },

  // Returns z such that mul(z, y) === x.
  div : (x:Fq, y:Fq) : Fq => {
    throw 'not implemented'
  },

  // Read a big integer from a string.
  ofString: (x : String) : Fq => {
    throw 'not implemented'
  },

  // Convert an int to an Fq element.
  ofInt: (x : number) : Fq => {
    throw 'not implemented'
  },

  // returns true iff there is a y with mul(y, y) === x.
  isSquare: (x : Fq) : boolean => {
    throw 'not implemented'
  },

  // returns y such that mul(y, y) === x if such a y exists.
  sqrt: (x : Fq) : Fq => {
    throw 'not implemented'
  },

  // Convert the field element to an little-endian array of bits
  toBits: (x : Fq) : Array<boolean> => {
    throw 'not implemented'
  },

  // Convert the field element to an little-endian array of bits
  ofBits: (x : Array<boolean>) : Fq => {
    throw 'not implemented'
  }
};

const Fr = {
  getBit: (x : Fr, i : number) => {
    const bitsPerLimb = 32;
    const j = Math.floor(i / 32);
    const k = i % 32;
    return ((x[j] >> k) & 1) === 1;
  },

  // Arithmetic mod r
  add : (x:Fr, y:Fr) : Fr => {
    throw 'not implemented'
  },

  sub : (x:Fr, y:Fr) : Fr => {
    throw 'not implemented'
  },

  ofInt: (x : number) : Fr => {
    throw 'not implemented'
  }
};

type Fq3 = {
  a : Fq,
  b : Fq,
  c : Fq,
};

type Fq6 = {
  a : Fq3,
  b : Fq3,
};

type AffinePoint<F> = {
  x : F,
  y : F,
};

type JacobianPoint<F> = {
  x : F,
  y : F,
  z : F,
};

type AffineG1 = AffinePoint<Fq>;
type JacobianG1 = JacobianPoint<Fq>;
type AffineG2 = AffinePoint<Fq3>;

const G1 = {
  identity : { x: Fq.ofInt(0), y: Fq.ofInt(0), z: Fq.ofInt(1) },

  add : (P : JacobianG1, Q : JacobianG1) : JacobianG1 => {
    throw 'not implemented';
  },

  double : (P : JacobianG1) : JacobianG1 => {
    throw 'not implemented';
  },

  mixedAdd : (P : JacobianG1, Q : AffineG1) : JacobianG1 => {
    throw 'not implemented';
  },

  toAffine : (P : JacobianG1) : AffineG1 => {
    const zSquared = Fq.mul(P.z, P.z);
    const zCubed = Fq.mul(zSquared, P.z);
    return {
      x: Fq.div(P.x, zSquared),
      y: Fq.div(P.x, zCubed),
    };
  }
};

/* Group map: This implements a function Fq -> AffineG1
 */
function groupMap(t : Fq) : AffineG1 {
  // Parameters defining the group-map.
  const u = Fq.ofInt(1);
  const a = Fq.ofString("11");
  const b = Fq.ofString("11625908999541321152027340224010374716841167701783584648338908235410859267060079819722747939267925389062611062156601938166010098747920378738927832658133625454260115409075816187555055859490253375704728027944315501122723426879114");

  // Derived constants. None of these have to be hardcoded
  const uOver2 = Fq.div(u, Fq.ofInt(2)); // Could be precomputed.

  // conicC === 3/4 * u^2 + a (all mod q)
  const conicC = Fq.ofString("10474622741979738350586053697810159282042677479988487267945875730256338203142776693264723440947584730354517742972114619330793264372898463767424060463699099041430354081337516110367604534461599617402983929764977041055196119040012");

  // z === sqrt(-(u^3 + a*u +b) - conicC)
  const projectionPoint = {
    z : Fq.ofString("38365735639699746381939366704915555468563774296792699496721397906733830428037078183799997086205833647489050605889539959322880863358082391473031143521765387671570958090617625358358885062894615919620647426481572278916894388596945"),
    y : Fq.ofInt(1)
  };

  // Actual computation begins.
  const ct = Fq.mul(conicC, t);
  const s = Fq.mul(
    Fq.ofInt(2),
    Fq.div(
      Fq.add(Fq.mul(ct, projectionPoint.y), projectionPoint.z),
      Fq.add(Fq.mul(ct, t), Fq.ofInt(1))));

  const z = Fq.sub(projectionPoint.z, s);
  const y = Fq.sub(projectionPoint.y, Fq.mul(s, t));

  const v = Fq.sub(Fq.div(z, y), uOver2);

  const potentialXs = [
    v,
    Fq.negate(Fq.add(u, v)), 
    Fq.add(u, Fq.square(y))
  ];

  for (let i = 0; i < potentialXs.length; ++i) {
    const x = potentialXs[i];
    const y2 = Fq.add(Fq.mul(x, Fq.square(x)), Fq.add(Fq.mul(a, x), b));
    // y2 is guaranteed to be square for at least one element of potentialXs.
    // We return on the first such element.
    if (Fq.isSquare(y2)) {
      return {
        x: x,
        y: Fq.sqrt(y2)
      };
    }
  }
}

function chunk<A>(xs : Array<A>, n : number) : Array<Array<A>> { 
  const res = [];

  let a = [];
  for (let i = 0; i < xs.length; ++i) {
    a.push(xs[i]);

    if (a.length === n || i === xs.length - 1) {
      res.push(a);
      a = [];
    }
  };

  return res;
}

/* This code is a specification of the `pedersenHash` function.
 */
const pedersenHash = (() => {
  const pedersenParameters : Array<AffineG1> = [
      [ "332637027557984585263317650500984572911029666110240270052776816409842001629441009391914692"
      , "256729384495629324506420372961192720918348265673564549794471951979904664963951714723671245"
      ]
    , [ "317636346738201844363072211531037005916212220880107581418751757742684937914450594188415214"
      , "34528004492629100771376637597612406651713499584905780489286194141574291240293310116415477"
      ]
    , [ "301993958032627472884437745615529438033253545721338569638490859186611357261503455475144560"
      , "146838269365541568898424192297459095856365681624642067425805412886771331230439469722095457"
      ]
    , [ "128129903535426931605566944870567299118257828089601530702537687963370272749913056019263948"
      , "241533714158383240264541770223151071469220576304583859791081751809254489361787785034789292"
      ]
    , [ "313740059656320278624446394988661572874903691784478118184415417081043868987379996532675000"
      , "100335334128845081242859700333050668946392262163243686493207843641156092956137855903739186"
      ]
    , [ "423183895593383061799561339264968652038340040714054275680700025954978728606721325061813986"
      , "313969101172182642564501383126895492652625186481651229385533160513306266107255895040965835"
      ]
    , [ "96515863600062668253667988564365773313561516965030035964759662895203654760595267751273022"
      , "74788359380435946369732993003083344506070059318176369841012459568171255289307688643768892"
      ]
    , [ "133805277542469035530250675647787997526131024301973452468057797508664393260190079584060932"
      , "473248979559415085339364815352614347743448895122993254491829858719453440371739397007461158"
      ]
    , [ "193145450621136862339560730801073269842002469065910956677832837218816947495711002260152576"
      , "16255012080098881505792406186591030441202762121828886745554048531238641365799402942870343"
      ]
    , [ "227178667986388803585115344621131283407798287495545402043280943015629427526751052148991114"
      , "475003404954778522592169245938178450555712839789630810550000761777308152460251354101521050"
      ]
    , [ "423133681764677277086792611137892122334228781032625093129146984124166840674465788309849992"
      , "365324352402801055309192141629343166814047966867902840699773790982764508051119135029931427"
      ]
  ].map(([x, y]) => ({ x: Fq.ofString(x), y: Fq.ofString(y) }))

  return (ts : Array<[boolean, boolean, boolean]>) : Fq => {
    const chunkSize = 188;

    const gRes = multiscale(
      chunk(ts, chunkSize)
        .map((c, i) =>  [ triplesToScalar(c), pedersenParameters[i] ]));

    return G1.toAffine(gRes).x;
  };

  // Multiplies a number by 16. Could probably be made more efficient by bitshifting.
  function timesSixteen(x : Fr) : Fr {
    const x2 = Fr.add(x, x);
    const x4 = Fr.add(x2, x2);
    const x8 = Fr.add(x4, x4);
    return Fr.add(x8, x8)
  }

  // Given an array [[s0, g0], [s1, g1], ...] return
  // s0*g0 + s1*g1 + ...
  // where * is scalar-multiplication and + is the G1 point addition/group operation.
  function multiscale(xs : Array<[Fr, AffineG1]>) : JacobianG1 {
    const numBits = 753;

    let res = G1.identity;
    for (let i = numBits - 1; i >= 0; --i) {
      res = G1.double(res);

      xs.forEach(([s, g]) => {
        if (Fr.getBit(s, i)) {
          res = G1.mixedAdd(res, g);
        }
      });
    }

    return res;
  }

  // in psedudocode, returns
  //
  // ts[0] * 16**0 + ts[1] * 16**1 + ts[2] * 16**2 + ... + ts[n-1] * 16**(n-1)
  function triplesToScalar(ts : Array<[boolean, boolean, boolean]>) : Fr {
    let res = Fr.ofInt(0);
    let sixteenToThei = Fr.ofInt(1);
    ts.forEach(([b0, b1, sign]) => {
      let term;
      if (!b1 && !b0) {
        term = sixteenToThei;
      } else if (!b1 && b0) {
        term = Fr.add(sixteenToThei, sixteenToThei);
      } else if (b1 && !b0) {
        term = Fr.add(sixteenToThei, Fr.add(sixteenToThei, sixteenToThei));
      } else if (b1 && b0) {
        const xx = Fr.add(sixteenToThei, sixteenToThei);
        term = Fr.add(xx, xx);
      }

      res = Fr.add(res, term);
      sixteenToThei = timesSixteen(sixteenToThei);
    });

    return res;
  };
})();

/* This is a specification for `hashToGroup`. As you can see, it depends on
 * `pedersenHash` and `groupMap`.
 */
function hashToGroup (
  a : AffineG1,
  b : AffineG2,
  c : AffineG1,
  deltaPrime : AffineG2
) : AffineG1 {
  return groupMap(
    Fq.ofBits(
      blake2s(
        Fq.toBits(
          pedersenHash(
            padToTriples(
              G1ToBits(a)
              .concat(G2ToBits(b))
              .concat(G1ToBits(c))
              .concat(G2ToBits(deltaPrime))))))));

  function G1ToBits({x, y} : AffineG1) : Array<boolean> {
    // Only need one bit of y
    return [ Fq.toBits(y)[0] ].concat(Fq.toBits(x));
  }

  function G2ToBits({x, y} : AffineG2) : Array<boolean> {
    const y0 = y.a;

    const xBits = [];
    [x.a, x.b, x.c].forEach((p) => Fq.toBits(p).forEach((b) => xBits.push(b)));

    // Only need one bit of y
    return [ Fq.toBits(y0)[0] ].concat(xBits);
  }

  function padToTriples(bits : Array<boolean>) : Array<[boolean, boolean, boolean]> {
    const r = bits.length % 3;

    bits = bits.slice();
    // Pad bits to be length a multiple of 3
    if (r !== 0) {
      const bitsNeeded = 3 - r;
      for (let i = 0; i < bitsNeeded; ++i) {
        bits.push(false);
      }
    }

    return chunk(bits, 3) as Array<[boolean, boolean, boolean]>;
  }

  // See here for spec: https://blake2.net/
  function blake2s (bits : Array<boolean>) : Array<boolean> {
    throw 'not implemented'
  }
}
