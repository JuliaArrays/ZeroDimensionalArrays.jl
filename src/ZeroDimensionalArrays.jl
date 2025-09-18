module ZeroDimensionalArrays

export
    ZeroDimArray,
    ZeroDimArrayInTypeParameter,
    Box,
    BoxConst

abstract type AbstractZeroDimensionalArray{T} <: AbstractArray{T, 0} end

"""
    ZeroDimArray

A collection type storing exactly one element. More precisely, a zero-dimensional
array, subtyping `AbstractArray{T, 0} where {T}`.

* Has a single type parameter:

    * `T`, the element type

* Construct like so:

    * `ZeroDimArray(element)`

    * `ZeroDimArray{T}(element)`

* Convert from other array types with `convert`.

* Access the element using `getindex`. Julia supports the square bracket syntax for
  `getindex`: `array[]` is equivalent to `getindex(array)`.

* After a `ZeroDimArray` is constructed, it is not possible to change the value of
  its element.

* Regarding layout in memory, a `ZeroDimArray` is a copy of its element.

* For any `x`, `ZeroDimArray(x) === ZeroDimArray(x)` holds.

* For any `x`, `isbits(ZeroDimArray(x))` as long as `isbits(x)`.

Other exported collection types:

* [`Box`](@ref)

* [`BoxConst`](@ref)

* [`ZeroDimArrayInTypeParameter`](@ref)
"""
struct ZeroDimArray{T} <: AbstractZeroDimensionalArray{T}
    v::T
    global function new_zero_dimensional_array_immutable(::Type{T}, v) where {T}
        new{T}(v)
    end
end

"""
    Box

A collection type storing exactly one element. More precisely, a zero-dimensional
array, subtyping `AbstractArray{T, 0} where {T}`.

* Has a single type parameter:

    * `T`, the element type

* Construct like so:

    * `Box(element)`

    * `Box{T}(element)`

* Convert from other array types with `convert`.

* After a `Box` is constructed, change the value of its element using `setindex!`.
  Julia supports the square bracket syntax for `setindex!`: `array[] = element` is
  equivalent to `setindex!(array, element)`.

* Regarding layout in memory, a `Box` is a reference to its element.

Other exported collection types:

* [`BoxConst`](@ref)

* [`ZeroDimArray`](@ref)

* [`ZeroDimArrayInTypeParameter`](@ref)
"""
mutable struct Box{T} <: AbstractZeroDimensionalArray{T}
    v::T
    global function new_zero_dimensional_array_mutable(::Type{T}, v) where {T}
        new{T}(v)
    end
    global function new_zero_dimensional_array_mutable_undef(::Type{T}) where {T}
        new{T}()
    end
end

"""
    BoxConst

A collection type storing exactly one element. More precisely, a zero-dimensional
array, subtyping `AbstractArray{T, 0} where {T}`.

* Has a single type parameter:

    * `T`, the element type

* Construct like so:

    * `BoxConst(element)`

    * `BoxConst{T}(element)`

* Convert from other array types with `convert`.

* Access the element using `getindex`. Julia supports the square bracket syntax for
  `getindex`: `array[]` is equivalent to `getindex(array)`.

* After a `BoxConst` is constructed, it is not possible to change the value of
  its element.

* Regarding layout in memory, a `BoxConst` is a reference to its element.

Other exported collection types:

* [`Box`](@ref)

* [`ZeroDimArray`](@ref)

* [`ZeroDimArrayInTypeParameter`](@ref)
"""
mutable struct BoxConst{T} <: AbstractZeroDimensionalArray{T}
    const v::T
    global function new_zero_dimensional_array_mutable_const_field(::Type{T}, v) where {T}
        new{T}(v)
    end
end

"""
    ZeroDimArrayInTypeParameter

A collection type storing exactly one element. More precisely, a zero-dimensional
array, subtyping `AbstractArray{T, 0} where {T}`.

* Has two type parameters:

    * `T`, the element type

    * `Value`, the element

* Construct like so:

    * `ZeroDimArrayInTypeParameter(element)`

    * `ZeroDimArrayInTypeParameter{T}(element)`

* Convert from other array types with `convert`.

* Access the element using `getindex`. Julia supports the square bracket syntax for
  `getindex`: `array[]` is equivalent to `getindex(array)`.

* After a `ZeroDimArrayInTypeParameter` is constructed, it is not possible to
  change the value of its element.

* As a `ZeroDimArrayInTypeParameter` stores its element in its type parameter, a
  call like `ZeroDimArrayInTypeParameter(x)` might throw in type application if
  Julia is not able to use `x` as a type parameter.

* For any `a`, `iszero(sizeof(a))` as long as `a isa ZeroDimArrayInTypeParameter`.

* For any `x`, `ZeroDimArrayInTypeParameter(x) === ZeroDimArrayInTypeParameter(x)`
  holds.

* For any `x`, `isbits(ZeroDimArrayInTypeParameter(x))` as long as
  `ZeroDimArrayInTypeParameter(x)` returns.

* For any `x`, `Base.issingletontype(typeof(ZeroDimArrayInTypeParameter(x)))` as
  long as `ZeroDimArrayInTypeParameter(x)` returns.

Other exported collection types:

* [`Box`](@ref)

* [`BoxConst`](@ref)

* [`ZeroDimArray`](@ref)
"""
struct ZeroDimArrayInTypeParameter{T, Value} <: AbstractZeroDimensionalArray{T}
    global function new_zero_dimensional_array_in_type_parameter(::Type{T}, v) where {T}
        u = if v isa T
            v
        else
            convert(T, v)::T
        end
        new{T, u}()
    end
end

const ZeroDimensionalArrayCanNotMutateElement = Union{
    ZeroDimArray,
    ZeroDimArrayInTypeParameter,
    BoxConst,
}

const ZeroDimensionalArray = Union{
    ZeroDimensionalArrayCanNotMutateElement,
    Box,
}

function type_to_constructor_function(::Type{T}) where {T <: ZeroDimensionalArray}
    local ret
    if T <: ZeroDimArray
        ret = new_zero_dimensional_array_immutable
    elseif T <: ZeroDimArrayInTypeParameter
        ret = new_zero_dimensional_array_in_type_parameter
    elseif T <: Box
        ret = new_zero_dimensional_array_mutable
    elseif T <: BoxConst
        ret = new_zero_dimensional_array_mutable_const_field
    end
    ret
end

Base.@nospecializeinfer function Base.propertynames(
    # the `unused` is here because of https://github.com/JuliaLang/julia/issues/44428
    (@nospecialize unused::ZeroDimensionalArray),
    ::Bool = false,
)
    ()
end

Base.@nospecializeinfer function Base.size(@nospecialize unused::ZeroDimensionalArray)
    ()
end

function Base.getindex(a::ZeroDimensionalArray)
    function get_param(::ZeroDimArrayInTypeParameter{<:Any, Value}) where {Value}
        Value
    end
    local ret
    if a isa Union{ZeroDimArray, Box, BoxConst}
        ret = a.v
    elseif a isa ZeroDimArrayInTypeParameter
        ret = get_param(a)
    end
    ret
end

# This method is redundant for correctness, but adding it helps achieve constprop, which
# helps `only(::ZeroDimensionalArray)` and `last(::ZeroDimensionalArray)`, for example.
Base.@constprop :aggressive function Base.getindex(a::ZeroDimensionalArray, i::Int)
    if !isone(i)
        throw(BoundsError())
    end
    a[]
end

function Base.setindex!(a::Box, x)
    a.v = x
end

Base.@nospecializeinfer function Base.isassigned((@nospecialize unused::ZeroDimensionalArray), i::Vararg{Integer})
    all(isone, i)
end

function Base.iterate(a::ZeroDimensionalArray)
    (a[], nothing)
end
Base.@nospecializeinfer function Base.iterate((@nospecialize a::ZeroDimensionalArray), @nospecialize state::Any)
    nothing
end

function Base.iterate(r::Iterators.Reverse{<:ZeroDimensionalArray})
    a = Iterators.reverse(r)
    iterate(a)
end
Base.@nospecializeinfer function Base.iterate((@nospecialize a::Iterators.Reverse{<:ZeroDimensionalArray}), @nospecialize state::Any)
    nothing
end

function construct_given_eltype(::Type{Arr}, ::Type{T}, v) where {Arr <: ZeroDimensionalArray, T}
    c = type_to_constructor_function(Arr)
    c(T, v)
end

function construct(::Type{Arr}, v) where {Arr <: ZeroDimensionalArray}
    T = if (Arr <: ZeroDimArrayInTypeParameter) && (v isa Type)
        Type{v}
    else
        typeof(v)
    end
    construct_given_eltype(Arr, T, v)
end

function convert_from_other_array_to_given_eltype(::Type{Arr}, ::Type{T}, a::AbstractArray{<:Any, 0}) where {Arr <: ZeroDimensionalArray, T}
    v = a[]
    construct_given_eltype(Arr, T, v)
end

function convert_from_other_array(::Type{Arr}, a::AbstractArray{<:Any, 0}) where {Arr <: ZeroDimensionalArray}
    T = eltype(a)
    convert_from_other_array_to_given_eltype(Arr, T, a)
end

function Base.copy(a::ZeroDimensionalArray)
    Arr = typeof(a)
    convert_from_other_array(Arr, a)
end

for Arr ∈ (
    ZeroDimArray,
    ZeroDimArrayInTypeParameter,
    Box,
    BoxConst,
)
    @eval begin
        function Base.convert(::Type{$Arr}, a::AbstractArray{<:Any, 0})
            convert_from_other_array($Arr, a)
        end
        function Base.convert(::Type{$Arr{T}}, a::AbstractArray{<:Any, 0}) where {T}
            convert_from_other_array_to_given_eltype($Arr, T, a)
        end
        function (::Type{$Arr})(v)
            construct($Arr, v)
        end
        function (::Type{$Arr{T}})(v) where {T}
            construct_given_eltype($Arr, T, v)
        end
    end
end

function Box{T}() where {T}
    new_zero_dimensional_array_mutable_undef(T)
end

function Base.similar((@nospecialize unused::ZeroDimensionalArray), ::Type{T}, ::Tuple{}) where {T}
    new_zero_dimensional_array_mutable_undef(T)
end

# TODO:
# ```julia
# function Base.similar((@nospecialize unused::ZeroDimensionalArray), ::Type{T}, size::Tuple{Vararg{Int}}) where {T}
#     FixedSizeArrayDefault{T}(undef, size)
# end
# ```

# https://github.com/JuliaLang/julia/issues/51753
if isdefined(Base, :dataids) && hasmethod(Base.dataids, Tuple{Box{Float32}})
    Base.@nospecializeinfer function Base.dataids((@nospecialize a::ZeroDimensionalArrayCanNotMutateElement),)
        ()
    end
end

end
