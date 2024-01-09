# Helper functions that may be used from here or there

# In the model, y is down, as in device space of Cairo / Luxor.
easting_to_model_x(model::ModelSpace, easting) = easting_to_model_x(model.world_to_model_scale, model.originE, easting)
easting_to_model_x(model::ModelSpace, easting::Vector) = map(x -> easting_to_model_x(model, x), easting)
easting_to_model_x(world_to_model_scale, world_units_originE, wx) = (wx - world_units_originE) / world_to_model_scale

northing_to_model_y(model::ModelSpace, northing) = northing_to_model_y(model.world_to_model_scale, model.originN, northing)
northing_to_model_y(model::ModelSpace, northing::Vector) = map(y -> northing_to_model_y(model, y), northing)
northing_to_model_y(world_to_model_scale, world_units_originN, wy) = -(wy - world_units_originN) / world_to_model_scale

model_x_to_easting(model::ModelSpace, x) = model_x_to_easting(model.world_to_model_scale, model.originE, x)
model_x_to_easting(model::ModelSpace, vx::Vector) = map(x -> model_x_to_easting(model, x), vx)
model_x_to_easting(world_to_model_scale, world_units_originE, mx) = mx * world_to_model_scale + world_units_originE

model_y_to_northing(model::ModelSpace, y) = model_y_to_northing(model.world_to_model_scale, model.originN, y)
model_y_to_northing(model::ModelSpace, vy::Vector) = map(y -> model_y_to_northing(model, y), vy)
model_y_to_northing(world_to_model_scale, world_units_originN, my) = -my * world_to_model_scale + world_units_originN


"""
    minimum_model_to_paper_scale_for_non_overlapping_labels(m::ModelSpace; 
    min_scale = 0.1, max_scale = 0.9, iterations = 20, tol = 0.001,
    kwds...)
    ---> x::typeof(lower)
"""
function minimum_model_to_paper_scale_for_non_overlapping_labels(m::ModelSpace; 
    min_scale = 0.1, max_scale = 0.9, iterations = 20, tol = 0.001,
    kwds...)
    #
    # m.limiting... is mutable. Update LuxorLayout with the model's current values.
    LIMITING_WIDTH[] = m.limiting_width[]
    LIMITING_HEIGHT[] = m.limiting_height[]
    #
    if length(m.labels) == 0
        @info "No labels in model."
        return snap()
    end
    model_bb = inkextent_user_get()
    # This single-parameter function captures all parameters in this context, 
    # except the scale (which is to be the output from this context). 
    function boolean_step(model_to_paper_scale)
        # The following is hardly always correct, but we can't see that it does matter here. TODO: Study this.
        O_model_in_paper_space = midpoint(O - model_bb) * model_to_paper_scale
        labels_ps = labels_paper_space_from_model_and_keywords(m;
            model_to_paper_scale,  O_model_in_paper_space, kwds...)
        # Now optimize the offset positions of paper space labels:
        LuxorLabels.optimize_offset_direction_diagonal!(labels_ps, plot_label_bounding_box)
        # 
        prioritized_indexes, boundary_boxes = indexes_and_bbs_prioritized_at_given_offset(;labels = labels_ps)
        dropped_indexes = setdiff(1:length(labels_ps), prioritized_indexes)
        if length(dropped_indexes) < 4
            msg = join([string(i) * " " * string(l) for (i,l) in zip(dropped_indexes, m.labels[dropped_indexes])], "\n" )
        else
            msg = join([string(i) for i in dropped_indexes], ", " )
        end
        if length(dropped_indexes) > 0
            @info "At model_to_paper_scale = $(round(model_to_paper_scale; digits = 4)), we would drop $(length(dropped_indexes)) labels: $msg"
        else
            @info "All labels fit at model_to_paper_scale = $(round(model_to_paper_scale; digits = 4)). "
        end
        # Return true if no drop!
        length(prioritized_indexes) == length(labels_ps)
    end
    # Now find the step in `boolean_step` by iteration. Return the minimum such that:
    # scale |> boolean_step --> true
    find_boolean_step_using_interval_halving(boolean_step; lower = min_scale, upper = max_scale, iterations, tol)
end






"""
    find_boolean_step_using_interval_halving(step_func::Function, lower, upper, iterations; tol = 0.001)
    ---> x::typeof(lower)

Find the minimum x that returns 'true'. 

`step_func(x)`       returns true 
`step_func(x - tol)` returns false 

Use this when iterating paper size (model parameters limting_height and limiting_width) to fit all labels.
For a more general function, it might be better to return the unknown midpoint between `true` and `false` values.
 
# Example
```
julia> with_logger(ConsoleLogger(stderr, Debug)) do
    find_boolean_step_using_interval_halving(; lower = 1.0, upper = 8.0) do x
        x >= π
    end
end
┌ Debug: Recurse into upper half since mid = 2.75 |> #42 --> false
└ @ RouteMap c:\\Users\\f\\.julia\\dev\\RouteMap\\src\\utils.jl:82
┌ Debug: Recurse into lower half since mid = 3.625 |> #42 --> true
└ @ RouteMap c:\\Users\\f\\.julia\\dev\\RouteMap\\src\\utils.jl:78
┌ Debug: Recurse into lower half since mid = 3.1875 |> #42 --> true
└ @ RouteMap c:\\Users\\f\\.julia\\dev\\RouteMap\\src\\utils.jl:78
┌ Debug: Recurse into upper half since mid = 2.96875 |> #42 --> false
└ @ RouteMap c:\\Users\\f\\.julia\\dev\\RouteMap\\src\\utils.jl:82
┌ Debug: Recurse into upper half since mid = 3.078125 |> #42 --> false
└ @ RouteMap c:\\Users\\f\\.julia\\dev\\RouteMap\\src\\utils.jl:82
┌ Debug: Recurse into upper half since mid = 3.1328125 |> #42 --> false
└ @ RouteMap c:\\Users\\f\\.julia\\dev\\RouteMap\\src\\utils.jl:82
┌ Debug: Recurse into lower half since mid = 3.16015625 |> #42 --> true
└ @ RouteMap c:\\Users\\f\\.julia\\dev\\RouteMap\\src\\utils.jl:78
┌ Debug: Recurse into lower half since mid = 3.146484375 |> #42 --> true
└ @ RouteMap c:\\Users\\f\\.julia\\dev\\RouteMap\\src\\utils.jl:78
┌ Debug: Recurse into upper half since mid = 3.1396484375 |> #42 --> false
└ @ RouteMap c:\\Users\\f\\.julia\\dev\\RouteMap\\src\\utils.jl:82
┌ Debug: Recurse into lower half since mid = 3.14306640625 |> #42 --> true
└ @ RouteMap c:\\Users\\f\\.julia\\dev\\RouteMap\\src\\utils.jl:78
┌ Debug: Recurse into upper half since mid = 3.141357421875 |> #42 --> false
└ @ RouteMap c:\\Users\\f\\.julia\\dev\\RouteMap\\src\\utils.jl:82
┌ Debug: Recurse into lower half since mid = 3.1422119140625 |> #42 --> true
└ @ RouteMap c:\\Users\\f\\.julia\\dev\\RouteMap\\src\\utils.jl:78
┌ Debug: Found root of #42 with 8 unused iterations. tol = 0.001
└ @ RouteMap c:\\Users\\f\\.julia\\dev\\RouteMap\\src\\utils.jl:73
3.1422119140625
```
"""

function find_boolean_step_using_interval_halving(step_func::Function; lower, upper, iterations = 20, tol = 0.001)
    mid = (lower + upper) / 2
    @assert iterations > 1
    @assert step_func(upper) "The value upper = $upper is too low. step_func(upper) returns `false` TODO fix $step_func"
    # Call the recursive method.
    x = _find_boolean_step_using_interval_halving(step_func, lower, mid, iterations; tol)
    if isnan(x)
        @debug "Could not find boolean step in iterations = $iterations. `Consider parameters for find_boolean_step_using_interval_halving`"
    end
    x
end

"""
    _find_boolean_step_using_interval_halving(step_func::Function, lower, upper, iterations; tol = 0.001)
    ---> x::typeof(lower)

Recursive, no argument checks.
"""
function _find_boolean_step_using_interval_halving(step_func::Function, lower, upper, iterations; tol = 0.001)
    mid = (lower + upper) / 2
    if iterations == 0
        @debug "Could not converge"
        return NaN
    end
    if (upper - lower) < tol
        @debug "Found root of $step_func with $iterations unused iterations. tol = $tol"
        return upper
    end
    if step_func(mid)
        # Recurse into lower half
        @debug "Recurse into lower half since mid = $mid |> $step_func --> true"
        return _find_boolean_step_using_interval_halving(step_func, lower, mid, iterations - 1)
    else
        # Recurse into upper half
        @debug "Recurse into upper half since mid = $mid |> $step_func --> false"
        return _find_boolean_step_using_interval_halving(step_func, mid, upper, iterations - 1)
    end
end
