; Blog tool example.  20 Jan 08, rev 21 May 09.

; To run:
; arc> (load "lib/blog.arc")
; arc> (bsv)
; go to http://localhost:8080/blog

;enable blog in news.arc
(= blog? t)

(= postdir* (+ srvdir* "posts/")  maxid* 0  posts* (table))

(= blogtitle* "A Blog")

(deftem post  id nil  title nil  text nil)

(def load-posts ()
  (each id (map int (dir postdir*))
    (= maxid*      (max maxid* id)
       (posts* id) (temload 'post (string postdir* id)))))

(def save-post (p) (temstore 'post p (string postdir* p!id)))

(def post (id) (posts* (errsafe:int id)))

(mac blogpage body
  `(whitepage
     (center
       (widtable 600
         (tag b (link blogtitle* "blog"))
         (br 3)
         ,@body
         (br 3)
         (w/bars (link "archive")
                 (link "new post" "newpost"))))))

(defop viewpost req (blogop post-page req))

(def blogop (f req)
  (aif (post (arg req "id"))
       (f (get-user req) it)
       (blogpage (pr "No such post."))))

(def blog-permalink (p) (string "viewpost?id=" p!id))

(def post-page (user p) (blogpage (display-post user p)))

(def display-post (user p)
  (tag b (link p!title (blog-permalink p)))
  (when user
    (sp)
    (link "[edit]" (string "editpost?id=" p!id)))
  (br2)
  (pr p!text))

(defopl newpost req
  (whitepage
    (aform [let u (get-user _)
             (post-page u (addpost u (arg _ "t") (arg _ "b")))]
      (if (if (all bound '(blog-threshold* karma))
            (> (karma (get-user req)) blog-threshold*)
            t)
      (tab (row "title" (input "t" "" 60))
           (row "text"  (textarea "b" 10 80))
           (row ""      (submit)))
      (pr (string "Sorry, you need " blog-threshold* " karma to create a blog post."))))))

(def addpost (user title text)
  (let p (inst 'post 'id (++ maxid*) 'title title 'text text)
    (save-post p)
    (= (posts* p!id) p)))

(defopl editpost req (blogop edit-blog-page req))

(def edit-blog-page (user p)
  (whitepage
    (vars-form user
               `((string title ,p!title t t) (text text ,p!text t t))
               (fn (name val) (= (p name) val))
               (fn () (save-post p)
                      (post-page user p)))))

(defop archive req
  (blogpage
    (tag ul
      (each p (map post (rev (range 1 maxid*)))
        (tag li (link p!title (blog-permalink p)))))))

(defop blog req
  (let user (get-user req)
    (blogpage
      (up i 0 5
        (awhen (posts* (- maxid* i))
          (display-post user it)
          (br 3))))))

(def bsv ()
  (ensure-dir postdir*)
  (load-posts)
  (asv))