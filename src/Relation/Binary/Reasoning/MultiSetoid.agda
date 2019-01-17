------------------------------------------------------------------------
-- The Agda standard library
--
-- Convenient syntax for "equational reasoning" in multiple Setoids
------------------------------------------------------------------------

-- Example use:
--
--   open import Data.Maybe
--   import Relation.Binary.Reasoning.MultiSetoid as SetR
--
--   begin⟨ S ⟩
--     x
--       ≈⟨ drop-just (begin⟨ setoid S ⟩
--          just x
--            ≈⟨ justx≈mz ⟩
--          mz
--            ≈⟨ mz≈justy ⟩
--          just y ∎) ⟩
--     y
--       ≈⟨ y≈z ⟩
--     z ∎

{-# OPTIONS --without-K --safe #-}

open import Relation.Binary
open import Relation.Binary.Reasoning.Setoid as EqR using (_IsRelatedTo_)
open import Relation.Binary.PropositionalEquality

open Setoid renaming (_≈_ to [_]_≈_)

module Relation.Binary.Reasoning.MultiSetoid where

infix 1 begin⟨_⟩_
infixr 2 _≈⟨_⟩_ _≡⟨_⟩_
infix 3 _∎

begin⟨_⟩_ : ∀ {c l} (S : Setoid c l) {x y} → _IsRelatedTo_ S x y → [ S ] x ≈ y
begin⟨_⟩_ S p = EqR.begin_ S p

_∎ : ∀ {c l} {S : Setoid c l} x → _IsRelatedTo_ S x x
_∎ {S = S} = EqR._∎ S

_≈⟨_⟩_ : ∀ {c l} {S : Setoid c l} x {y z} → [ S ] x ≈ y → _IsRelatedTo_ S y z → _IsRelatedTo_ S x z
_≈⟨_⟩_ {S = S} = EqR._≈⟨_⟩_ S

_≡⟨_⟩_ : ∀ {c l} {S : Setoid c l} x {y z} → x ≡ y → _IsRelatedTo_ S y z → _IsRelatedTo_ S x z
_≡⟨_⟩_ {S = S} = EqR._≡⟨_⟩_ S
