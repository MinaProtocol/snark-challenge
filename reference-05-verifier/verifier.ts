// This file requires the file crypto_lib.js to be loaded already!


/* This file contains specifications of the following functions
 * - `pedersenHash`
 * - `groupMap`
 * - `hashToGroup`
 *
 * These specifications are given as typescript code, assuming
 * implementations for field arithmetic mod q and mod r, where
 * q and r are as given here: https://coinlist.co/build/coda/pages/MNT6753
 */

type FqRepr = Uint32Array

type FrRepr = FqRepr

type FieldType<A> ={
  one : A,

  isZero: (x:A) => boolean,

  // Add two numbers mod q.
  equal : (x:A, y:A) => boolean,

  // Add two numbers mod q.
  add : (x:A, y:A) => A,

  // Subtract two numbers mod q.
  sub : (x:A, y:A) => A,

  // Negate a number mod q
  negate : (x:A) => A,

  // Multiply two numbers mod q.
  mul : (x:A, y:A) => A,

  // square(x) == mul(x, x)
  square : (x:A) => A,

  // Returns z such that mul(z, y) === x.
  div : (x:A, y:A) => A,

  // Read a big integer from a string.
  ofString: (x : String) => A,

  // Convert an int to an A element.
  ofInt: (x : number) => A,

  // returns true iff there is a y with mul(y, y) === x.
  isSquare: (x : A) => boolean,

  // returns y such that mul(y, y) === x if such a y exists.
  sqrt: (x : A) => A,

  // Convert the field element to an little-endian array of bits
  toBits: (x : A) => Array<boolean>,

  // Convert the field element to an little-endian array of bits
  ofBits: (x : Array<boolean>) => A,

  // Represented using 24 32-bit limbs.
  toLimbs : (x : A) => Uint32Array
}

abstract class FqT {
};
abstract class FrT {
};

type Bits = Array<boolean>

type Fq3 = {
  a : FqT,
  b : FqT,
  c : FqT,
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

type AffineG1 = AffinePoint<FqT>;
type JacobianG1 = JacobianPoint<FqT>;
type AffineG2 = AffinePoint<Fq3>;
type JacobianG2 = JacobianPoint<Fq3>;

abstract class G1Precomputation {};
abstract class G2Precomputation {};
type PairingObject = {
  g1Precompute : (JacobianG1) => G1Precomputation,
  g2Precompute : (JacobianG2) => G2Precomputation,
  millerLoop : (G1Precomputation, G2Precomputation) => Fq6,
  finalExponentiation : (Fq6) => Fq6
};

const g : any = (typeof window === 'undefined' ? eval('global') : window);

// The following are implemented in OCaml in crypto_lib.ml, not in JS
// - Fq arithmetic
// - Fq6 arithmetic
// - Fr arithmetic
// - The pairing
// - The blake2s hash function
const Fq : FieldType<FqT> = g['MNT6Fq'] as FieldType<FqT>;
const Fq6 : FieldType<Fq6> = g['MNT6Fq6'] as FieldType<Fq6>;
const Fr : FieldType<FrT> = g['MNT6Fr'] as FieldType<FrT>;
const Pairing : PairingObject = g['MNT6Pairing'] as PairingObject;
const blake2s : (Bits) => Bits = g['blake2s'];

function timesTwo(x : FqT) : FqT {
  return Fq.add(x, x);
}

function timesFour(x : FqT) : FqT {
  const xx = Fq.add(x, x);
  return Fq.add(xx, xx);
}

function timesThree(x : FqT) : FqT {
  return Fq.add(x, timesTwo(x));
}

function timesEight(x : FqT) : FqT {
  return timesTwo(timesFour(x));
}

// a = 11
const timesA = (x : FqT) : FqT => {
  const x2 = timesTwo(x);
  const x4 = timesTwo(x2);
  const x8 = timesTwo(x4);
  return Fq.add(x8, Fq.add(x2, x));
}

function G1IsIdentity(P : JacobianG1) {
  return Fq.isZero(P.z)
}

const G1 = {
  identity : { x: Fq.ofInt(1), y: Fq.ofInt(1), z: Fq.ofInt(0) },

  add : (P : JacobianG1, Q : JacobianG1) : JacobianG1 => {
    if (G1IsIdentity(P)) {
      return Q;
    }
    if (G1IsIdentity(Q)) {
      return P;
    }

    let X1 = P.x, Y1 = P.y, Z1 = P.z;
    let X2 = Q.x, Y2 = Q.y, Z2 = Q.z;

    let Z1Z1 = Fq.square(Z1);
    let Z2Z2 = Fq.square(Z2);
    let U1 = Fq.mul(X1, Z2Z2);
    let U2 = Fq.mul(X2, Z1Z1);
    let S1 = Fq.mul(Fq.mul(Y1, Z2), Z2Z2);
    let S2 = Fq.mul(Fq.mul(Y2, Z1), Z1Z1);
    let H = Fq.sub(U2, U1);
    let I = Fq.square(timesTwo(H));
    let J = Fq.mul(H, I);
    let r = timesTwo(Fq.sub(S2, S1));
    let V = Fq.mul(U1, I);
    let X3 = Fq.sub(Fq.sub(Fq.square(r), J), timesTwo(V));

    return {
      x : X3,
      y : Fq.sub(Fq.mul(r, Fq.sub(V, X3)), timesTwo(Fq.mul(S1, J))),
      z :  Fq.mul(Fq.sub(Fq.sub(Fq.square(Fq.add(Z1, Z2)), Z1Z1), Z2Z2), H)
    };
  },

  double : (P : JacobianG1) : JacobianG1 => {
    if (G1IsIdentity(P)) {
      return P;
    }
    let X1 = P.x, Y1 = P.y, Z1 = P.z;
    let XX = Fq.square(X1);
    let YY = Fq.square(Y1);
    let YYYY = Fq.square(YY);
    let ZZ = Fq.square(Z1);
    let S = timesTwo(Fq.sub(Fq.sub(Fq.square(Fq.add(X1,YY)), XX), YYYY));
    let M = Fq.add(timesThree(XX), timesA(Fq.square(ZZ)));
    let T = Fq.sub(Fq.square(M), timesTwo(S));
    let X3 = T;
    let Y3 = Fq.sub(Fq.mul(M, Fq.sub(S, T)), timesEight(YYYY));
    let Z3 = Fq.sub(Fq.sub(Fq.square(Fq.add(Y1,Z1)), YY), ZZ);
    return { x:X3, y:Y3, z:Z3 };
  },

  mixedAdd : (P : JacobianG1, Q : AffineG1) : JacobianG1 => {
    if (G1IsIdentity(P)) {
      return { x : Q.x, y : Q.y, z : Fq.ofInt(1) };
    }

    // Many of these can be done in place to save memory
    let X1 = P.x, Y1 = P.y, Z1 = P.z;
    let X2 = Q.x, Y2 = Q.y;
    let Z1Z1 = Fq.square(Z1);
    let U2 = Fq.mul(X2, Z1Z1);
    let S2 = Fq.mul(Fq.mul(Y2, Z1), Z1Z1);
    let H = Fq.sub(U2, X1);
    let HH = Fq.square(H);
    let I = timesFour(HH);
    let J = Fq.mul(H, I);
    let r = timesTwo(Fq.sub(S2, Y1));
    let V = Fq.mul(X1, I);
    let X3 = Fq.sub(Fq.sub(Fq.square(r), J), timesTwo(V));
    let Y3 = Fq.sub(Fq.mul(r, Fq.sub(V, X3)), timesTwo(Fq.mul(Y1, J)));
    let Z3 = Fq.sub(Fq.sub(Fq.square(Fq.add(Z1, H)), Z1Z1), HH);
    return { x : X3, y : Y3, z : Z3 };
  },

  ofAffine : (P : AffineG1) : JacobianG1 => {
    return { x : P.x, y : P.y, z : Fq.ofInt(1) };
  },

  toAffine : (P : JacobianG1) : AffineG1 => {
    const zSquared = Fq.mul(P.z, P.z);
    const zCubed = Fq.mul(zSquared, P.z);
    return {
      x: Fq.div(P.x, zSquared),
      y: Fq.div(P.y, zCubed),
    };
  }
};

const G2 = {
  ofAffine : (P : AffineG2) : JacobianG2 => {
    return {
      x: P.x,
      y: P.y,
      z: {a: Fq.ofInt(1), b: Fq.ofInt(0), c: Fq.ofInt(0) }
    };
  },
  one:  {
    z: {a: Fq.ofInt(1), b: Fq.ofInt(0), c: Fq.ofInt(0) }
  , x:
      { a: Fq.ofString(
          "46538297238006280434045879335349383221210789488441126073640895239023832290080310125413049878152095926176013036314720850781686614265244307536450228450615346834324267478485994670716807428718518299710702671895190475661871557310")
      , b: Fq.ofString(
          "10329739935427016564561842963551883445915701424214177782911128765230271790215029185795830999583638744119368571742929964793955375930677178544873424392910884024986348059137449389533744851691082159233065444766899262771358355816328")
      , c: Fq.ofString(
          "19962817058174334691864015232062671736353756221485896034072814261894530786568591431279230352444205682361463997175937973249929732063490256813101714586199642571344378012210374327764059557816647980334733538226843692316285591005879")
      }
  , y:
      { a: Fq.ofString(
          "5648166377754359996653513138027891970842739892107427747585228022871109585680076240624013411622970109911154113378703562803827053335040877618934773712021441101121297691389632155906182656254145368668854360318258860716497525179898")
      , b: Fq.ofString(
          "26817850356025045630477313828875808893994935265863280918207940412617168254772789578700316551065949899971937475487458539503514034928974530432009759562975983077355912050606509147904958229398389093697494174311832813615564256810453")
      , c: Fq.ofString(
          "32332319709358578441696731586704495581796858962594701633932927358040566210788542624963749336109940335257143899293177116050031684054348958813290781394131284657165540476824211295508498842102093219808642563477603392470909217611033")
      }
  }
};

/* Group map: This implements a function Fq -> AffineG1
 */
function groupMap(t : FqT) : AffineG1 {
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

const pedersenParameters : Array<AffineG1> = [
  ["2071893303198007985737678972190309212568452221625132024511988170095494148670997278812694070338313361389889122280160253462982652030041813566301365289695187505618174204273471887226695702458395861269694368663558765191107385382142", "17187187414417664367585796530257262302159176591062800465884265459977066325098901507827719965058588341044788483232395252403515861767227243983849894797683644816538861625368393588001624014759720661490214325432345769098675755344007"], 
  ["12212700530208157134689256057121042620633735483309261868159828729358269133353025097021648766749096328904625282610227267815597560656189994727627613599055093979638719153187781645363642530065802177696707603573183038198049837281284", "25783690089010390455572974279288664362239817189553105020262800542618336981545722940934884637537924384027963108482794866752096889610121505188228870561534980224779056104062778099246844511975082198175449341056361726557212816273203"], 
  ["24970556048065806436025775756019294569514287852390684813064321958272933228137795169157911036418821145649315804385644486444483724251269635399290126638401987231852781394516304251109918520031098349546899855265794613791318815401876", "31962426837049224740980485154381998358868991216693595616538747324158910634872015696123705432006307054685021215563881823301198025102710386453970240354239402398745821628720107919855566997584156778139135499881940592882629489943551"], 
  ["4431264411717549274439490659582560401278429696218324463252012866668010436230467390709079687847260266333949609702709398614735778908621392906775244210809408019439483728382538000678063011124654256466867465806472450156285959296478", "5357104929738581133630585435713154584790058687516758823722160588386982989576958329026493218285464648215758171648009368623425257221760769388865621253647844864279048734223948216626860899712215839882580351969504555475483295828321"], 
  ["6671433602972561813695090966408317709238420789110797829702834855105065892311048504872981038933746208133427345903147737968972400166128764694941204592973429712710593028851732935226387767696882706160253984317874861465334699161990", "21711555364470068355814107901005676801426239531219087510381972880175131973242407029290710493957974865954350244915332826635503654142837214217367474143450949577779528038476129095441904192715126325925180200706764720129647900154510"], 
  ["3279287280516667726034641228088153493377068947932964914992332109534304163378313362642088339811737854700479601646880961405137089274374094406319964129318466368217040667072259586616947873396338805588189680637610631077799406849678", "36083410532375699766897530133147718931585816209038495573380944607379201487163666226805598827634658263382384531791578426004569849840500849793075159834066479383773342040065664681946311465722831163353980052849824208445357276512039"], 
  ["6080315379067559396366920603391445316068884876999059159889161166465434118824372554207399274504146495157531657398487486565476348416859948241407968265138831613853730297645692192334843976583486101896736840413872097839964499683332", "26420424881408892228870218588074681761407815765852299070750308032078795079763335114222685666340147826454447640325063954005645285100365609355311780905109783862569185820306941334828547063301806152701392010289886220468661953965919"], 
  ["39301831400422949389818222554551556278076967824511010861535510094278551646323817962504510429949535607847124719220397592919414191667356795652722963307663320704947997484288198213588564623546419124090570040138115255574753268044296", "36457812814376230890682190373753614518702525324272794059443925877471853974877472140825740785996758245920724784158181335975363784020543877031746359325492875482739908200696955809723414504629601464266420637086159099075048645416374"], 
  ["7540664997550190973602360351030883142324749771399862809105176292300299526593722518355361727448429173635571954137685816627918496116227546648451982643232613412226512084475776533244886987139627138835739493051117039845249333293796", "41832168374796125531735699856185177965741887376998317172586340222379811256102274861246907652644659486244227261842256173112551393210515106271575307252302330588981902151799763241646966710905966859708456096352215232407040721812440"], 
  ["36397483455279521486180767892445054628947434149047678403043888842127539677645442740735471632069262625023630925482329096023950321390546066181899597320416634680062586092646310952310844092327312810134226425393239318043723435147242", "18286472905180979924646715322917829676123207845562357760879307637733164075896656550520464980631401874233327857749869297454439627725894967171722892001304897028600380951109713197296853450963512190698451016172641099337226932835103"], 
  ["38971740405150801303656120540964048311055428317597420804659853006910052152298169876746036294761470660390748610246706280407819428237389693394271333553585474382213782764591195401917422695201611402679319607462045083981820266292526", "12052300622245628070333354588755219239307478469529845235720526151711813563444656737524423919201679934065964579148677093493832843694922101898382470265577630638871822779691658559083989998504649770048646951871151837463810472588643"], 
  ["28580639909521896467730379621107007981713563598576419274286032656030060646413984885651670728423715399952200046109842062405825188571385283021073346904536651485834210457583868625103914909503900539953858010694440026958408821693616", "33074070963001755009804136607611008375296623364907104158069380168975081449307467755506733151497347867221785696657950398557975950305507047259982036542250828282873739093067701764175433149313198906930824052021363292166457216217373"], 
  ].map(([x, y]) => ({ x: Fq.ofString(x), y: Fq.ofString(y) }))

// Given an array [[s0, g0], [s1, g1], ...] return
// s0*g0 + s1*g1 + ...
// where * is scalar-multiplication and + is the G1 point addition/group operation.
function multiscale(xs : Array<[FrT, AffineG1]>) : JacobianG1 {
  const numBits = 753;
  const ys : Array<[Array<boolean>, AffineG1]> = xs.map(([s, g]) => [ Fr.toBits(s), g ]);

  let res = G1.identity;
  let foundOne = false;
  for (let i = numBits - 1; i >= 0; --i) {
    res = G1.double(res);

    ys.forEach(([s, g]) => {
      if (s[i]) {
        foundOne = true;
        res = G1.mixedAdd(res, g);
      }
    });
  }

  return res;
}

/* This code is a specification of the `pedersenHash` function.
 */
const pedersenHash = (() => {
  return (ts : Array<[boolean, boolean, boolean]>) : FqT => {
    const chunkSize = 188;

    const gRes = multiscale(
      chunk(ts, chunkSize)
        .map((c, i) =>  [ triplesToScalar(c), pedersenParameters[i] ]));

    return G1.toAffine(gRes).x;
  };

  // Multiplies a number by 16. Could probably be made more efficient by bitshifting.
  function timesSixteen(x : FrT) : FrT {
    const x2 = Fr.add(x, x);
    const x4 = Fr.add(x2, x2);
    const x8 = Fr.add(x4, x4);
    return Fr.add(x8, x8)
  }

  // in psedudocode, returns
  //
  // ts[0] * 16**0 + ts[1] * 16**1 + ts[2] * 16**2 + ... + ts[n-1] * 16**(n-1)
  function triplesToScalar(ts : Array<[boolean, boolean, boolean]>) : FrT {
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

      res = sign ? Fr.sub(res, term) : Fr.add(res, term);
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
}

type Proof = {
  a          : AffineG1,
  b          : AffineG2,
  c          : AffineG1,
  deltaPrime : AffineG2,
  z          : AffineG1,
};

type ExtendedProof = {
  a          : AffineG1,
  b          : AffineG2,
  c          : AffineG1,
  deltaPrime : AffineG2,
  z          : AffineG1,
  yS         : AffineG1,
};

type VerificationKey = {
  alphaBeta : Fq6,
  delta : AffineG2,
  query : Array<AffineG1>,
};

/* This function should check
  e(proof.a, proof.b)
  === proof.alphaBeta
      * e(G1.add(vk.query[0], G1.scale(input, vk.query[1])), G2.one)
      * e(proof.c, proof.deltaPrime)

  and

  e(proof.yS, deltaPrime) === e(proof.z, vk.delta)

  where e is the bilinear pairing on MNT6753 and where * is multiplication in
  Fq6.
*/
function verifierCore (
  vk : VerificationKey,
  input : FrT,
  proof : ExtendedProof
) : boolean {
  const deltaPrime = Pairing.g2Precompute(
    G2.ofAffine(proof.deltaPrime));

  const ab = Pairing.millerLoop(
    Pairing.g1Precompute(G1.ofAffine(proof.a)),
    Pairing.g2Precompute(G2.ofAffine(proof.b)));

  const acc = Pairing.millerLoop(
    Pairing.g1Precompute(
      G1.mixedAdd(
        multiscale([ [input, vk.query[1]] ]),
        vk.query[0])
    ),
    Pairing.g2Precompute(G2.ofAffine(G2.one))
  );

  const cDeltaPrime = Pairing.millerLoop(
    Pairing.g1Precompute(G1.ofAffine(proof.c)),
    deltaPrime);

  const res1 = Pairing.finalExponentiation(Fq6.div(ab, Fq6.mul(acc, cDeltaPrime)));
  if (! Fq6.equal(res1, vk.alphaBeta)) {
    return false;
  }

  const ySdeltaPrime = Pairing.millerLoop(
    Pairing.g1Precompute(G1.ofAffine(proof.yS)),
    deltaPrime);
  const zDelta = Pairing.millerLoop(
    Pairing.g1Precompute(G1.ofAffine(proof.z)),
    Pairing.g2Precompute(G2.ofAffine(vk.delta)));
  const res2 =
    Pairing.finalExponentiation(
      Fq.div(ySdeltaPrime, zDelta));
  if (! Fq6.equal(res2, Fq6.one)) {
    return false;
  }

  return true;
};

/* This is the full verifier function. If you implement this, no other
 * implementations will be used and this function will be called directly.
 */
function boweGabizonVerifier(
  vk : VerificationKey,
  input : FrT,
  proof : Proof
) : boolean {
  const eProof : ExtendedProof = {
    a: proof.a,
    b: proof.b,
    c: proof.c,
    deltaPrime: proof.deltaPrime,
    z : proof.z,
    yS: hashToGroup(proof.a, proof.b, proof.c, proof.deltaPrime)
  };

  return verifierCore(vk, input, eProof);
};

g['boweGabizonVerifier'] = boweGabizonVerifier;
g['hashToGroup'] = hashToGroup;
g['groupMap'] = groupMap;
g['pedersenHash'] = pedersenHash;
g['G1'] = G1;
g['multiscale'] = multiscale;
