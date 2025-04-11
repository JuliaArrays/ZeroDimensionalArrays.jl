# ZeroDimensionalArrays

[![Build Status](https://github.com/JuliaArrays/ZeroDimensionalArrays.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaArrays/ZeroDimensionalArrays.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Package version](https://juliahub.com/docs/General/ZeroDimensionalArrays/stable/version.svg)](https://juliahub.com/ui/Packages/General/ZeroDimensionalArrays)
[![Package dependencies](https://juliahub.com/docs/General/ZeroDimensionalArrays/stable/deps.svg)](https://juliahub.com/ui/Packages/General/ZeroDimensionalArrays?t=2)
[![PkgEval](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/Z/ZeroDimensionalArrays.svg)](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/Z/ZeroDimensionalArrays.html)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

A tiny software package for the Julia programming language, providing zero-dimensional array types. `Ref`-killer.

Exports these zero-dimensional subtypes of `AbstractArray`, differing on topics such as mutability and identity:
* `ZeroDimArray`
    * declared with `struct`, not with `mutable struct`
    * does not support `setfield!`, or mutating the element otherwise
    * `isbits` when the element is `isbits`
* `Box`
    * declared with `mutable struct`
    * supports `setfield!` for mutating the element
    * acts as a reference to its element
* `BoxConst`
    * declared with `mutable struct`
    * does not support `setfield!`, or mutating the element otherwise
    * acts as a reference to its element

Any zero-dimensional array is an iterator containing exactly one element (this follows from the zero-dimensional shape). `Ref`, too, is a zero-dimensional iterator, however it's not an array. Even though `Ref` supports being indexed like a zero-dimensional array is commonly indexed, without an index: `x[]`.

The motivation for creating this package is:
* To prevent the frequent confusion regarding `Ref` vs `Base.RefValue` by offering a replacement that makes `Ref` unnecessary in many use cases. Previous discussion:
    * https://github.com/JuliaLang/julia/issues/38133
    * https://github.com/JuliaLang/julia/issues/55321
    * https://discourse.julialang.org/t/ref-is-not-a-concrete-type-poorly-documented/120375
    * https://discourse.julialang.org/t/understanding-type-ref-t/107711
    * https://discourse.julialang.org/t/ref-t-vs-base-refvalue-t/127886
* To provide "mutable wrapper" functionality:
    * `Box` can be a good choice. Examples:
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
* To provide a [*boxing*](https://en.wikipedia.org/wiki/Boxing_(computer_programming)) feature, for example for data deduplication to avoid excessive memory use. Either `Box` or `BoxConst` might be a good choice here, depending on whether mutability is desired. Compare:
    * ```julia-repl
      julia> large_data = ntuple(identity, 8)
      (1, 2, 3, 4, 5, 6, 7, 8)

      julia> for _ ∈ 1:4
                 large_data = (large_data, large_data)
             end

      julia> Base.summarysize(large_data)
      1024

      julia> Base.summarysize([large_data for _ ∈ 1:1000])  # duplicates `large_data` a thousand times
      1024040

      julia> using ZeroDimensionalArrays

      julia> large_data_reference = Box(large_data);

      julia> Base.summarysize([large_data_reference for _ ∈ 1:1000])  # `large_data` isn't stored inline
      9064
      ```
* To provide a wrapper type for treating a value as a scalar in broadcasting:
    * `ZeroDimArray` can be a good choice:
      ```julia-repl
      julia> using ZeroDimensionalArrays

      julia> isa.([1,2,3], [Array, Dict, Int])
      3-element BitVector:
       0
       0
       1

      julia> isa.(ZeroDimArray([1,2,3]), [Array, Dict, Int])  # now escape the vector from broadcasting using `ZeroDimArray`
      3-element BitVector:
       1
       0
       0
      ```
      The other types, `Box` or `BoxConst` would work for this use case, too, as would any zero-dimensional array, but `ZeroDimArray` is more likely to have zero cost for performance.
    * previous discussion regarding `Ref`:
        * https://discourse.julialang.org/t/ref-vs-zero-dimensional-arrays/24434

## Comparison with other potential solutions

* Zero-dimensional `Array`:
    * `fill(x)`, creating a zero-dimensional `Array` containing `x` as its element, is often used instead of `Ref(x)`.
    * `Array{T, 0} where {T}` is very similar to `Box`, albeit less efficient. The inefficiency is due to the fact that the implementation of `Array` supports resizeability (even though that's currently only available to users in the one-dimensional case of `Vector`), implying extra indirection, leading to extra pointer dereferences and extra allocation.
* [FixedSizeArrays.jl](https://github.com/JuliaArrays/FixedSizeArrays.jl):
    * Less heavy than `Array`, but still may be less efficient than `Box`.
* [FillArrays.jl](https://github.com/JuliaArrays/FillArrays.jl):
    * Zero-dimensional `Fill`, constructible with `Fill(x)`, is equivalent to `ZeroDimArray`.
