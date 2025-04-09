using ZeroDimensionalArrays
using Test
using Aqua

@testset "ZeroDimensionalArrays.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(ZeroDimensionalArrays)
    end
    # Write your tests here.
end
