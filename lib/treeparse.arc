; treeparse.arc -- born on 2008/02/27
;
; A parser combinator library for parsing lists and trees.
; Loosely based on parsecomb.arc and Parsec.
;
; Parsers are functions that take a list as input and return a list
; with the following structure:
;
;     (<parsed list> <remaining list> <actions>)
;
; Parsers return nil on failure.
;
; To parse a scheme-ish binary number
;    e.g. ("#" "b" 0 0 0 1 0 1 0 1 0)
; (= bin-digit    (alt 0 1)
;    binary (seq "#" "b" (many1 bin-digit)))
; then call (parse binary <input string>)
; or just (binary <input string>)
;
; Use `sem' to embed semantics.
; Use `filt' to embed filters.
;
; Examples in "lib/treeparse-examples.arc"

(require "lib/tconc.arc")

(mac delay-parser (p)
  "Delay evaluation of a parser, in case it is not yet defined."
  (let remaining (uniq)
    `(fn (,remaining)
       (parse ,p ,remaining))))

(def return (val remaining (o actions nil))
  "Signal a successful parse."
  (list val remaining actions))

(def parse-all (parser input)
  "Calls parse, returning the parsed list only if the entire input was
parsed. Otherwise returns nil and prints an error. Semantics are
executed on success."
  (awhen (parse parser input)
    (if (no:it 1) (do (carry-out it) (it 0))
                  (do (pr "Parse error: extra tokens '")
                      (prn (it 1))
                      nil))))

(def parse (parser remaining)
  "Apply parser (or literal, or list) to input."
  (if (isa parser 'fn) (parser remaining)
      (acons parser) (parse-list parser remaining)
      (parse (lit parser) remaining)))

(def parse-list (parsers li)
  (when (and li (alist li) (alist (car li)))
    (iflet (parsed remaining actions) (seq-r2 parsers (car li)
                                              (tconc-new) (tconc-new))
           (unless remaining (return (list parsed)
                                     (cdr li) actions)))))

(def lit (a)
  "Creates a parser that matches a literal. You shouldn't need to
call this directly, `parse' should wrap up literals for you."
  (fn (remaining)
    (when (and (acons remaining) (iso a (car remaining)))
      (return (list (car remaining)) (cdr remaining)))))

(def seq parsers
  "Applies parsers in sequential order."
  (seq-l parsers))

(def seq-l (parsers)
  "Applies the list of parsers in sequential order"
  (fn (remaining)
    (seq-r parsers remaining (tconc-new) (tconc-new))))

(def seq-r (parsers li acc act-acc)
  (if (no parsers) (return (car acc) li (car act-acc))
      (iflet (parsed remaining actions) (parse (car parsers) li)
             (seq-r (cdr parsers) remaining 
                    (lconc acc (copy parsed))
                    (lconc act-acc (copy actions))))))

(def alt parsers
  "Alternatives, like Parsec's <|>."
  (alt-l parsers))

(def alt-l (parsers)
  "A list of alternatives, like Parsec's <|>."
  (fn (remaining) (alt-r parsers remaining)))

(def alt-r (parsers remaining)
  (if (no parsers) nil
      (or (parse (car parsers) remaining)
          (alt-r (cdr parsers) remaining))))

(def nothing (remaining)
  "A parser that consumes nothing."
  (return nil remaining))

(def at-end (remaining)
  "A parser that succeeds only if input is empty."
  (unless remaining (return nil nil)))

(def anything (remaining)
  "A parser that consumes one token."
  (when (acons remaining)
    (return (list (car remaining)) (cdr remaining))))

(def anything-but parsers
  "Anything that 'parsers' will not accept."
  (seq (cant-see (apply alt parsers)) anything))

(def maybe (parser)
  "Parser appears once, or not."
  (alt parser nothing))

(def cant-see (parser)
  "Parser does not appear next in the input stream."
  (fn (remaining)
    (if (parse parser remaining) nil
        (return nil remaining))))

(def many (parser)
  "Parser is repeated zero or more times."
  (fn (remaining) (many-r parser remaining (tconc-new) nil)))

(def many-r (parser li acc act-acc)
  (iflet (parsed remaining actions) (parse parser li)
         (many-r parser remaining
                 (lconc acc (copy parsed))
                 (if actions (join act-acc actions) act-acc))
         (return (car acc) li act-acc)))

(def many1 (parser)
  "Parser is repeated one or more times."
  (seq parser (many parser)))

(def many2 (parser)
  "Parser is repeated two or more times."
  (seq parser (many1 parser)))

(def pred (test parser)
  "Create a parser that succeeds if `parser' succeeds and its output
passes `test'."
  (fn (remaining)
    (awhen (parse parser remaining)
      (and (test (car it)) it))))

(def sem (fun parser)
  "Attach semantics to a parser."
  (fn (remaining)
    (iflet (parsed remaining actions) (parse parser remaining)
           (return parsed remaining
                   (join actions
                         (list (fn () (fun parsed))))))))

(def filt (fun parser)
  "Attach filter to a parser."
  (fn (remaining)
    (iflet (parsed remaining actions) (parse parser remaining)
           (return (fun parsed) remaining actions))))

(def filtcar (fun parser)
  "Like filt, but only operates on the car of the input.
  (filtcar foo p) == (filt foo:car p)."
  (filt fun:car parser))

(def carry-out (result)
  "Execute the semantics of a parser result."
  (each f (result 2) (f)))
