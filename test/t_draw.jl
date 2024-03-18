# Uses some definitions from 't_world_space.jl'
# Tests of output with a single leg and simple config.
# Label offset optimization is not a relevant point in 
# this example.
@assert @isdefined(legs) "Run this after t_world_space.jl"
@test length(legs) == 1
m = model_activate(;countimage_startvalue = 9)
plot_legs_in_model_space_and_push_labels_to_model!(m, legs)
# First, we ignore any labels and such.
# 10.svg has only the road and two stops circles:
RouteMap.snap()
# But here we go, 11.svg has default labels
snap_with_labels(m)

# Test identical labels won't be duplicated in the model.
legs_fork = Leg[]
add_or_update_if_not_redundant!(legs_fork;    ABx = A1B1x, 
    ABy = A1B1y, 
    text_A = label_A1.text, 
    text_B = label_B1.text)
add_or_update_if_not_redundant!(legs_fork;    ABx = A2B2x, 
    ABy = A2B2y, 
    text_A = label_A2.text, 
    text_B = label_B2.text)
m = model_activate(;countimage_startvalue = 11)
plot_legs_in_model_space_and_push_labels_to_model!(m, legs_fork)
@test length(m.labels) == 3
# 12.svg has three labels and two legs:
snap_with_labels(m)

