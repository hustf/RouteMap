include("t_world_space.jl")
@test length(legs) == 1
m = model_activate(;countimage_startvalue = 9)
plot_leg_in_model_space(m, legs[1])
# First, we'll drop any labels and such.
RouteMap.snap()
# But here we go:
snap_with_labels(m)


# Test identical labels won't be duplicated in the model.
legs = Leg[]
add_or_update_if_not_redundant!(legs;    ABx = A1B1x, 
    ABy = A1B1y, 
    text_A = label_A1.text, 
    text_B = label_B1.text)
add_or_update_if_not_redundant!(legs;    ABx = A2B2x, 
    ABy = A2B2y, 
    text_A = label_A2.text, 
    text_B = label_B2.text)
m = model_activate(;countimage_startvalue = 10)
plot_legs_in_model_space(m, legs)
@test length(m.labels) == 3
snap_with_labels(m)