# This splits a large svg file into A4-sized partitions,
# without scaling but with rotation. This is handy for 
# preserving text size when printing piecewise
printstyled("Run me like this:\n julia> julia\\dev\\RouteMap> julia --project=. -t2 example/Split/ex_split.jl\n\n", color =:green)
include("split_functions.jl")
partition(; centre_rot_cw = 0 * π / 180, Δx = 320, keep = 
   [(1,1),
    (1,2),
    (1,3),
    (1,4),
    (2,1),
    (2,2),
    (2,3),
    (2,4),
    (3,1),
    (3,2),
    (3,3),
    (3,4)])
finish()
