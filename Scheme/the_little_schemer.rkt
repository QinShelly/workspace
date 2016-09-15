(define atom?
  (lambda (x)
    (and (not (pair? x)) (not (null? x)))))

(atom? (quote()))
(atom? 'atom)
(atom? 'turkey)
(atom? 1942)
(atom? 'u)
(atom? '*abc$)
(list? (quote (atom)))
(list? (quote(atom turkey or)))
(list? (quote((quote(atom turkey)) 'or)))
(car '(a b c))
(car '((a b c) x y z))
(car '(((hotdogs)) (and) (pickle) (relish)))
(car (car '(((hotdogs)) (and) (pickle) (relish))))
(cdr '(a b c))

(cdr '((a b c) x y z))
(cdr '(hamburger))
(car (cdr '((b) (x y) ((c)))))
(cdr (cdr '((b) (x y) ((c)))))

(cons 'a '(butter and fly))
(cons '(banana and) '(peanut butter and jelly))
(cons '(a b (c)) '())

(cons 'a (car '((b) c d)))
(cons 'a (cdr '((b) c d)))

(null? '())
(null? '(a b c))
(atom? '(Harry had a heap of apples))
(atom? (car '(Harry had a heap of apples)))
(atom? (cdr '(Harry had a heap of apples)))
(atom? (car (cdr '(Harry had a heap of apples))))

(eq? 'Harry 'Harry)
(eq? 'margarine 'butter)
(eq? '() '(strawberry))
(eq? 6 7)
(eq? (car '(Mary hada little lamb chop)) 'Mary)
(eq? (cdr '(soured milk)) 'milk)
(eq? (car '(beans beans we need jelly beans))  (car (cdr '(beans beans we need jelly beans))))

(define lat?
  (lambda (l)
    (cond
      ((null? l) #t)
      ((atom? (car l)) (lat? (cdr l)))
      (else #f))))

(lat? '(Jack Sprat could eat no chicken fat))
(lat? '(bacon (and eggs)))

(or (null? '()) (atom? '(d e f g)))
(or (null? '(a b c)) (null? '()))

(define member?
  (lambda(a lat)
    (cond
      ((null? lat) #f)
      (else (or (eq? a (car lat))
                (member? a (cdr lat)))))))

(member? 'tea '(coffee tea or milk))
(member? 'meat '(mashed potatoes and meat gravy))
(member? 'livers '(bagel and lox))

(define rember
  (lambda (a lat)
    (cond
      ((null? lat) '())
      ((eq? (car lat) a) (rember a (cdr lat)))
      (else (cons (car lat) (rember a (cdr lat)))))))

(rember 'mint '(lamb mint chops and mint jelly))
(rember 'sauce '(soy sauce and tomato sauce))

(define firsts
  (lambda (l)
    (cond
      ((null? l) '())
      (else (cons (caar l) (firsts (cdr l)))))))

(firsts '((apple peach pumpkin)
         (plum pear cherry)
         (grape raisin pea)
         (bean carrot eggplant)))

(firsts '((a b)
         (c d)
         (e f)))

(firsts '((five plums)
         (four)
         (eleven green oranges)))

(firsts '(((five plums) four)
         (eleven green oranges)
         ((no) more)))

(define insertR
  (lambda (new old lat)
    (cond
      ((null? lat) '())
      (else (cond
              ((eq? (car lat) old)
               (cons old
                     (cons new (cdr lat))))
              (else (cons (car lat) (insertR new old (cdr lat)))))))))

(insertR 'topping 'fudge '(ice cream with fudge for dessert))

(define insertL
  (lambda (new old lat)
    (cond
      ((null? lat) '())
      (else (cond
              ((eq? (car lat) old) (cons new (cons old (cdr lat))))
              (else (cons (car lat) (insertL new old (cdr lat)))))))))

(define subst
  (lambda (new old lat)
    (cond
      ((null? lat) '())
      (else (cond ((eq? (car lat) old)
                  (cons new (cdr lat)))
            (else (cons (car lat)
                        (subst new old (cdr lat)))))))))

(subst 'topping 'dessert '(ice cream with fudge for dessert))

(define subst2
  (lambda (new o1 o2 lat)
    (cond
      ((null? lat) '())
      (else (cond
              ((or (eq? (car lat) o1) (eq? (car lat) o2))
               (cons new (cdr lat)))
              (else (cons (car lat)
                          (subst2 new o1 o2
                                  (cdr lat)))))))))

(subst2 'vanilla 'chocolate 'banana '(banana ice cream
                                             with chocolate topping))

(define multirember
  (lambda (a lat)
    (cond
      ((null? lat) '())
      (else
       (cond
         ((eq? (car lat) a) (multirember a (cdr lat)))
         (else (cons (car lat) (multirember a (cdr lat)))))))))

(multirember 'cup '(coffee cup tea cup and hick cup))

(define multiinsertR
  (lambda (new old lat)
    (cond
      ((null? lat) '())
      (else
       (cond
         ((eq? (car lat) old)
          (cons old
                (cons new (multiinsertR new old (cdr lat)))))
         (else (cons (car lat) (multiinsertR new old (cdr lat)))))))))

(define multiinsertL
  (lambda (new old lat)
    (cond
      ((null? lat) '())
      (else
       (cond
         ((eq? (car lat) old)
          (cons new (cons old (multiinsertL new old (cdr lat)))))
         (else (cons (car lat) (multiinsertL new old (cdr lat)))))))))

(multiinsertL 'fried 'fish '(chips and fish or fish and fried))

(define multisubst
  (lambda (new old lat)
    (cond
      ((null? lat) '())
      (else
       (cond
         ((eq? (car lat) old)
          (cons new (cdr lat)))
         (else
          (cons (car lat) (multisubst new old (cdr lat)))))))))

(define add1
  (lambda (n)
    (+ n 1)))

(define sub1
  (lambda (n)
    (- n 1)))

(define o+
  (lambda (n m)
    (cond
      ((zero? m) n)
      (else (add1 (o+ n (sub1 m)))))))

(o+ 1 2)

(define o-
  (lambda (n m)
    (cond
      ((zero? m) n)
      (else (sub1 (o- n (sub1 m)))))))
(o- 14 3)
(o- 18 25)

(define addtup
  (lambda (tup)
    (cond
      ((null? tup) 0)
      (else (o+ (car tup) (addtup (cdr tup)))))))

(addtup '(5 3 9))

(define o*
  (lambda (n m)
    (cond
      ((zero? m) 0)
      (else (o+ n (o* n (sub1 m)))))))

(o* 8 5)

(define tup+
  (lambda (tup1 tup2)
    (cond
      ((null? tup1) tup2)
      ((null? tup2) tup1)
      (else (cons (o+ (car tup1) (car tup2))
                  (tup+ (cdr tup1) (cdr tup2)))))))

(tup+ '(2 4) '(5 8))
(tup+ '(2 4) '(5 8 7 6))

(define O>
  (lambda (n m)
    (cond
      ((zero? n) #f)
      ((zero? m) #t)
      (else (O> (sub1 n) (sub1 m))))))
(O> 2 3)

(define O<
  (lambda (n m)
    (cond
      ((zero? m) #f)
      ((zero? n) #t)
      (else (O< (sub1 n) (sub1 m))))))

(O< 4 3)

(define o=
  (lambda (n m)
    (cond
      ((zero? m) (zero? n))
      ((zero? n) #f)
      (else (o= (sub1 n) (sub1 m))))))

(o= 4 4)

(define o!
  (lambda (n m)
    (cond
      ((zero? m) 1)
      (else (o* n (o! n (sub1 m)))))))

(o! 2 3)

(define devision
  (lambda (n m)
          (cond
            ((o< n m) 0)
            (else (add1 (devision (o- n m) m))))))

(devision 15 4)

(define Olength
  (lambda (lat)
    (cond
      ((null? lat) 0)
      (else (add1 (length (cdr lat)))))))

(length '(ham and chees on rye))

(define pick
  (lambda (n lat)
    (cond
      ((zero? (sub1 n)) (car lat))
      (else (pick (sub1 n) (cdr lat))))))

(pick 4 '(lasagna spaghetti ravioli macaroni meatball))

(define rempick
  (lambda (n lat)
    (cond
      ((zero? (sub1 n)) (cdr lat))
      (else (cons (car lat)
                  (rempick (sub1 n)
                           (cdr lat)))))))

(rempick 3 '(hotdogs with hot mustard))

(define no-nums
  (lambda (lat)
    (cond
      ((null? lat) '())
      (else (cond
              ((number? (car lat))
               (no-nums (cdr lat)))
              (else (cons (car lat)
                          (no-nums (cdr lat)))))))))

(no-nums '(5 pears 6 prunes 9 dates))

(define all-nums
  (lambda (lat)
    (cond
      ((null? lat) '())
      (else (cond
              ((number? (car lat))
               (cons (car lat) (all-nums (cdr lat))))
              (else (all-nums (cdr lat))))))))

(all-nums '(5 pears 6 prunes 9 dates))

(define occur
  (lambda (a lat)
    (cond
      ((null? lat) 0)
      (else (cond
              ((eq? a (car lat))
               (add1 (occur a (cdr lat))))
              (else (occur a (cdr lat))))))))

(define rember*
  (lambda (a l)
    (cond
      ((null? l) '())
      ((atom? (car l))
       (cond
         ((eq? (car l) a) (rember* a (cdr l)))
         (else (cons (car l) (rember* a (cdr l))))))
      (else (cons (rember* a (car l)) (rember* a (cdr l)))))))

              
(rember* 'cup '((coffee) cup ((tea) cup) (and (hick)) cup))

(define insertR*
  (lambda (new old l)
    (cond
      ((null? l) '())
      ((atom? (car l))
       (cond
         ((eq? old (car l)) (cons old (cons new (insertR* new old (cdr l)))))
         (else (cons (car l) (insertR* new old (cdr l))))))
      (else (cons (insertR* new old (car l)) (insertR* new old (cdr l)))))))

(insertR* 'roast 'chuck '(((chuck)) (a (wood) chuck)))

(define occur*
  (lambda (a l)
    (cond
      ((null? l) 0)
      ((atom? (car l))
       (cond
         ((eq? a (car l)) (+ 1 (occur* a (cdr l))))
         (else (occur* a (cdr l)))))
      (else (+ (occur* a (car l)) (occur* a (cdr l)))))))

(occur* 'banana '((banana) (split ((banana ice) (cream (banana))))))

(define subst*
  (lambda (new old l)
    (cond
      ((null? l) '())
      ((atom? (car l))
       (cond
         ((eq? (car l) old)
          (cons new
                (subst* new old (cdr l))))
         (else (cons (car l)
                     (subst* new old
                             (cdr l))))))
       (else
        (cons (subst* new old (car l))
              (subst* new old (cdr l)))))))

(subst* 'orange 'banana '((banana)
                          (split ((((banana ice)))
                                  (cream (banana))
                                  sherbet))
                          (banana)
                          (bread)))

(define insertL*
  (lambda (new old l)
    (cond
      ((null? l) '())
      ((atom? (car l))
       (cond
         ((eq? (car l) old)
          (cons new
                (cons old
                      (insertL* new old
                                (cdr l)))))
         (else (cons (car l)
                     (insertL* new old
                               (cdr l))))))
      (else (cons (insertL* new old
                            (car l))
                  (insertL* new old
                            (cdr l)))))))

(insertL* 'pecker 'chuck '((how much (wood))
                           could
                           ((a (wood) chuck))
                           (((chuck)))
                           (if (a) ((wood chuck)))
                           could chuck wood))

(define member*
  (lambda (a l)
    (cond
      ((null? l) #f)
      ((atom? (car l))
       (or (eq? (car l) a)
           (member* a (cdr l))))
      (else (or (member* a (car l))
                (member* a (cdr l)))))))

(member* 'chips '((potato) (chips ((with) fish) (chips))))

(define leftmost
  (lambda (l)
    (cond
      ((atom? (car l)) (car l))
      (else (leftmost (car l))))))

(leftmost '(((hot) (tuna (and))) cheese))

(define eqan?
  (lambda (a1 a2)
    (cond
      ((and (number? a1) (number? a2))(= a1 a2))
      ((or (number? a1) (number? a2)) #f)
      (else (eq? a1 a2)))))

(define Oequal?
  (lambda (s1 s2)
    (cond
      ((and (atom? s1) (atom? s2))
       (eqan? s1 s2))
      ((or (atom? s1) (atom? s2))
       #f)
      (else (eqlist? s1 s2)))))

(define eqlist?
  (lambda (l1 l2)
    (cond
      ((and (null? l1) (null? l2)) #t)
      ((or (null? l1) (null? l2)) #f)
      (else
       (and (Oequal? (car l1) (car l2))
            (eqlist? (cdr l1) (cdr l2)))))))

(eqlist? '(beef ((salami)) (and (soda))) '(beef ((sausage)) (and (soda))))
(eqlist? '(beef ((sausage)) (and (soda))) '(beef ((sausage)) (and (soda))))

(define rember
  (lambda (s l)
    (cond
      ((null? l) '())
      ((equal? (car l) s) (cdr l))
      (else (cons (car l)
              (rember s
                 (cdr l)))))))

(define numbered?
  (lambda (aexp)
    (cond
      ((atom? aexp) (number? aexp))
      ((eq? (car (cdr aexp)) '+)
       (and (numbered? (car aexp))
                       (numbered? (car (cdr (cdr aexp))))))
      ((eq? (car (cdr aexp)) '*)
       (and (numbered? (car aexp))
                       (numbered? (car (cdr (cdr aexp))))))
      )))

(numbered? '(3 * 5))

(define value
  (lambda (nexp)
    (cond
      ((atom? nexp) nexp)
      ((eq? (car (cdr nexp)) '+)
       (+ (value (car nexp))
          (value (car (cdr (cdr nexp))))))
            ((eq? (car (cdr nexp)) '*)
       (* (value (car nexp))
          (value (car (cdr (cdr nexp)))))))))

(value '(3 + (4 + 5)))
(value '(3 * (4 + 5)))

(define set?
  (lambda (lat)
    (cond
      ((null? lat) #t)
      ((member? (car lat) (cdr lat))
          #f)
      (else (set? (cdr lat))))))

(set? '(apple peaches apple plum))
(set? '(apple 3 pear 4 9 apple 3 4))

(define makeset
  (lambda (lat)
    (cond
      ((null? lat) '())
      ((member? (car lat) (cdr lat))
       (makeset (cdr lat)))
      (else (cons (car lat)
                  (makeset (cdr lat)))))))

(makeset '(apple peach pear peach plum apple lemon peach))

(define makeset
  (lambda (lat)
    (cond
      ((null? lat) '())
      (else (cons (car lat)
                  (makeset
                   (multirember (car lat)
                                (cdr lat))))))))

(makeset '(apple peach pear peach plumn apple lemon peach))
(makeset '(apple 3 pear 4 9 apple 3 4))

(define subset?
  (lambda (set1 set2)
    (cond
      ((null? set1) #t)
      (else (cond
              ((member (car set1) set2)
               (subset? (cdr set1) set2))
              (else #f))))))

(subset? '(5 chicken wings) '(5 hamburgers 2 pieces fried chicken and light duckling wings))
(subset? '(4 pounds of horseradish) '(four pounds chicken and 5 ounces horseradish))

(define eqset?
  (lambda (set1 set2)
    (and (subset? set1 set2)
         (subset? set2 set1))))

(eqset? '(a b c) '(a b c d))
(eqset? '(a b c d) '(a b c d))

(define intersect?
  (lambda (set1 set2)
    (cond
      ((null? set1) #f)
      ((member? (car set1) set2) #t)
      (else (intersect? (cdr set1) set2)))))

(intersect? '(a b c) '(d e f))
(intersect? '(a b) '(a b c))

(define intersect
  (lambda (set1 set2)
    (cond
      ((null? set1) '())
      ((member? (car set1) set2)
       (cons (car set1) (intersect (cdr set1) set2)))
      (else (intersect (cdr set1) set2)))))

(intersect '(stewed tomatoes and macaroni) '(macaroni and cheese))

(define union
  (lambda (set1 set2)
    (cond
      ((null? set1) set2)
      ((member? (car set1) set2)
       (union (cdr set1) set2))
      (else (cons (car set1)
                  (union (cdr set1) set2))))))

(union '(stewed tomatoes and macaroni casserole) '(macaroni and cheese))

(define xxx
  (lambda (set1 set2)
    (cond
      ((null? set1) '())
      ((member? (car set1) set2)
       (xxx (cdr set1) set2))
      (else (cons (car set1)
                  (xxx (cdr set1) set2))))))

(xxx '(a b c) '(a b d))

(define intersectall
  (lambda (l-set)
    (cond
      ((null? (cdr l-set)) (car l-set))
      (else (intersect (car l-set)
                       (intersectall (cdr l-set)))))))

(intersectall '((6 pears and)
                (3 peaches and 6 peppers)
                (8 pears and 6 plums)
                (and 6 prunes with some apples)))

(pair? '(pear pear))
(pair? '((2) (pair)))
(pair? '(full (house)))

(define first
  (lambda (p)
    (car p)))

(define second
  (lambda (p)
    (car (cdr p))))

(define build
  (lambda (s1 s2)
    (cons s1 (cons s2 '()))))

(define fun?
  (lambda (rel)
    (set? (firsts rel))))

(fun? '((d 4) (b 0)))
(fun? '((d 4) (b 0) (b 9)))

(define revpair
  (lambda (pair)
    (build (second pair) (first pair))))

(define revrel
  (lambda (rel)
    (cond
      ((null? rel) '())
      (else (cons (revpair (car rel))
                  (revrel (cdr rel)))))))

(revrel '((8 a) (pumpkin pie) (got sick)))

(define seconds
  (lambda (l)
    (cond
      ((null? l) '())
      (else (cons (car (cdr (car l)))
                  (seconds (cdr l)))))))
(seconds '((8 2) (5 2)))

(define fullfun?
  (lambda (fun)
    (set? (seconds fun))))

(fullfun? '((8 2) (5 2)))
(fullfun? '((grape raisin)
            (plum prune)
            (stewed grape)))

(define one-to-one?
  (lambda (fun)
    (fun? (revrel fun))))

(one-to-one? '((chocolate chip) (doughy cookie)))

(define rember-f
  (lambda (test?)
    (lambda (a l)
      (cond
        ((null? l) '())
        ((test? (car l) a) (cdr l))
        (else (cons (car l)
                    ((rember-f test?) a (cdr l))))))))

((rember-f equal?) '(pop corn) '(lemonade (pop corn) and (cake)))

(define eq?-c
  (lambda (a)
    (lambda (x)
      (eq? x a))))

(define eq?-salad (eq?-c 'salad))

((eq?-c 'salad) 'cucubee)

(define insertL-f
  (lambda (test?)
    (lambda (new old l)
      (cond
        ((null? l) '())
        ((test? (car l) old)
         (cons new (cons old (cdr l))))
        (else (cons (car l)
                    ((insertL-f test?) new old (cdr l))))))))

((insertL-f eq?) 'd 'b '(a b c))

(define insertR-f
  (lambda (test?)
    (lambda (new old l)
      (cond
        ((null? l) '())
        ((test? (car l) old)
         (cons old (cons new (cdr l))))
        (else (cons (car l)
                    ((insertR-f test?) new old (cdr l))))))))

((insertR-f eq?) 'd 'b '(a b c))

(define seqL
  (lambda (new old l)
    (cons new (cons old l))))

(define seqR
  (lambda (new old l)
    (cons old (cons new l))))

(define insert-g
  (lambda (seq)
    (lambda (new old l)
      (cond
        ((null? l) '())
        ((eq? (car l) old)
         (seq new old (cdr l)))
        (else (cons (car l)
                    ((insert-g seq) new old (cdr l))))))))

(define insertL
  (insert-g
   (lambda (new old l)
     (cons new (cons old l)) )))

(insertL 'd 'b '(a b c))

(define insertR
  (insert-g seqR))

(insertR 'd 'b '(a b c))

(define multirember_co
  (lambda (a lat col)
    (cond
      ((null? lat)
       (col '() '()))
      ((eq? (car lat) a)
       (multirember_co a
                       (cdr lat)
                       (lambda (newlat seen)
                         (col newlat
                              (cons (car lat) seen)))))
      (else
       (multirember_co a
                       (cdr lat)
                       (lambda (newlat seen)
                         (col (cons (car lat) newlat)
                              seen)))))))

(define a-friend
  (lambda (x y)
    (null? y)))

(multirember_co 'tuna '(strawberries tuna and swordfish) a-friend)
(multirember_co 'tuna '() a-friend)
(multirember_co 'tuna '(tuna) a-friend)
(multirember_co 'tuna '(and tuna) a-friend)

(define last-friend
  (lambda (x y)
    (length x)))

(multirember_co 'tuna '(strawberries tuna and swordfish) last-friend)

(define multiinsertLR
  (lambda (new oldL oldR lat)
    (cond
      ((null? lat) '())
      ((eq? (car lat) oldL)
       (cons new
             (cons oldL
                   (multiinsertLR new oldL oldR
                                  (cdr lat)))))
      ((eq? (car lat) oldR)
       (cons oldR
             (cons new
                   (multiinsertLR new oldL oldR
                                  (cdr lat)))))
      (else
       (cons (car lat)
             (multiinsertLR new oldL oldR
                            (cdr lat)))))))

(multiinsertLR 'f 'b 'c '(a b c))

(define multiinsertLR_co
  (lambda (new oldL oldR lat col)
    (cond
      ((null? lat)
       (col '() 0 0))
      ((eq? (car lat) oldL)
       (multiinsertLR_co new oldL oldR
                         (cdr lat)
                         (lambda (newlat L R)
                           (col (cons new
                                      (cons oldL newlat))
                                (+ 1 L) R))))
      ((eq? (car lat) oldR)
       (multiinsertLR_co new oldL oldR
                         (cdr lat)
                         (lambda (newlat L R)
                           (col (cons oldR
                                      (cons new newlat))
                                L (+ 1 R)))))
      (else
       (multiinsertLR_co new oldL oldR
                         (cdr lat)
                         (lambda (newlat L R)
                           (col (cons (car lat) newlat)
                                L R)))))))

(multiinsertLR_co 'f 'b 'c '(a b c) (lambda (x y z) (cons x (cons y z))))

(define even-only*
  (lambda (l)
    (cond
      ((null? l) '())
      ((atom? (car l))
       (cond
         ((even? (car l))
          (cons (car l)
                (even-only* (cdr l))))
         (else (even-only* (cdr l)))))
      (else (cons (even-only* (car l))
                  (even-only* (cdr l)))))))

(even-only* '((9 1 2 8) 3 10 ((9 9) 7 6) 2))


(define even-only*_Co
  (lambda (l col)
          (cond
            ((null? l)
             (col '() 1 0))
            ((atom? (car l))
             (cond
               ((even? (car l))
               (even-only*_co (cdr l)
                              (lambda (newl p s)
                                (col (cons (car l) newl)
                                     (* (car l) p) s))))
             (else (even-only*_co (cdr l)
                                  (lambda (newl p s)
                                    (col newl
                                         p (+ (car l) s)))))))
            (else (even-only*_co (car l)
                                 (lambda (newl p s)
                                   (even-only*_co (cdr l)
                                                 (lambda (dnewl dproduct dsum)
                                                   (col (cons newl dnewl)
                                                        (* p dproduct)
                                                        (+ s dsum))))))))))
(define the-last-friend
  (lambda (newl product sum)
    (cons sum
          (cons product
                newl))))
(even-only*_co '((9 1 2 8) 3 10 ((9 9) 7 6) 2) the-last-friend)

(define looking
  (lambda (a lat)
    (keep-looking a (pick 1 lat) lat)))

(define keep-looking
  (lambda (a sorn lat)
    (cond
      ((number? sorn)
       (keep-looking a (pick sorn lat) lat))
      (else (eq? sorn a)))))

(pick 2 '(a b c d))
(looking 'caviar '(6 2 grits caviar 5 7 3))
(looking 'caviar '(6 2 4 caviar 5 7 3))

(define shift
  (lambda (pair)
    (build (first (first pair))
           (build (second (first pair))
                  (second pair)))))
(shift '((a b) c))
(shift '((a b) (c d)))


                                                 
                                   