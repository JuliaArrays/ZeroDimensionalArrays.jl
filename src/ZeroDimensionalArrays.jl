module ZeroDimensionalArrays

export
    ZeroDimArray,
    ZeroDimArrayInTypeParameter,
    Box,
    BoxConst

abstract type AbstractZeroDimensionalArray{T} <: AbstractArray{T, 0} end

struct ZeroDimArray{T} <: AbstractZeroDimensionalArray{T}
    v::T
    global function new_zero_dimensional_array_immutable(::Type{T}, v) where {T}
        new{T}(v)
    end
end

mutable struct Box{T} <: AbstractZeroDimensionalArray{T}
    v::T
    global function new_zero_dimensional_array_mutable(::Type{T}, v) where {T}
        new{T}(v)
    end
    global function new_zero_dimensional_array_mutable_undef(::Type{T}) where {T}
        new{T}()
    end
end

mutable struct BoxConst{T} <: AbstractZeroDimensionalArray{T}
    const v::T
    global function new_zero_dimensional_array_mutable_const_field(::Type{T}, v) where {T}
        new{T}(v)
    end
end

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
