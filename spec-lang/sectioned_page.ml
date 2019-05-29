open Core
open Util

type 'a section = {heading: string; body: 'a t}

and 'a item = Section of 'a section | Leaf of 'a

and 'a t = 'a item list

let rec map t ~f = List.map ~f:(map_item ~f) t

and map_item t ~f =
  match t with
  | Section {heading; body} ->
      Section {heading; body= map body ~f}
  | Leaf x ->
      Leaf (f x)

let rec render_item ~leaf ~section ~concat level = function
  | Leaf md ->
      leaf md
  | Section {heading; body} ->
      section ~level ~title:heading
        (render ~leaf ~section ~concat (level + 1) body)

and render ~leaf ~section ~concat level t =
  concat (List.map ~f:(render_item ~leaf ~section ~concat level) t)

let render_to_markdown t =
  render ~leaf:Fn.id 2 t ~concat:(String.concat ~sep:"\n\n")
    ~section:(fun ~level ~title body ->
      sprintf "%s %s\n\n%s" (String.init level ~f:(fun _ -> '#')) title body )

let title_to_id s =
  String.lowercase s |> String.map ~f:(fun c -> if c = ' ' then '-' else c)

let render_to_html t =
  let open Html in
  render ~leaf:Fn.id 2 t ~concat:List.concat
    ~section:(fun ~level ~title body ->
      [ node (sprintf "h%d" level)
          [Stationary.Attribute.create "id" (title_to_id title)]
          [text title] ]
      @ body )

let table_of_contents t =
  let rec go_t prefix t =
    List.filter_map t ~f:(function Section s -> Some s | Leaf _ -> None)
    |> List.concat_mapi ~f:(fun i sec ->
           let toc_text =
             let i = i + 1 in
             if prefix = "" then Int.to_string i else sprintf "%s.%d" prefix i
           in
           (toc_text, sec.heading) :: go_t toc_text sec.body )
  in
  let open Html in
  div
    [class_ "table-of-contents"]
    [ ul []
        (List.map (go_t "" t) ~f:(fun (s, title) ->
             li []
               [ a
                   [ksprintf href "#%s" (title_to_id title)]
                   [ksprintf text "%s: %s" s title] ] )) ]

let sec ~title body = Section {heading= title; body}

let leaf s = Leaf s

let text : string -> string item = leaf

let md fmt = ksprintf (fun s -> leaf (Markdown.of_string s)) fmt

let of_markdown =
  let header_string level =
    String.init level ~f:(fun _ -> '#') ^ " " 
  in
  let rec of_markdown level lines =
    let prefix = header_string level in
    List.group lines
      ~break:(fun _ x -> String.is_prefix x ~prefix)
    |> List.map ~f:(function
        | [] -> assert false
        | (x :: xs) as seclines ->
          match String.chop_prefix x ~prefix with 
          | None -> 
            (* This is a text section *)
            leaf (String.concat ~sep:"\n" seclines)
          | Some header ->
            sec ~title:(String.strip header)
              (of_markdown (level + 1) xs)
      )
  in
  Fn.compose (of_markdown 1) String.split_lines
