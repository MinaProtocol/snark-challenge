open Core
module Html = Html_concise

module Parameter_kind = struct
  type t = Batch_parameter | Input | Output
end

module Quick_details = struct
  type t = {description: Markdown.t; prize: Prize.t}

  let render {description; prize} =
    let open Sectioned_page in
    sec ~title:"Quick details"
      [ leaf
          (ksprintf Markdown.of_string
             !{md|- **Problem:** %{Markdown}
- **Prize:**
%s|md}
             description
             ( List.map prize ~f:(fun (p, r) ->
                   sprintf
                     !"    - **%{Prize.Participant_set}:** %{Prize.Reward}"
                     p r )
             |> String.concat ~sep:"\n" )) ]
end

module Interface = struct
  module F = struct
    type 'a t =
      | Declare of
          Parameter_kind.t * string * Type.t * Html.t option * (Name.t -> 'a)
      | Choose_definitional_parameter :
          ((Type.t, 'n) Vec.t * string) list
          * (string, 'n) Vec.t
          * ((Name.t, 'n) Vec.t -> 'a)
          -> 'a t

    let map t ~f =
      match t with
      | Choose_definitional_parameter (xs, names, k) ->
          Choose_definitional_parameter (xs, names, fun x -> f (k x))
      | Declare (p, s, t, note, k) ->
          Declare (p, s, t, note, fun n -> f (k n))
  end

  include Free_monad.Make (F)

  let ( ! ) ?note p s t = Free (Declare (p, s, t, note, return))

  let def names ts = Free (Choose_definitional_parameter (ts, names, return))

  module Spec = struct
    type ('a, 'n) spec =
      { definitional_parameters:
          (string, 'n) Vec.t * ((Type.t, 'n) Vec.t * string) list
      ; batch_parameters: (string * Type.t * Html.t option) list
      ; input: (string * Type.t * Html.t option) list
      ; output: (string * Type.t * Html.t option) list
      ; description: 'a }
    [@@deriving fields]

    let field = function
      | Parameter_kind.Batch_parameter ->
          Fields_of_spec.batch_parameters
      | Input ->
          Fields_of_spec.input
      | Output ->
          Fields_of_spec.output

    type 'a t = T : ('a, 'n) spec -> 'a t

    let has_batch_parameters (T t) = not (List.is_empty t.batch_parameters)

    let update s pk ~f =
      let field = field pk in
      Field.fset field s (f (Field.get field s))

    let create ~name:_ m =
      cata
        (map m ~f:(fun description ->
             T
               { description
               ; definitional_parameters= ([], [])
               ; batch_parameters= []
               ; input= []
               ; output= [] } ))
        ~f:(function
          | Declare (pk, s, t, note, k) ->
              let (T spec) = k (Name.local s) in
              T (update spec pk ~f:(fun xs -> (s, t, note) :: xs))
          | Choose_definitional_parameter (choices, names, k) ->
              let (T spec) = k (Vec.map names ~f:(fun s -> Name.local s)) in
              T {spec with definitional_parameters= (names, choices)} )

    let render
        (T
          { description
          ; definitional_parameters
          ; batch_parameters
          ; input
          ; output }) =
      let definitional_preamble =
        let names, choices = definitional_parameters in
        match choices with
        | [] ->
            ""
        | _ ->
            let bindings =
              ( (if Vec.length names > 1 then ["("] else [])
              @ List.intersperse ~sep:", "
                  (List.map (Vec.to_list names) ~f:(fun name ->
                       Name.render_declaration name |> Html.to_string ))
              @ if Vec.length names > 1 then [")"] else [] )
              |> String.concat
            in
            let choices =
              List.map choices ~f:(fun (choice, name) ->
                  let with_params = Vec.length choice > 1 in
                  String.concat
                    (List.map (Vec.to_list choice)
                       ~f:(Fn.compose Html.to_string Type.render))
                    ~sep:", "
                  |> (if with_params then sprintf "(%s)" else Fn.id)
                  |> sprintf "- `%s`: %s" name )
              |> String.concat ~sep:"\n"
            in
            sprintf
              {md|The following problem is defined for any choice of %s
in

%s

You can click on the above types to see how they will be
represented in the files given to your program. `uint64`
values are represented in little-endian byte order. Arrays
are represented as sequences of values, with no length
prefix and no separators between elements. Structs are also
represented this way.|md}
              bindings choices
        (*
            [ span []
            ; ul []
                (List.map choices ~f:(fun choice ->
                     li []
                       (List.intersperse
                          (List.map (Vec.to_list choice) ~f:Type.render)
                          ~sep:(text ", ")) ))
            ; markdown
                "You can click on the above types to see how they will be \
                 represented in the files given to your program. `uint64` \
                 values are represented in little-endian byte order. Arrays \
                 are represented as sequences of values, with no length \
                 prefix and no separators between elements. Structs are also \
                 represented this way." ]
*)
      in
      let params ?desc ~title xs =
        let open Sectioned_page in
        sec ~title
          ( Option.(to_list (map desc ~f:(fun d -> leaf d)))
          @ [ List.map xs ~f:(fun (ident, ty, note) ->
                  sprintf !{md|- %s : %{Html}|md} ident (Type.render ty)
                  ^ Option.value_map note ~default:""
                      ~f:(sprintf !"\n    %{Html}") )
              |> String.concat ~sep:"\n" |> Markdown.of_string |> leaf ] )
        (*

          ]
          @ [ [ ul [class_ "value-list"]
                  (List.map xs ~f:(fun (ident, ty, note) ->
                       li []
                         ( [ div []
                               [ span [class_ "identifier"] [Html.text ident]
                               ; Html.text ":"
                               ; span [class_ "type"] [Type.render ty] ] ]
                         @ Option.to_list
                             (Option.map note ~f:(fun note ->
                                  div [class_ "note"] [note] ))
                         @ [div [class_ "representation"] []] ) )) ]
              |> leaf ] )
*)
        (*
        div
          [ class_ "parameters"
          ; Stationary.Attribute.create "id" (String.lowercase title) ]
          ( [h2 [] [text title]]
          @ Option.to_list desc
          @ [ ul [class_ "value-list"]
                (List.map xs ~f:(fun (ident, ty, note) ->
                     li []
                       ( [ div []
                             [ span [class_ "identifier"] [text ident]
                             ; text ":"
                             ; span [class_ "type"] [Type.render ty] ] ]
                       @ Option.to_list
                           (Option.map note ~f:(fun note ->
                                div [class_ "note"] [note] ))
                       @ [div [class_ "representation"] []] ) )) ] )
*)
      in
      let batch_parameters =
        if List.is_empty batch_parameters then []
        else
          [ params ~title:"Parameters"
              ~desc:
                (Markdown.of_string
                   "The parameters will be generated once and your submission \
                    will be allowed to preprocess them in any way you like \
                    before being invoked on multiple inputs.")
              batch_parameters ]
      in
      let input = params ~title:"Input" input in
      let output = params ~title:"Output" output in
      let open Sectioned_page in
      sec ~title:"Problem specification"
        ( [leaf (Markdown.of_string definitional_preamble)]
        @ batch_parameters
        @ [input; output; sec ~title:"Expected behavior" [leaf description]] )

    (*
      div [class_ "problem"]
        ( [h2 [] [text "Problem specification"]]
          @ definitional_preamble
          @ batch_parameters
          @ [input; output; description] )
*)
  end
end

module Reference_implementation = struct
  type t = {repo: string; main: string; core: string}
end

type t =
  { title: string
  ; quick_details: Quick_details.t
  ; preamble: Pages.t -> Markdown.t Sectioned_page.t
  ; interface: Markdown.t Interface.t
  ; postamble: Pages.t -> Markdown.t Sectioned_page.t
  ; reference_implementation: Reference_implementation.t }

let slug t =
  String.map (String.lowercase t.title) ~f:(fun c -> if c = ' ' then '-' else c)

let render ~pages
    { title
    ; quick_details
    ; preamble
    ; interface
    ; postamble
    ; reference_implementation } =
  let spec = Interface.Spec.create ~name:title interface in
  let param_set_names =
    let (Interface.Spec.T spec) = spec in
    spec.Interface.Spec.definitional_parameters |> snd |> List.map ~f:snd
  in
  let batch_params_description =
    sprintf
      {md|
0. The submission-runner will randomly generate the parameters and save them to
    files %s.
0. Your binary `main` will be run with 

    ```bash
        %s
    ```
    where `PATH_TO_X_PARAMETERS` will be replaced by the actual path.

    Your binary can at this point, if you like, do some preprocessing of the parameters and
    save any state it would like to files %s.|md}
      (String.concat ~sep:" and "
         (List.map param_set_names ~f:(sprintf "`PATH_TO_%s_PARAMETERS`")))
      (String.concat ~sep:"\n"
         (List.map param_set_names ~f:(fun s ->
              sprintf "./main %s preprocess PATH_TO_%s_PARAMETERS" s s )))
      (String.concat ~sep:" and "
         (List.map param_set_names ~f:(sprintf "`./%s_preprocessed`")))
  in
  let t : _ Sectioned_page.t =
    let open Sectioned_page in
    [Quick_details.render quick_details]
    @ preamble pages
    @ [ Interface.Spec.render spec
      ; sec ~title:"Submission guidelines"
          [ ksprintf Markdown.of_string
              {md|Your submission will be run and evaluated as follows.

%s
0. The submission runner will generate a random sequence of inputs, saved to a file
   `PATH_TO_INPUTS`.

1. Your binary will be compiled with `./build.sh`. This step should produce a binary `./main`.

3. Your binary will be invoked with

    ```bash
        %s
    ```

    and its runtime will be recorded. The file `PATH_TO_INPUTS` will contain
    a sequence of inputs, each of which is of the form specified in the
    ["Input"](#input) section. 

    It should create a file called "outputs" at the path `PATH_TO_OUTPUTS`
    which contains a sequence of outputs, each of which is of the form
    specified in the ["Output"](#output) section.

    %s
    |md}
              ( if Interface.Spec.has_batch_parameters spec then
                batch_params_description
              else "" )
              ( if Interface.Spec.has_batch_parameters spec then
                List.map param_set_names ~f:(fun p ->
                    sprintf
                      "./main %s compute PATH_TO_%s_PARAMETERS PATH_TO_INPUTS \
                       PATH_TO_OUTPUTS"
                      p p )
                |> String.concat ~sep:"\n"
              else "./main compute PATH_TO_INPUTS PATH_TO_OUTPUTS" )
              ( if Interface.Spec.has_batch_parameters spec then
                {md|It can, if it likes, read the preprocessed files created in step 1
    in order to help it solve the problem.|md}
              else "" )
            |> leaf ]
      ; sec ~title:"Reference implementation"
          [ ksprintf
              (Fn.compose leaf Markdown.of_string)
              {md|The output of your submitted program will be checked against 
the reference implementation at this repo [here](%s).
The "main" file is [here](%s).
The core algorithm is implemented [here](%s).
|md}
              reference_implementation.repo reference_implementation.main
              reference_implementation.core ] ]
    @
    let postamble = postamble pages in
    if List.is_empty postamble then []
    else [sec ~title:"Further discussion and background" postamble]
  in
  let content =
    Sectioned_page.(render_to_markdown (map ~f:Markdown.to_string t))
  in
  ksprintf Markdown.of_string !{md|# %s

%{Html}

%s|md} title
    (Sectioned_page.table_of_contents t)
    content

(*
  div []
    [ h1 [] [text title]
    ; Quick_details.render quick_details
    ; preamble pages
    ; Interface.Spec.render spec
    ; div []
        [ h2 [] [text]
        ; ksprintf markdown
            {md|
Your submission will be run and evaluated as follows.

%s
0. The submission runner will generate a random sequence of inputs, saved to a file
   `PATH_TO_INPUTS`.

3. Your binary will be invoked with

    ```bash
    ./main compute PATH_TO_INPUTS PATH_TO_OUTPUTS
    ```

    and its runtime will be recorded. The file PATH_TO_INPUTS will contain
    a sequence of inputs, each of which is of the form specified in the
    ["Input"](#input) section. 

    It should create a file called "outputs" at the path PATH_TO_OUTPUTS
    which contains a sequence of outputs, each of which is of the form
    specified in the ["Output"](#output) section.

    It can, if it likes, read
    the file "./preprocessed" in order to help it solve the problem.|md}
            ( if Interface.Spec.has_batch_parameters spec then
              batch_params_description
            else "" ) ]
    ; postamble pages
    ; hr []
    ; a [href reference_implementation_url] [text "Reference implementation"]
    ]
*)
