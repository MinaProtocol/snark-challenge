type z = Zero

type 'a s = S of 'a

type ('a, 'n) t = [] : ('a, z) t | ( :: ) : 'a * ('a, 'n) t -> ('a, 'n s) t

type ('a, 'n) vec = ('a, 'n) t

module Ind (Acc : sig
  type (_, _) t
end) =
struct
  type 'a t = {f: 'n. ('a, 'n) Acc.t -> 'a -> ('a, 'n s) Acc.t}

  let rec right : type a n.
      (a, n) vec -> init:(a, z) Acc.t -> f:a t -> (a, n) Acc.t =
   fun t ~init ~f ->
    match t with
    | [] ->
        init
    | x :: xs ->
        let r = right xs ~init ~f in
        f.f r x
end

let length v =
  let module F = Ind (struct
    type (_, _) t = int
  end) in
  F.right ~init:0 ~f:{f= (fun acc _ -> acc + 1)} v

let to_list v =
  let module F = Ind (struct
    type ('a, _) t = 'a list
  end) in
  F.right ~init:[] ~f:{f= (fun xs x -> x :: xs)} v

let map (type a b) v ~(f : a -> b) =
  let module F = Ind (struct
    type (_, 'n) t = (b, 'n) vec
  end) in
  F.right ~init:[] ~f:{f= (fun ys x -> f x :: ys)} v
