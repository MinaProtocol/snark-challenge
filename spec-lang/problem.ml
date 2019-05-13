open Core
module Html = Html_concise

module Parameter_kind = struct
  type t = Batch_parameter | Input | Output
end

module Quick_details = struct
  type t = {description: Html.t; prize: Prize.t}

  let render {description; prize} =
    let open Html in
    div []
      [ h2 [] [text "Quick details"]
      ; ul []
          [ li [] [Html.markdown "**Problem:** "; description]
          ; li [] [Html.markdown "**Prize:** "; Prize.render prize] ] ]
end

module Interface = struct
  module F = struct
    type 'a t =
      | Declare of
          Parameter_kind.t * string * Type.t * Html.t option * (Name.t -> 'a)
      | Choose_definitional_parameter :
          (Type.t, 'n) Vec.t list
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
      { definitional_parameters: (string, 'n) Vec.t * (Type.t, 'n) Vec.t list
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
      let open Html in
      let definitional_preamble =
        let names, choices = definitional_parameters in
        match choices with
        | [] ->
            []
        | _ ->
            [ span []
                ( [text "The following problem is defined for any choice of "]
                @ (if Vec.length names > 1 then [text "("] else [])
                @ List.intersperse ~sep:(text ",")
                    (List.map (Vec.to_list names) ~f:(fun name ->
                         Name.render_declaration name ))
                @ (if Vec.length names > 1 then [text ")"] else [])
                @ [text " in"] )
            ; ul []
                (List.map choices ~f:(fun choice ->
                     li []
                       (List.intersperse
                          (List.map (Vec.to_list choice) ~f:Type.render)
                          ~sep:(text ", ")) ))
            ; p
                "You can click on the types of any of the parameters, inputs, \
                 or outputs to see how they will be represented in the files \
                 given to your program." ]
      in
      let params ?desc ~title xs =
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
      in
      let batch_parameters =
        if List.is_empty batch_parameters then []
        else
          [ params ~title:"Parameters"
              ~desc:
                (p
                   "The parameters will be generated once and your submission \
                    will be allowed to preprocess them in any way you like \
                    before being invoked on multiple inputs.")
              batch_parameters ]
      in
      let input = params ~title:"Input" input in
      let output = params ~title:"Output" output in
      div [class_ "problem"]
        ( [h2 [] [text "Problem specification"]]
        @ definitional_preamble @ batch_parameters
        @ [input; output; description] )
  end
end

type t =
  { title: string
  ; quick_details: Quick_details.t
  ; preamble: Pages.t -> Html.t
  ; interface: Html.t Interface.t
  ; postamble: Pages.t -> Html.t
  ; reference_implementation_url: string }

let render ~pages
    { title
    ; quick_details
    ; preamble
    ; interface
    ; postamble
    ; reference_implementation_url } =
  let open Html in
  let spec = Interface.Spec.create ~name:title interface in
  let batch_params_description =
    {md|
0. The submission-runner will randomly generate the parameters and save them to a file `PATH_TO_PARAMETERS`
0. Your binary `main` will be run with 

    ```bash
    ./main preprocess PATH_TO_PARAMETERS
    ```
    where `PATH_TO_PARAMETERS` will be replaced by the acutal path.

    Your binary can at this point, if you like, do some preprocessing of the parameters and
    save any state it would like to a file `./preprocessed`.|md}
  in
  div []
    [ h1 [] [text title]
    ; Quick_details.render quick_details
    ; preamble pages
    ; Interface.Spec.render spec
    ; div []
        [ h2 [] [text "Submission guidelines"]
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
