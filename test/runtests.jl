using ZeroDimensionalArrays
using Test
using Aqua: Aqua

@testset "ZeroDimensionalArrays.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(ZeroDimensionalArrays)
    end

    @testset "all array types joined" begin
        x = 0.3
        for Arr ∈ (
            ZeroDimArray,
            Box,
            BoxConst,
        )
            @test (@inferred Arr(x)) == (@inferred convert(Arr, fill(x)))
            @test isstructtype(Arr)
            @test Arr <: AbstractArray{<:Any, 0}
            @test (@inferred Arr(x)) isa Arr{typeof(x)}
            @test (@inferred convert(Arr, fill(x))) isa Arr{typeof(x)}
            @test (@inferred Arr{Float32}(x)) isa Arr{Float32}
            @test (@inferred convert(Arr{Float32}, fill(x))) isa Arr{Float32}
            @test () === @inferred propertynames(Arr(x))
            @test only(fill(x)) === @inferred only(Arr(x))
            @test last(fill(x)) === @inferred last(Arr(x))
            @test fill(x)[] === @inferred Arr(x)[]
            @test fill(x)[1] === @inferred Arr(x)[1]
            @test @inferred isassigned(Arr(x))
            @test @inferred isassigned(Arr(x), 1)
            @test !(isassigned(Arr(x), 2))
            for it ∈ (Arr(x), Iterators.reverse(Arr(x)))
                @test (@inferred iterate(it)) isa Tuple{typeof(x), Any}
                @test x === first(iterate(it))
                @test nothing === @inferred iterate(it, last(iterate(it)))
            end
            @test (@inferred similar(Arr(x))) isa Box{typeof(x)}
            @test (@inferred similar(Arr(x), Float32)) isa Box{Float32}
            @test (@inferred copy(Arr(x))) isa Arr{typeof(x)}
            @test (@inferred copy(Arr{AbstractFloat}(x))) isa Arr{AbstractFloat}
            @test let a = Arr(x)
                a == copy(a)
            end
            @test fill(x) == Arr(x)
            @test Arr(x) == Arr(x)
            @test all(@inferred Arr(x) .== Arr(x))
            @test (@inferred Arr(x) .+ [10, 20]) isa AbstractVector
        end
    end

    @testset "each array type on its own" begin
        @testset "`ZeroDimArray`" begin
            @test @isdefined ZeroDimArray
            @test !ismutabletype(ZeroDimArray)
            @test isbitstype(ZeroDimArray{Float64})
        end
        @testset "`Box`" begin
            @test @isdefined Box
            @test ismutabletype(Box)
            @test (@inferred Box{Float32}()) isa Box{Float32}
            @test let a = Box(0.3)
                a[] = 0.7
                only(a) === 0.7
            end
        end
        @testset "`BoxConst`" begin
            @test @isdefined BoxConst
            @test ismutabletype(BoxConst)
        end
    end
end
