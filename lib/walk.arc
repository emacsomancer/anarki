($:namespace-undefine-variable! '_walk)
(defgeneric walk (seq f)
  ((afn (l)
     (when acons.l
       (f car.l)
       (self cdr.l)))
   seq))

(defmethod walk (seq f) (isa seq table)
  (maptable (fn (k v)
              (f (list k v)))
            seq))

(defmethod walk (seq f) (isa seq string)
  (forlen i seq
    (f seq.i)))

; different ways to navigate trees
(def tree (x)
  (annotate 'tree x))

(defmethod walk (seq f) (isa seq tree)
  (let x rep.seq
    (f x)
    (unless (atom x)
      (walk (tree car.x) f)
      (walk (tree cdr.x) f))))

(def leaves (x)
  (annotate 'leaves x))

(defmethod walk (seq f) (isa seq leaves)
  (let x rep.seq
    (if (atom x)
      (f x)
      (do (walk (leaves car.x) f)
          (walk (leaves cdr.x) f)))))