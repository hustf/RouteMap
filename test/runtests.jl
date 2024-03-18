using Test
function run_all_tests()
    @testset "1" begin
        include("t_world_space.jl")
    end
    @testset "2 Pic. 10-12" begin
        include("t_draw.jl")
    end
    @testset "3" begin
        include("t_transformations.jl")
    end
    @testset "4 Pic. 14-22" begin
        include("t_fit_to_given_paper.jl")
    end
    @testset "5" begin
        include("t_adapt_paper_to_label_stacking.jl")
    end
    @testset "6" begin
        include("t_draw_offset.jl")
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