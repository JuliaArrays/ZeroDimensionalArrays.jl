using ZeroDimensionalArrays
using Test
using Aqua: Aqua

@testset "ZeroDimensionalArrays.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(ZeroDimensionalArrays)
    end

    @testset "all array types joined" begin
        for Arr ∈ (
            ZeroDimArray,
            Box,
            BoxConst,
        )
            @test (@inferred Arr(0.3)) == (@inferred convert(Arr, fill(0.3)))
            @test isstructtype(Arr)
            @test Arr <: AbstractArray{<:Any, 0}
            @test (@inferred Arr(0.3)) isa Arr{Float64}
            @test (@inferred convert(Arr, fill(0.3))) isa Arr{Float64}
            @test (@inferred Arr{Float32}(0.3)) isa Arr{Float32}
            @test (@inferred convert(Arr{Float32}, fill(0.3))) isa Arr{Float32}
            @test () === @inferred propertynames(Arr(0.3))
            @test only(fill(0.3)) === @inferred only(Arr(0.3))
            @test fill(0.3)[] === @inferred Arr(0.3)[]
            @test fill(0.3)[1] === @inferred Arr(0.3)[1]
            @test @inferred isassigned(Arr(0.3))
            @test @inferred isassigned(Arr(0.3), 1)
            @test !(isassigned(Arr(0.3), 2))
            @test (@inferred iterate(Arr(0.3))) isa Tuple{Float64, Any}
            @test 0.3 === first(iterate(Arr(0.3)))
            @test let a = Arr(0.3)
                nothing === @inferred iterate(a, last(iterate(a)))
            end
            @test nothing === @inferred iterate(Arr(0.3), nothing)
            @test (@inferred similar(Arr(0.3))) isa Box{Float64}
            @test (@inferred similar(Arr(0.3), Float32)) isa Box{Float32}
            @test (@inferred copy(Arr(0.3))) isa Arr{Float64}
            @test (@inferred copy(Arr{AbstractFloat}(0.3))) isa Arr{AbstractFloat}
            @test let a = Arr(0.3)
                a == copy(a)
            end
            @test fill(0.3) == Arr(0.3)
            @test Arr(0.3) == Arr(0.3)
            @test all(@inferred Arr(0.3) .== Arr(0.3))
            @test (@inferred Arr(0.3) .+ [10, 20]) isa AbstractVector
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
