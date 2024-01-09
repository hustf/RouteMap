using Test
function run_all_tests()
    @testset "1" begin
        include("t_world_space.jl")
    end
    @testset "2" begin
        include("t_draw.jl")
    end
    @testset "3" begin
        include("t_utils.jl")
    end
    @testset "4" begin
        include("t_fit_paper_to_labels.jl")
    end
end

# This is copied directly from Luxor.
if get(ENV, "ROUTEMAP_KEEP_TEST_RESULTS", false) == "true"
    cd(mktempdir(cleanup=false))
    @info("...Keeping the results in: $(pwd())")
    run_all_tests()
    @info("Test images were saved in: $(pwd())")
else
mktempdir() do tmpdir
    cd(tmpdir) do
        msg = """Running tests in: $(pwd())
        but not keeping the results
        because you didn't do: ENV[\"ROUTEMAP_KEEP_TEST_RESULTS\"] = \"true\""""
        @info msg
        run_all_tests()
        @info("Test images weren't saved. To see the test images, next time do this before running:")
        @info(" ENV[\"ROUTEMAP_KEEP_TEST_RESULTS\"] = \"true\"")
    end
end
end