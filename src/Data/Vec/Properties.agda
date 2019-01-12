------------------------------------------------------------------------
-- The Agda standard library
--
-- Some Vec-related properties
------------------------------------------------------------------------

{-# OPTIONS --without-K --safe #-}

module Data.Vec.Properties where

open import Algebra.FunctionProperties
open import Data.Empty using (⊥-elim)
open import Data.Fin as Fin using (Fin; zero; suc; toℕ; fromℕ)
open import Data.Fin.Properties using (_+′_)
open import Data.List.Base as List using (List)
open import Data.List.Any using (here; there)
import Data.List.Membership.Propositional as List
open import Data.Nat
open import Data.Nat.Properties using (+-assoc; ≤-step)
open import Data.Product as Prod
  using (_×_; _,_; proj₁; proj₂; <_,_>; uncurry)
open import Data.Vec
open import Function
open import Function.Inverse using (_↔_; inverse)
open import Relation.Binary as B hiding (Decidable)
open import Relation.Binary.PropositionalEquality as P
  using (_≡_; _≢_; refl; _≗_)
open import Relation.Binary.HeterogeneousEquality as H using (_≅_; refl)
open import Relation.Unary using (Pred; Decidable)
open import Relation.Nullary using (yes; no)

------------------------------------------------------------------------
-- Properties of propositional equality over vectors

module _ {a} {A : Set a} {n} {x y : A} {xs ys : Vec A n} where

 ∷-injectiveˡ : x ∷ xs ≡ y ∷ ys → x ≡ y
 ∷-injectiveˡ refl = refl

 ∷-injectiveʳ : x ∷ xs ≡ y ∷ ys → xs ≡ ys
 ∷-injectiveʳ refl = refl

 ∷-injective : (x ∷ xs) ≡ (y ∷ ys) → x ≡ y × xs ≡ ys
 ∷-injective refl = refl , refl

module _ {a} {A : Set a} where

  ≡-dec : B.Decidable _≡_ → ∀ {n} → B.Decidable {A = Vec A n} _≡_
  ≡-dec _≟_ []       []       = yes refl
  ≡-dec _≟_ (x ∷ xs) (y ∷ ys) with x ≟ y | ≡-dec _≟_ xs ys
  ... | yes refl | yes refl = yes refl
  ... | no  x≢y  | _        = no (x≢y   ∘ ∷-injectiveˡ)
  ... | yes _    | no xs≢ys = no (xs≢ys ∘ ∷-injectiveʳ)

------------------------------------------------------------------------
-- _[_]=_

module _ {a} {A : Set a} where

  []=-injective : ∀ {n} {xs : Vec A n} {i x y} →
                  xs [ i ]= x → xs [ i ]= y → x ≡ y
  []=-injective here          here          = refl
  []=-injective (there xsᵢ≡x) (there xsᵢ≡y) = []=-injective xsᵢ≡x xsᵢ≡y

  -- See also Data.Vec.Properties.WithK.[]=-irrelevant.

------------------------------------------------------------------------
-- lookup

module _ {a} {A : Set a} where

  []=⇒lookup : ∀ {n} {x : A} {xs} {i : Fin n} →
               xs [ i ]= x → lookup i xs ≡ x
  []=⇒lookup here            = refl
  []=⇒lookup (there xs[i]=x) = []=⇒lookup xs[i]=x

  lookup⇒[]= : ∀ {n} (i : Fin n) {x : A} xs →
               lookup i xs ≡ x → xs [ i ]= x
  lookup⇒[]= zero    (_ ∷ _)  refl = here
  lookup⇒[]= (suc i) (_ ∷ xs) p    = there (lookup⇒[]= i xs p)

  []=↔lookup : ∀ {n i} {x} {xs : Vec A n} →
               xs [ i ]= x ↔ lookup i xs ≡ x
  []=↔lookup {i = i} =
    inverse []=⇒lookup (lookup⇒[]= _ _)
            lookup⇒[]=∘[]=⇒lookup ([]=⇒lookup∘lookup⇒[]= i _)
    where
    lookup⇒[]=∘[]=⇒lookup :
      ∀ {n x xs} {i : Fin n} (p : xs [ i ]= x) →
      lookup⇒[]= i xs ([]=⇒lookup p) ≡ p
    lookup⇒[]=∘[]=⇒lookup here      = refl
    lookup⇒[]=∘[]=⇒lookup (there p) =
      P.cong there (lookup⇒[]=∘[]=⇒lookup p)

    []=⇒lookup∘lookup⇒[]= :
      ∀ {n} (i : Fin n) {x} xs (p : lookup i xs ≡ x) →
      []=⇒lookup (lookup⇒[]= i xs p) ≡ p
    []=⇒lookup∘lookup⇒[]= zero    (x ∷ xs) refl = refl
    []=⇒lookup∘lookup⇒[]= (suc i) (x ∷ xs) p    =
      []=⇒lookup∘lookup⇒[]= i xs p

------------------------------------------------------------------------
-- updateAt (_[_]%=_)

module _ {a} {A : Set a} where

  -- Defining properties of updateAt:

  -- (+) updateAt i actually updates the element at index i.

  updateAt-updates : ∀ {n} (i : Fin n) {f : A → A} (xs : Vec A n) {x : A}
    → xs              [ i ]= x
    → updateAt i f xs [ i ]= f x
  updateAt-updates zero    (x ∷ xs) here        = here
  updateAt-updates (suc i) (x ∷ xs) (there loc) = there (updateAt-updates i xs loc)

  -- (-) updateAt i does not touch the elements at other indices.

  updateAt-minimal : ∀ {n} (i j : Fin n) {f : A → A} {x : A} (xs : Vec A n)
    → i ≢ j
    → xs              [ i ]= x
    → updateAt j f xs [ i ]= x
  updateAt-minimal zero    zero    (x ∷ xs) 0≢0 here        = ⊥-elim (0≢0 refl)
  updateAt-minimal zero    (suc j) (x ∷ xs) _   here        = here
  updateAt-minimal (suc i) zero    (x ∷ xs) _   (there loc) = there loc
  updateAt-minimal (suc i) (suc j) (x ∷ xs) i≢j (there loc) =
    there (updateAt-minimal i j xs (i≢j ∘ P.cong suc) loc)

  -- The other properties are consequences of (+) and (-).
  -- We spell the most natural properties out.
  -- Direct inductive proofs are in most cases easier than just using
  -- the defining properties.

  -- In the explanations, we make use of shorthand  f = g ↾ x
  -- meaning that f and g agree at point x, i.e.  f x ≡ g x.

  -- updateAt i  is a morphism from the monoid of endofunctions  A → A
  -- to the monoid of endofunctions  Vec A n → Vec A n

  -- 1a. relative identity:  f = id ↾ (lookup i xs)
  --                implies  updateAt i f = id ↾ xs

  updateAt-id-relative : ∀ {n} (i : Fin n) (xs : Vec A n) {f : A → A}
    → f (lookup i xs) ≡ lookup i xs
    → updateAt i f xs ≡ xs
  updateAt-id-relative zero    (x ∷ xs) eq = P.cong (_∷ xs) eq
  updateAt-id-relative (suc i) (x ∷ xs) eq = P.cong (x ∷_) (updateAt-id-relative i xs eq)

  -- 1b. identity:  updateAt i id ≗ id

  updateAt-id : ∀ {n} (i : Fin n) (xs : Vec A n) →
    updateAt i id xs ≡ xs
  updateAt-id i xs = updateAt-id-relative i xs refl

  -- 2a. relative composition:  f ∘ g = h ↾ (lookup i xs)
  --                   implies  updateAt i f ∘ updateAt i g ≗ updateAt i h

  updateAt-compose-relative : ∀ {n} (i : Fin n) {f g h : A → A} (xs : Vec A n)
    → f (g (lookup i xs)) ≡ h (lookup i xs)
    → updateAt i f (updateAt i g xs) ≡ updateAt i h xs
  updateAt-compose-relative zero    (x ∷ xs) fg=h = P.cong (_∷ xs) fg=h
  updateAt-compose-relative (suc i) (x ∷ xs) fg=h =
    P.cong (x ∷_) (updateAt-compose-relative i xs fg=h)

  -- 2b. composition:  updateAt i f ∘ updateAt i g ≗ updateAt i (f ∘ g)

  updateAt-compose : ∀ {n} (i : Fin n) {f g : A → A} →
    updateAt i f ∘ updateAt i g ≗ updateAt i (f ∘ g)
  updateAt-compose i xs = updateAt-compose-relative i xs refl

  -- 3. congruence:  updateAt i  is a congruence wrt. extensional equality.

  -- 3a.  If    f = g ↾ (lookup i xs)
  --      then  updateAt i f = updateAt i g ↾ xs

  updateAt-cong-relative : ∀ {n} (i : Fin n) {f g : A → A} (xs : Vec A n)
    → f (lookup i xs) ≡ g (lookup i xs)
    → updateAt i f xs ≡ updateAt i g xs
  updateAt-cong-relative zero    (x ∷ xs) f=g = P.cong (_∷ xs) f=g
  updateAt-cong-relative (suc i) (x ∷ xs) f=g = P.cong (x ∷_) (updateAt-cong-relative i xs f=g)

  -- 3b. congruence:  f ≗ g → updateAt i f ≗ updateAt i g

  updateAt-cong : ∀ {n} (i : Fin n) {f g : A → A}
    → f ≗ g
    → updateAt i f ≗ updateAt i g
  updateAt-cong i f≗g xs = updateAt-cong-relative i xs (f≗g (lookup i xs))

  -- The order of updates at different indices i ≢ j does not matter.

  -- This a consequence of updateAt-updates and updateAt-minimal
  -- but easier to prove inductively.

  updateAt-commutes : ∀ {n} (i j : Fin n) {f g : A → A}
    → i ≢ j
    → updateAt i f ∘ updateAt j g ≗ updateAt j g ∘ updateAt i f
  updateAt-commutes zero    zero    0≢0 (x ∷ xs) = ⊥-elim (0≢0 refl)
  updateAt-commutes zero    (suc j) i≢j (x ∷ xs) = refl
  updateAt-commutes (suc i) zero    i≢j (x ∷ xs) = refl
  updateAt-commutes (suc i) (suc j) i≢j (x ∷ xs) =
    P.cong (x ∷_) (updateAt-commutes i j (i≢j ∘ P.cong suc) xs)

  -- lookup after updateAt reduces.

  -- For same index this is an easy consequence of updateAt-updates
  -- using []=↔lookup.

  lookup∘updateAt : ∀ {n} (i : Fin n) {f : A → A} →
    lookup i ∘ updateAt i f ≗ f ∘ lookup i
  lookup∘updateAt i xs =
    []=⇒lookup (updateAt-updates i xs (lookup⇒[]= i _ refl))

  -- For different indices it easily follows from updateAt-minimal.

  lookup∘updateAt′ : ∀ {n} (i j : Fin n) {f : A → A}
    → i ≢ j
    → lookup i ∘ updateAt j f ≗ lookup i
  lookup∘updateAt′ i j xs i≢j =
    []=⇒lookup (updateAt-minimal i j i≢j xs (lookup⇒[]= i _ refl))

  -- Aliases for notation _[_]%=_

  []%=-id : ∀ {n} (xs : Vec A n) (i : Fin n) → xs [ i ]%= id ≡ xs
  []%=-id xs i = updateAt-id i xs

  []%=-compose : ∀ {n} (xs : Vec A n) (i : Fin n) {f g : A → A} →
       xs [ i ]%= f
          [ i ]%= g
     ≡ xs [ i ]%= g ∘ f
  []%=-compose xs i = updateAt-compose i xs

------------------------------------------------------------------------
-- _[_]≔_ (update)
--
-- _[_]≔_ is defined in terms of updateAt, and all of its properties
-- are special cases of the ones for updateAt.

module _ {a} {A : Set a} where

  []≔-idempotent : ∀ {n} (xs : Vec A n) (i : Fin n) {x₁ x₂ : A} →
                   (xs [ i ]≔ x₁) [ i ]≔ x₂ ≡ xs [ i ]≔ x₂
  []≔-idempotent xs i = updateAt-compose i xs

  []≔-commutes : ∀ {n} (xs : Vec A n) (i j : Fin n) {x y : A} → i ≢ j →
                 (xs [ i ]≔ x) [ j ]≔ y ≡ (xs [ j ]≔ y) [ i ]≔ x
  []≔-commutes xs i j i≢j = updateAt-commutes j i (i≢j ∘ P.sym) xs

  []≔-updates : ∀ {n} (xs : Vec A n) (i : Fin n) {x : A} →
                (xs [ i ]≔ x) [ i ]= x
  []≔-updates xs i = updateAt-updates i xs (lookup⇒[]= i xs refl)

  []≔-minimal : ∀ {n} (xs : Vec A n) (i j : Fin n) {x y : A} → i ≢ j →
                xs [ i ]= x → (xs [ j ]≔ y) [ i ]= x
  []≔-minimal xs i j i≢j loc = updateAt-minimal i j xs i≢j loc

  []≔-lookup : ∀ {n} (xs : Vec A n) (i : Fin n) →
               xs [ i ]≔ lookup i xs ≡ xs
  []≔-lookup xs i = updateAt-id-relative i xs refl

  lookup∘update : ∀ {n} (i : Fin n) (xs : Vec A n) x →
                  lookup i (xs [ i ]≔ x) ≡ x
  lookup∘update i xs x = lookup∘updateAt i xs

  lookup∘update′ : ∀ {n} {i j : Fin n} → i ≢ j → ∀ (xs : Vec A n) y →
                   lookup i (xs [ j ]≔ y) ≡ lookup i xs
  lookup∘update′ {n} {i} {j} i≢j xs y = lookup∘updateAt′ i j i≢j xs

------------------------------------------------------------------------
-- map

map-id : ∀ {a n} {A : Set a} → map {n = n} {A} id ≗ id
map-id []       = refl
map-id (x ∷ xs) = P.cong (x ∷_) (map-id xs)

map-cong : ∀ {a b n} {A : Set a} {B : Set b} {f g : A → B} →
           f ≗ g → map {n = n} f ≗ map g
map-cong f≗g []       = refl
map-cong f≗g (x ∷ xs) = P.cong₂ _∷_ (f≗g x) (map-cong f≗g xs)

map-∘ : ∀ {a b c n} {A : Set a} {B : Set b} {C : Set c}
        (f : B → C) (g : A → B) →
        map {n = n} (f ∘ g) ≗ map f ∘ map g
map-∘ f g []       = refl
map-∘ f g (x ∷ xs) = P.cong (f (g x) ∷_) (map-∘ f g xs)

lookup-map : ∀ {a b n} {A : Set a} {B : Set b}
             (i : Fin n) (f : A → B) (xs : Vec A n) →
             lookup i (map f xs) ≡ f (lookup i xs)
lookup-map zero    f (x ∷ xs) = refl
lookup-map (suc i) f (x ∷ xs) = lookup-map i f xs

map-updateAt : ∀ {n a b} {A : Set a} {B : Set b} →
  ∀ {f : A → B} {g : A → A} {h : B → B} (xs : Vec A n) (i : Fin n)
  → f (g (lookup i xs)) ≡ h (f (lookup i xs))
  → map f (updateAt i g xs) ≡ updateAt i h (map f xs)
map-updateAt (x ∷ xs) zero    eq = P.cong (_∷ _) eq
map-updateAt (x ∷ xs) (suc i) eq = P.cong (_ ∷_) (map-updateAt xs i eq)

map-[]≔ : ∀ {n a b} {A : Set a} {B : Set b}
          (f : A → B) (xs : Vec A n) (i : Fin n) {x : A} →
          map f (xs [ i ]≔ x) ≡ map f xs [ i ]≔ f x
map-[]≔ f xs i = map-updateAt xs i refl

------------------------------------------------------------------------
-- _++_

module _ {a} {A : Set a} {m} {ys ys' : Vec A m} where

  -- See also Data.Vec.Properties.WithK.++-assoc.

  ++-injectiveˡ : ∀ {n} (xs xs' : Vec A n) →
                  xs ++ ys ≡ xs' ++ ys' → xs ≡ xs'
  ++-injectiveˡ []       []         _  = refl
  ++-injectiveˡ (x ∷ xs) (x' ∷ xs') eq =
    P.cong₂ _∷_ (∷-injectiveˡ eq) (++-injectiveˡ _ _ (∷-injectiveʳ eq))

  ++-injectiveʳ : ∀ {n} (xs xs' : Vec A n) →
                  xs ++ ys ≡ xs' ++ ys' → ys ≡ ys'
  ++-injectiveʳ []       []         eq = eq
  ++-injectiveʳ (x ∷ xs) (x' ∷ xs') eq =
    ++-injectiveʳ xs xs' (∷-injectiveʳ eq)

  ++-injective  : ∀ {n} (xs xs' : Vec A n) →
                  xs ++ ys ≡ xs' ++ ys' → xs ≡ xs' × ys ≡ ys'
  ++-injective xs xs' eq =
    (++-injectiveˡ xs xs' eq , ++-injectiveʳ xs xs' eq)

module _ {a} {A : Set a} where

  lookup-++-< : ∀ {m n} (xs : Vec A m) (ys : Vec A n) →
                ∀ i (i<m : toℕ i < m) →
                lookup i (xs ++ ys) ≡ lookup (Fin.fromℕ≤ i<m) xs
  lookup-++-< []       ys i       ()
  lookup-++-< (x ∷ xs) ys zero    (s≤s z≤n)       = refl
  lookup-++-< (x ∷ xs) ys (suc i) (s≤s (s≤s i<m)) =
    lookup-++-< xs ys i (s≤s i<m)

  lookup-++-≥ : ∀ {m n} (xs : Vec A m) (ys : Vec A n) →
                ∀ i (i≥m : toℕ i ≥ m) →
                lookup i (xs ++ ys) ≡ lookup (Fin.reduce≥ i i≥m) ys
  lookup-++-≥ []       ys i       i≥m       = refl
  lookup-++-≥ (x ∷ xs) ys zero    ()
  lookup-++-≥ (x ∷ xs) ys (suc i) (s≤s i≥m) = lookup-++-≥ xs ys i i≥m

  lookup-++-inject+ : ∀ {m n} (xs : Vec A m) (ys : Vec A n) i →
                      lookup (Fin.inject+ n i) (xs ++ ys) ≡ lookup i xs
  lookup-++-inject+ []       ys ()
  lookup-++-inject+ (x ∷ xs) ys zero    = refl
  lookup-++-inject+ (x ∷ xs) ys (suc i) = lookup-++-inject+ xs ys i

  lookup-++-+′ : ∀ {m n} (xs : Vec A m) (ys : Vec A n) i →
                 lookup (fromℕ m +′ i) (xs ++ ys) ≡ lookup i ys
  lookup-++-+′ []       ys       zero    = refl
  lookup-++-+′ []       (y ∷ xs) (suc i) = lookup-++-+′ [] xs i
  lookup-++-+′ (x ∷ xs) ys       i       = lookup-++-+′ xs ys i

  []≔-++-inject+ : ∀ {m n x} (xs : Vec A m) (ys : Vec A n) i →
                   (xs ++ ys) [ Fin.inject+ n i ]≔ x ≡ (xs [ i ]≔ x) ++ ys
  []≔-++-inject+ []       ys ()
  []≔-++-inject+ (x ∷ xs) ys zero    = refl
  []≔-++-inject+ (x ∷ xs) ys (suc i) =
    P.cong (x ∷_) $ []≔-++-inject+ xs ys i

------------------------------------------------------------------------
-- zipWith

module _ {a} {A : Set a} {f : A → A → A} where

  zipWith-assoc : Associative _≡_ f → ∀ {n} →
                  Associative _≡_ (zipWith {n = n} f)
  zipWith-assoc assoc []       []       []       = refl
  zipWith-assoc assoc (x ∷ xs) (y ∷ ys) (z ∷ zs) =
    P.cong₂ _∷_ (assoc x y z) (zipWith-assoc assoc xs ys zs)

  zipWith-idem : Idempotent _≡_ f → ∀ {n} →
                 Idempotent _≡_ (zipWith {n = n} f)
  zipWith-idem idem []       = refl
  zipWith-idem idem (x ∷ xs) =
    P.cong₂ _∷_ (idem x) (zipWith-idem idem xs)

  zipWith-identityˡ : ∀ {1#} → LeftIdentity _≡_ 1# f → ∀ {n} →
                      LeftIdentity _≡_ (replicate 1#) (zipWith {n = n} f)
  zipWith-identityˡ idˡ []       = refl
  zipWith-identityˡ idˡ (x ∷ xs) =
    P.cong₂ _∷_ (idˡ x) (zipWith-identityˡ idˡ xs)

  zipWith-identityʳ : ∀ {1#} → RightIdentity _≡_ 1# f → ∀ {n} →
                      RightIdentity _≡_ (replicate 1#) (zipWith {n = n} f)
  zipWith-identityʳ idʳ []       = refl
  zipWith-identityʳ idʳ (x ∷ xs) =
    P.cong₂ _∷_ (idʳ x) (zipWith-identityʳ idʳ xs)

  zipWith-zeroˡ : ∀ {0#} → LeftZero _≡_ 0# f → ∀ {n} →
                  LeftZero _≡_ (replicate 0#) (zipWith {n = n} f)
  zipWith-zeroˡ zeˡ []       = refl
  zipWith-zeroˡ zeˡ (x ∷ xs) =
    P.cong₂ _∷_ (zeˡ x) (zipWith-zeroˡ zeˡ xs)

  zipWith-zeroʳ : ∀ {0#} → RightZero _≡_ 0# f → ∀ {n} →
                  RightZero _≡_ (replicate 0#) (zipWith {n = n} f)
  zipWith-zeroʳ zeʳ []       = refl
  zipWith-zeroʳ zeʳ (x ∷ xs) =
    P.cong₂ _∷_ (zeʳ x) (zipWith-zeroʳ zeʳ xs)

  zipWith-inverseˡ : ∀ {⁻¹ 0#} → LeftInverse _≡_ 0# ⁻¹ f → ∀ {n} →
                     LeftInverse _≡_ (replicate {n = n} 0#) (map ⁻¹) (zipWith f)
  zipWith-inverseˡ invˡ []       = refl
  zipWith-inverseˡ invˡ (x ∷ xs) =
    P.cong₂ _∷_ (invˡ x) (zipWith-inverseˡ invˡ xs)

  zipWith-inverseʳ : ∀ {⁻¹ 0#} → RightInverse _≡_ 0# ⁻¹ f → ∀ {n} →
                     RightInverse _≡_ (replicate {n = n} 0#) (map ⁻¹) (zipWith f)
  zipWith-inverseʳ invʳ []       = refl
  zipWith-inverseʳ invʳ (x ∷ xs) =
    P.cong₂ _∷_ (invʳ x) (zipWith-inverseʳ invʳ xs)

  zipWith-distribˡ : ∀ {g} → _DistributesOverˡ_ _≡_ f g → ∀ {n} →
                     _DistributesOverˡ_ _≡_ (zipWith {n = n} f) (zipWith g)
  zipWith-distribˡ distribˡ []        []      []       = refl
  zipWith-distribˡ distribˡ (x ∷ xs) (y ∷ ys) (z ∷ zs) =
    P.cong₂ _∷_ (distribˡ x y z) (zipWith-distribˡ distribˡ xs ys zs)

  zipWith-distribʳ : ∀ {g} → _DistributesOverʳ_ _≡_ f g → ∀ {n} →
                     _DistributesOverʳ_ _≡_ (zipWith {n = n} f) (zipWith g)
  zipWith-distribʳ distribʳ []        []      []       = refl
  zipWith-distribʳ distribʳ (x ∷ xs) (y ∷ ys) (z ∷ zs) =
    P.cong₂ _∷_ (distribʳ x y z) (zipWith-distribʳ distribʳ xs ys zs)

  zipWith-absorbs : ∀ {g} → _Absorbs_ _≡_ f g → ∀ {n} →
                   _Absorbs_ _≡_ (zipWith {n = n} f) (zipWith g)
  zipWith-absorbs abs []       []       = refl
  zipWith-absorbs abs (x ∷ xs) (y ∷ ys) =
    P.cong₂ _∷_ (abs x y) (zipWith-absorbs abs xs ys)

module _ {a b} {A : Set a} {B : Set b} {f : A → A → B} where

  zipWith-comm : (∀ x y → f x y ≡ f y x) → ∀ {n}
                 (xs ys : Vec A n) → zipWith f xs ys ≡ zipWith f ys xs
  zipWith-comm comm []       []       = refl
  zipWith-comm comm (x ∷ xs) (y ∷ ys) =
    P.cong₂ _∷_ (comm x y) (zipWith-comm comm xs ys)

module _ {a b c d} {A : Set a} {B : Set b} {C : Set c} {D : Set d} where

  zipWith-map₁ : ∀ {n} (_⊕_ : B → C → D) (f : A → B)
                 (xs : Vec A n) (ys : Vec C n) →
                 zipWith _⊕_ (map f xs) ys ≡ zipWith (λ x y → f x ⊕ y) xs ys
  zipWith-map₁ _⊕_ f []       []       = refl
  zipWith-map₁ _⊕_ f (x ∷ xs) (y ∷ ys) =
    P.cong (f x ⊕ y ∷_) (zipWith-map₁ _⊕_ f xs ys)

  zipWith-map₂ : ∀ {n} (_⊕_ : A → C → D) (f : B → C)
                 (xs : Vec A n) (ys : Vec B n) →
                 zipWith _⊕_ xs (map f ys) ≡ zipWith (λ x y → x ⊕ f y) xs ys
  zipWith-map₂ _⊕_ f []       []       = refl
  zipWith-map₂ _⊕_ f (x ∷ xs) (y ∷ ys) =
    P.cong (x ⊕ f y ∷_) (zipWith-map₂ _⊕_ f xs ys)

module _ {a b c} {A : Set a} {B : Set b} {C : Set c} where

  lookup-zipWith : ∀ (f : A → B → C) {n} (i : Fin n) xs ys →
                   lookup i (zipWith f xs ys) ≡ f (lookup i xs) (lookup i ys)
  lookup-zipWith _ zero    (x ∷ _)  (y ∷ _)   = refl
  lookup-zipWith _ (suc i) (_ ∷ xs) (_ ∷ ys)  = lookup-zipWith _ i xs ys

------------------------------------------------------------------------
-- zip

module _ {a b} {A : Set a} {B : Set b} where

  lookup-zip : ∀ {n} (i : Fin n) (xs : Vec A n) (ys : Vec B n) →
               lookup i (zip xs ys) ≡ (lookup i xs , lookup i ys)
  lookup-zip = lookup-zipWith _,_

  -- map lifts projections to vectors of products.

  map-proj₁-zip : ∀ {n} (xs : Vec A n) (ys : Vec B n) →
                  map proj₁ (zip xs ys) ≡ xs
  map-proj₁-zip []       []       = refl
  map-proj₁-zip (x ∷ xs) (y ∷ ys) = P.cong (x ∷_) (map-proj₁-zip xs ys)

  map-proj₂-zip : ∀ {n} (xs : Vec A n) (ys : Vec B n) →
                  map proj₂ (zip xs ys) ≡ ys
  map-proj₂-zip []       []       = refl
  map-proj₂-zip (x ∷ xs) (y ∷ ys) = P.cong (y ∷_) (map-proj₂-zip xs ys)

-- map lifts pairing to vectors of products.

map-<,>-zip : ∀ {a b c n} {A : Set a} {B : Set b} {C : Set c}
              (f : A → B) (g : A → C) (xs : Vec A n) →
              map < f , g > xs ≡ zip (map f xs) (map g xs)
map-<,>-zip f g []       = P.refl
map-<,>-zip f g (x ∷ xs) = P.cong (_ ∷_) (map-<,>-zip f g xs)

map-zip : ∀ {a b c d n} {A : Set a} {B : Set b} {C : Set c} {D : Set d}
          (f : A → B) (g : C → D) (xs : Vec A n) (ys : Vec C n) →
          map (Prod.map f g) (zip xs ys) ≡ zip (map f xs) (map g ys)
map-zip f g []       []       = refl
map-zip f g (x ∷ xs) (y ∷ ys) = P.cong (_ ∷_) (map-zip f g xs ys)

------------------------------------------------------------------------
-- unzip

module _ {a b} {A : Set a} {B : Set b} where

  lookup-unzip : ∀ {n} (i : Fin n) (xys : Vec (A × B) n) →
                 let xs , ys = unzip xys
                 in (lookup i xs , lookup i ys) ≡ lookup i xys
  lookup-unzip ()      []
  lookup-unzip zero    ((x , y) ∷ xys) = refl
  lookup-unzip (suc i) ((x , y) ∷ xys) = lookup-unzip i xys

  map-unzip : ∀ {c d n} {C : Set c} {D : Set d}
              (f : A → B) (g : C → D) (xys : Vec (A × C) n) →
              let xs , ys = unzip xys
              in (map f xs , map g ys) ≡ unzip (map (Prod.map f g) xys)
  map-unzip f g []              = refl
  map-unzip f g ((x , y) ∷ xys) =
    P.cong (Prod.map (f x ∷_) (g y ∷_)) (map-unzip f g xys)

  -- Products of vectors are isomorphic to vectors of products.

  unzip∘zip : ∀ {n} (xs : Vec A n) (ys : Vec B n) →
              unzip (zip xs ys) ≡ (xs , ys)
  unzip∘zip [] []             = refl
  unzip∘zip (x ∷ xs) (y ∷ ys) =
    P.cong (Prod.map (x ∷_) (y ∷_)) (unzip∘zip xs ys)

  zip∘unzip : ∀ {n} (xys : Vec (A × B) n) →
              uncurry zip (unzip xys) ≡ xys
  zip∘unzip []              = refl
  zip∘unzip ((x , y) ∷ xys) = P.cong ((x , y) ∷_) (zip∘unzip xys)

  ×v↔v× : ∀ {n} → (Vec A n × Vec B n) ↔ Vec (A × B) n
  ×v↔v× = inverse (uncurry zip) unzip (uncurry unzip∘zip) zip∘unzip

------------------------------------------------------------------------
-- _⊛_

module _ {a b} {A : Set a} {B : Set b} where

  lookup-⊛ : ∀ {n} i (fs : Vec (A → B) n) (xs : Vec A n) →
             lookup i (fs ⊛ xs) ≡ (lookup i fs $ lookup i xs)
  lookup-⊛ zero    (f ∷ fs) (x ∷ xs) = refl
  lookup-⊛ (suc i) (f ∷ fs) (x ∷ xs) = lookup-⊛ i fs xs

  map-is-⊛ : ∀ {n} (f : A → B) (xs : Vec A n) →
             map f xs ≡ (replicate f ⊛ xs)
  map-is-⊛ f []       = refl
  map-is-⊛ f (x ∷ xs) = P.cong (_ ∷_) (map-is-⊛ f xs)

  ⊛-is-zipWith : ∀ {n} (fs : Vec (A → B) n) (xs : Vec A n) →
                 (fs ⊛ xs) ≡ zipWith _$_ fs xs
  ⊛-is-zipWith []       []       = refl
  ⊛-is-zipWith (f ∷ fs) (x ∷ xs) = P.cong (f x ∷_) (⊛-is-zipWith fs xs)

  zipWith-is-⊛ : ∀ {c} {C : Set c} {n} (f : A → B → C) →
                 (xs : Vec A n) (ys : Vec B n) →
                 zipWith f xs ys ≡ (replicate f ⊛ xs ⊛ ys)
  zipWith-is-⊛ f []       []       = refl
  zipWith-is-⊛ f (x ∷ xs) (y ∷ ys) = P.cong (_ ∷_) (zipWith-is-⊛ f xs ys)

------------------------------------------------------------------------
-- foldr

-- See also Data.Vec.Properties.WithK.foldr-cong.

-- The (uniqueness part of the) universality property for foldr.

foldr-universal : ∀ {a b} {A : Set a} (B : ℕ → Set b)
                  (f : ∀ {n} → A → B n → B (suc n)) {e}
                  (h : ∀ {n} → Vec A n → B n) →
                  h [] ≡ e →
                  (∀ {n} x → h ∘ (x ∷_) ≗ f {n} x ∘ h) →
                  ∀ {n} → h ≗ foldr B {n} f e
foldr-universal B f {_} h base step []       = base
foldr-universal B f {e} h base step (x ∷ xs) = begin
  h (x ∷ xs)
    ≡⟨ step x xs ⟩
  f x (h xs)
    ≡⟨ P.cong (f x) (foldr-universal B f h base step xs) ⟩
  f x (foldr B f e xs)
    ∎
  where open P.≡-Reasoning

foldr-fusion : ∀ {a b c} {A : Set a}
               {B : ℕ → Set b} {f : ∀ {n} → A → B n → B (suc n)} e
               {C : ℕ → Set c} {g : ∀ {n} → A → C n → C (suc n)}
               (h : ∀ {n} → B n → C n) →
               (∀ {n} x → h ∘ f {n} x ≗ g x ∘ h) →
               ∀ {n} → h ∘ foldr B {n} f e ≗ foldr C g (h e)
foldr-fusion {B = B} {f} e {C} h fuse =
  foldr-universal C _ _ refl (λ x xs → fuse x (foldr B f e xs))

idIsFold : ∀ {a n} {A : Set a} → id ≗ foldr (Vec A) {n} _∷_ []
idIsFold = foldr-universal _ _ id refl (λ _ _ → refl)

------------------------------------------------------------------------
-- sum

sum-++-commute : ∀ {m n} (xs : Vec ℕ m) {ys : Vec ℕ n} →
                 sum (xs ++ ys) ≡ sum xs + sum ys
sum-++-commute []       {_}  = refl
sum-++-commute (x ∷ xs) {ys} = begin
  x + sum (xs ++ ys)     ≡⟨ P.cong (x +_) (sum-++-commute xs) ⟩
  x + (sum xs + sum ys)  ≡⟨ P.sym (+-assoc x (sum xs) (sum ys)) ⟩
  sum (x ∷ xs) + sum ys  ∎
  where open P.≡-Reasoning

------------------------------------------------------------------------
-- replicate

lookup-replicate : ∀ {a n} {A : Set a} (i : Fin n) (x : A) →
                   lookup i (replicate x) ≡ x
lookup-replicate zero    = λ _ → refl
lookup-replicate (suc i) = lookup-replicate i

map-replicate :  ∀ {a b} {A : Set a} {B : Set b} (f : A → B) (x : A) →
                 ∀ n → map f (replicate x) ≡ replicate {n = n} (f x)
map-replicate f x zero = refl
map-replicate f x (suc n) = P.cong (f x ∷_) (map-replicate f x n)

module _ {a b c} {A : Set a} {B : Set b} {C : Set c} where

  zipWith-replicate₁ : ∀ {n} (_⊕_ : A → B → C) (x : A) (ys : Vec B n) →
                     zipWith _⊕_ (replicate x) ys ≡ map (x ⊕_) ys
  zipWith-replicate₁ _⊕_ x []       = refl
  zipWith-replicate₁ _⊕_ x (y ∷ ys) =
    P.cong (x ⊕ y ∷_) (zipWith-replicate₁ _⊕_ x ys)

  zipWith-replicate₂ : ∀ {n} (_⊕_ : A → B → C) (xs : Vec A n) (y : B) →
                     zipWith _⊕_ xs (replicate y) ≡ map (_⊕ y) xs
  zipWith-replicate₂ _⊕_ []       y = refl
  zipWith-replicate₂ _⊕_ (x ∷ xs) y =
    P.cong (x ⊕ y ∷_) (zipWith-replicate₂ _⊕_ xs y)

------------------------------------------------------------------------
-- tabulate

lookup∘tabulate : ∀ {a n} {A : Set a} (f : Fin n → A) (i : Fin n) →
                  lookup i (tabulate f) ≡ f i
lookup∘tabulate f zero    = refl
lookup∘tabulate f (suc i) = lookup∘tabulate (f ∘ suc) i

tabulate∘lookup : ∀ {a n} {A : Set a} (xs : Vec A n) →
                  tabulate (flip lookup xs) ≡ xs
tabulate∘lookup []       = refl
tabulate∘lookup (x ∷ xs) = P.cong (x ∷_) (tabulate∘lookup xs)

tabulate-∘ : ∀ {n a b} {A : Set a} {B : Set b}
             (f : A → B) (g : Fin n → A) →
             tabulate (f ∘ g) ≡ map f (tabulate g)
tabulate-∘ {zero}  f g = refl
tabulate-∘ {suc n} f g = P.cong (f (g zero) ∷_) (tabulate-∘ f (g ∘ suc))

tabulate-cong : ∀ {n a} {A : Set a} {f g : Fin n → A} → f ≗ g → tabulate f ≡ tabulate g
tabulate-cong {zero} p = refl
tabulate-cong {suc n} p = P.cong₂ _∷_ (p zero) (tabulate-cong (p ∘ suc))

------------------------------------------------------------------------
-- allFin

lookup-allFin : ∀ {n} (i : Fin n) → lookup i (allFin n) ≡ i
lookup-allFin = lookup∘tabulate id

allFin-map : ∀ n → allFin (suc n) ≡ zero ∷ map suc (allFin n)
allFin-map n = P.cong (zero ∷_) $ tabulate-∘ suc id

tabulate-allFin : ∀ {n a} {A : Set a} (f : Fin n → A) →
                  tabulate f ≡ map f (allFin n)
tabulate-allFin f = tabulate-∘ f id

-- If you look up every possible index, in increasing order, then you
-- get back the vector you started with.

map-lookup-allFin : ∀ {a} {A : Set a} {n} (xs : Vec A n) →
                    map (λ x → lookup x xs) (allFin n) ≡ xs
map-lookup-allFin {n = n} xs = begin
  map (λ x → lookup x xs) (allFin n) ≡⟨ P.sym $ tabulate-∘ (λ x → lookup x xs) id ⟩
  tabulate (λ x → lookup x xs)       ≡⟨ tabulate∘lookup xs ⟩
  xs                                 ∎
  where open P.≡-Reasoning

------------------------------------------------------------------------
-- count

module _ {a p} {A : Set a} {P : Pred A p} (P? : Decidable P) where

  count≤n : ∀ {n} (xs : Vec A n) → count P? xs ≤ n
  count≤n []       = z≤n
  count≤n (x ∷ xs) with P? x
  ... | yes _ = s≤s (count≤n xs)
  ... | no  _ = ≤-step (count≤n xs)

------------------------------------------------------------------------
-- insert

module _ {a} {A : Set a} where

  insert-lookup : ∀ {n} (i : Fin (suc n)) (x : A)
                  (xs : Vec A n) → lookup i (insert i x xs) ≡ x
  insert-lookup zero x xs = refl
  insert-lookup (suc ()) x []
  insert-lookup (suc i) x (y ∷ xs) = insert-lookup i x xs

  insert-punchIn : ∀ {n} (i : Fin (suc n)) (x : A) (xs : Vec A n)
                   (j : Fin n) →
                   lookup (Fin.punchIn i j) (insert i x xs) ≡ lookup j xs
  insert-punchIn zero x xs j = refl
  insert-punchIn (suc ()) x [] j
  insert-punchIn (suc i) x (y ∷ xs) zero = refl
  insert-punchIn (suc i) x (y ∷ xs) (suc j) = insert-punchIn i x xs j

  remove-punchOut : ∀ {n} (xs : Vec A (suc n))
                    {i : Fin (suc n)} {j : Fin (suc n)} (i≢j : i ≢ j) →
                    lookup (Fin.punchOut i≢j) (remove i xs) ≡ lookup j xs
  remove-punchOut (x ∷ xs) {zero} {zero} i≢j = ⊥-elim (i≢j refl)
  remove-punchOut (x ∷ xs) {zero} {suc j} i≢j = refl
  remove-punchOut (x ∷ []) {suc ()} {j} i≢j
  remove-punchOut (x ∷ y ∷ xs) {suc i} {zero} i≢j = refl
  remove-punchOut (x ∷ y ∷ xs) {suc i} {suc j} i≢j =
    remove-punchOut (y ∷ xs) (i≢j ∘ P.cong suc)

------------------------------------------------------------------------
-- remove

  remove-insert : ∀ {n} (i : Fin (suc n)) (x : A) (xs : Vec A n) →
                  remove i (insert i x xs) ≡ xs
  remove-insert zero x xs = refl
  remove-insert (suc ()) x []
  remove-insert (suc zero) x (y ∷ xs) = refl
  remove-insert (suc (suc ())) x (y ∷ [])
  remove-insert (suc (suc i)) x (y ∷ z ∷ xs) =
    P.cong (y ∷_) (remove-insert (suc i) x (z ∷ xs))

  insert-remove : ∀ {n} (i : Fin (suc n)) (xs : Vec A (suc n)) →
                  insert i (lookup i xs) (remove i xs) ≡ xs
  insert-remove zero (x ∷ xs) = refl
  insert-remove (suc ()) (x ∷ [])
  insert-remove (suc i) (x ∷ y ∷ xs) =
    P.cong (x ∷_) (insert-remove i (y ∷ xs))

------------------------------------------------------------------------
-- Conversion function

module _ {a} {A : Set a} where

  toList∘fromList : (xs : List A) → toList (fromList xs) ≡ xs
  toList∘fromList List.[]       = refl
  toList∘fromList (x List.∷ xs) = P.cong (x List.∷_) (toList∘fromList xs)
