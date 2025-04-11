module ZeroDimensionalArrays

export
    ZeroDimensionalArrayImmutable,
    ZeroDimensionalArrayMutable,
    ZeroDimensionalArrayMutableConstField

struct ZeroDimensionalArrayImmutable{T} <: AbstractArray{T, 0}
    v::T
    global function new_zero_dimensional_array_immutable(::Type{T}, v) where {T}
        new{T}(v)
    end
end

mutable struct ZeroDimensionalArrayMutable{T} <: AbstractArray{T, 0}
    v::T
    global function new_zero_dimensional_array_mutable(::Type{T}, v) where {T}
        new{T}(v)
    end
    global function new_zero_dimensional_array_mutable_undef(::Type{T}) where {T}
        new{T}()
    end
end

mutable struct ZeroDimensionalArrayMutableConstField{T} <: AbstractArray{T, 0}
    const v::T
    global function new_zero_dimensional_array_mutable_const_field(::Type{T}, v) where {T}
        new{T}(v)
    end
end

const ZeroDimensionalArray = Union{
    ZeroDimensionalArrayImmutable,
    ZeroDimensionalArrayMutable,
    ZeroDimensionalArrayMutableConstField,
}

function type_to_constructor_function(::Type{T}) where {T <: ZeroDimensionalArray}
    if T <: ZeroDimensionalArrayImmutable
        new_zero_dimensional_array_immutable
    elseif T <: ZeroDimensionalArrayMutable
        new_zero_dimensional_array_mutable
    elseif T <: ZeroDimensionalArrayMutableConstField
        new_zero_dimensional_array_mutable_const_field
    else
        throw(ArgumentError("no such constructor function"))
    end
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
    a.v
end

function Base.setindex!(a::ZeroDimensionalArrayMutable, x)
    a.v = x
end

Base.@nospecializeinfer function Base.isassigned(@nospecialize unused::ZeroDimensionalArray)
    true
end

Base.@nospecializeinfer function Base.isassigned((@nospecialize unused::ZeroDimensionalArray), i::Int)
    isone(i)
end

function Base.only(a::ZeroDimensionalArray)
    a[]
end

function construct_given_eltype(::Type{Arr}, ::Type{T}, v) where {Arr <: ZeroDimensionalArray, T}
    c = type_to_constructor_function(Arr)
    c(T, v)
end

function construct(::Type{Arr}, v) where {Arr <: ZeroDimensionalArray}
    T = typeof(v)
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

for Arr ∈ (
    ZeroDimensionalArrayImmutable,
    ZeroDimensionalArrayMutable,
    ZeroDimensionalArrayMutableConstField,
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

function ZeroDimensionalArrayMutable{T}() where {T}
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
if isdefined(Base, :dataids) && hasmethod(Base.dataids, Tuple{ZeroDimensionalArrayMutable{Float32}})
    function Base.dataids(a::ZeroDimensionalArray)
        Base.dataids(only(a))
    end
end

end
