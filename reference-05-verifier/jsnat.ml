open Core_kernel
open Js_of_ocaml

type t = < > Js.t

let of_int (n : int) : t =
  Js.Unsafe.global##BigInt n

let of_jsstring (s : Js.js_string Js.t) : t =
  Js.Unsafe.global##BigInt s

let of_string s = of_jsstring (Js.string s)

let equal =
  let f = Js.Unsafe.pure_js_expr "(function(x, y) { return x === y; })" in
  fun (x:t) (y:t) ->
    Js.Unsafe.(fun_call f [|inject x; inject y|])
    |> Js.to_bool

let shift_right = 
  let f =
    Js.Unsafe.pure_js_expr {js|function(x, n) {
      return x >> BigInt(n);
    }|js}
  in
  fun (x : t) ( n : int) ->
    Js.Unsafe.(fun_call f [|inject x; inject n|])

let shift_left = 
  let f =
    Js.Unsafe.pure_js_expr {js|function(x, n) {
      return x << BigInt(n);
    }|js}
  in
  fun (x : t) ( n : int) ->
    Js.Unsafe.(fun_call f [|inject x; inject n|])

let log_and =
  let f =
    Js.Unsafe.pure_js_expr {js|function(x, y) {
      return x & y;
    }|js}
  in
  fun (x : t) (y : t) ->
    Js.Unsafe.(fun_call f [|inject x; inject y|])

let log_or =
  let f =
    Js.Unsafe.pure_js_expr {js|function(x, y) {
      return x | y;
    }|js}
  in
  fun (x : t) (y : t) ->
    Js.Unsafe.(fun_call f [|inject x; inject y|])

let test_bit =
  let one = of_int 1 in
  fun t i ->
    equal
      (log_and one (shift_right t i))
      one

let ( < ) : t -> t -> bool =
  let f = Js.Unsafe.pure_js_expr {js|(function(x, y) { return x < y; })|js} in
  fun (x:t) (y:t) ->
    Js.Unsafe.(fun_call f [|inject x; inject y|])

let num_bits =
  let f =
    Js.Unsafe.pure_js_expr {js|function(x) {
      var zero = BigInt(0);
      x = x >= zero ? x : -x;
      var one = BigInt(1);
      var res = 0;
      while (x !== zero) {
        res += 1;
        x = x >> one;
        console.log('loop');
      }
      return res;
    }|js}
  in
  fun (x:t) : int ->
    Js.Unsafe.(fun_call f [| inject x |])

let to_bytes x =
  let n = num_bits x in
  let num_bytes = (n + 7) / 8 in
  String.init num_bytes ~f:(fun byte ->
      let c i =
        let bit = (8 * byte) + i in
        if test_bit x bit then 1 lsl i else 0
      in
      Char.of_int_exn
        (c 0 lor c 1 lor c 2 lor c 3 lor c 4 lor c 5 lor c 6 lor c 7) )

let of_bytes x =
  String.foldi x ~init:(of_int 0) ~f:(fun i acc c ->
      log_or acc (shift_left (of_int (Char.to_int c)) (8 * i)) )

let ( + ) : t -> t -> t =
  let f = Js.Unsafe.pure_js_expr {js|(function(x, y) { return x + y; })|js} in
  fun (x:t) (y:t) ->
    Js.Unsafe.(fun_call f [|inject x; inject y|])

let ( - ) : t -> t -> t =
  let f = Js.Unsafe.pure_js_expr {js|(function(x, y) { return x - y; })|js} in
  fun (x:t) (y:t) ->
    Js.Unsafe.(fun_call f [|inject x; inject y|])

let ( * ) : t -> t -> t =
  let f = Js.Unsafe.pure_js_expr {js|(function(x, y) { return x * y; })|js} in
  fun (x:t) (y:t) ->
    Js.Unsafe.(fun_call f [|inject x; inject y|])

let ( % ) : t -> t -> t =
  let f = Js.Unsafe.pure_js_expr {js|(function(x, y) { return x % y; })|js} in
  fun (x:t) (y:t) ->
    Js.Unsafe.(fun_call f [|inject x; inject y|])

let ( // ) : t -> t -> t =
  let f = Js.Unsafe.pure_js_expr {js|(function(x, y) { return x / y; })|js} in
  fun (x:t) (y:t) ->
    Js.Unsafe.(fun_call f [|inject x; inject y|])

let to_string x =
  Js.to_string (x##toString)

let to_string (t:t) = to_string (Js.Unsafe.coerce t)

let to_int_exn t = Int.of_string (to_string t)

let compare t1 t2 =
  if equal t1 t2
  then 0
  else if t1 < t2
  then -1
  else 1

module String_hum = struct
  type nonrec t = t

  let of_string = of_string

  let to_string = to_string
end

include Sexpable.Of_stringable (String_hum)

include (String_hum : Stringable.S with type t := t)

include Binable.Of_stringable (struct
  type nonrec t = t

  let of_string = of_bytes

  let to_string = to_bytes
end)
