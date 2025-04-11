# ZeroDimensionalArrays

[![Build Status](https://github.com/JuliaArrays/ZeroDimensionalArrays.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaArrays/ZeroDimensionalArrays.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Package version](https://juliahub.com/docs/General/ZeroDimensionalArrays/stable/version.svg)](https://juliahub.com/ui/Packages/General/ZeroDimensionalArrays)
[![Package dependencies](https://juliahub.com/docs/General/ZeroDimensionalArrays/stable/deps.svg)](https://juliahub.com/ui/Packages/General/ZeroDimensionalArrays?t=2)
[![PkgEval](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/Z/ZeroDimensionalArrays.svg)](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/Z/ZeroDimensionalArrays.html)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

A small software package for the Julia programming language providing zero-dimensional array types. `Ref`-killer.

Exports three zero-dimensional subtypes of `AbstractArray`:
* `ZeroDimensionalArrayImmutable`
    * declared with `struct`, not with `mutable struct`
    * does not support `setfield!`, or mutating the element otherwise
    * `isbits` when the element is `isbits`
* `Box`
    * declared with `mutable struct`
    * supports `setfield!`
* `BoxConstField`
    * declared with `mutable struct`
    * does not support `setfield!`, or mutating the element otherwise
    * included for completeness, but not likely to be useful often

The motivation for creating this package is:
* To prevent the frequent confusion regarding `Ref` vs `Base.RefValue` by offering a replacement that makes `Ref` unnecessary in many use cases. Previous discussion:
    * https://github.com/JuliaLang/julia/issues/38133
    * https://github.com/JuliaLang/julia/issues/55321
    * https://discourse.julialang.org/t/ref-is-not-a-concrete-type-poorly-documented/120375
    * https://discourse.julialang.org/t/ref-t-vs-base-refvalue-t/127886/
* To provide "mutable wrapper" functionality, something `Ref` is often used for:
    * `Box` can be a good replacement. Examples:
        * make a `const` binding that's mutable:
          ```julia
          const some_const_binding = Box(0.2)
          ```
        * make a field within an immutable `struct` mutable (warning: it's usually more efficient to change the entire `struct` into a `mutable struct`)
          ```julia
          struct SomeImmutableType
              immutable_bool::Bool
              immutable_float::Float64
              mutable_int::Box{Int}
          end
          ```
    * previous discussion:
        * https://github.com/JuliaLang/julia/issues/40369
        * https://discourse.julialang.org/t/dynamic-immutable-type/127168
* to provide a wrapper type for treating a value as a scalar in broadcasting, something `Ref` is often used for:
    * `ZeroDimensionalArrayImmutable` can be a good replacement:
      ```julia-repl
      julia> using ZeroDimensionalArrays

      julia> isa.(ZeroDimensionalArrayImmutable([1,2,3]), [Array, Dict, Int])
      3-element BitVector:
       1
       0
       0
      ```
