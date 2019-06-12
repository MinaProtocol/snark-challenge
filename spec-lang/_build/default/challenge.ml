open Core
open Util

type t =
  { name: string
  ; url: string
  ; dollars: int
  ; per_person: bool
  ; sub_challenges: t list }

let challenge name ?(per_person = false) ?url ~short ~dollars sub_challenges =
  let url =
    match url with Some u -> u | None -> sprintf "%s/%s.html" base_url short
  in
  {per_person; name; url; dollars; sub_challenges}

let problem (p : Problem.t) ~url =
  { name= p.title
  ; url
  ; dollars= Prize.dollar_amount p.quick_details.prize
  ; sub_challenges= []
  ; per_person= true }

let rec render =
  let indent s =
    String.split_lines s |> List.map ~f:(sprintf "    %s") |> unlines
  in
  fun {per_person; sub_challenges; name; dollars; url} ->
    let name =
      if List.is_empty sub_challenges then sprintf "[%s](%s)" name url
      else name
    in
    let prizes =
      if dollars = 0 then
        "**This challenge has ended, but please read the page for more info \
         as the [solution](https://github.com/codaprotocol/cuda-fixnum) has \
         been released and will be useful in the other challenges.**"
      else
        sprintf "**$%s in prizes%s**"
          (Int.to_string_hum ~delimiter:',' dollars)
          (if per_person then " for each of the first 10 participants" else "")
    in
    sprintf "- %s: %s\n%s" name prizes
      ( List.map sub_challenges ~f:(fun t ->
            let s = indent (render t) in
            s )
      |> unlines )
