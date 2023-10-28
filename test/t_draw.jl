include("t_world_space.jl")
@test length(legs) == 1
m = model_activate(;countimage_startvalue = 9)
plot_leg_in_model_space(m, legs[1])
# First, we'll drop any labels and such.
RouteMap.snap()
# But here we go:
snap_with_labels(m)
