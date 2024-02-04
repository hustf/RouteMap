# Utilties for fine-tuning map paper size and exact label fitting



"""
    adapt_model_paper_size_and_snap!(m::RouteMap.ModelSpace, model_to_paper_factor; kwds...)
    --> png image for display. Outputs and svg and a png file. Using `LuxorLayout.snap`

Also modifies `m` in-place. See `LabelPaperSpace` regarding keywords, like modifiying `offset` values.
"""
function adapt_model_paper_size_and_snap!(m::RouteMap.ModelSpace, model_to_paper_factor; kwds...)
    model_bb = inkextent_user_get()
    m.limiting_width[] = round(boxwidth(model_bb * model_to_paper_factor) + m.margin.r + m.margin.l)
    m.limiting_height[] = round(boxheight(model_bb * model_to_paper_factor) + m.margin.t + m.margin.b)
    println("A4 pages wide: ", ceil(m.limiting_width[] / 595), " at model_to_paper_factor = ", round(model_to_paper_factor, digits = 5), "\n   pages tall: ", ceil(m.limiting_width[] / 895))
    snap_with_labels(m; kwds...)
end



"""
    minimum_model_to_paper_factor_for_non_overlapping_labels(m::ModelSpace; 
    min_factor = 0.1, max_factor = 0.9, iterations = 20, tol = 0.001,
    kwds...)
    ---> x::typeof(lower)


# Example

Here, model `m` is predefined and populated with labels.
'halign' and 'offset' are vectors with length corresponding to `m.labels`.
 We can use the same keyword arguments as in `labels_paper_space_from_model_and_keywords`.

```
julia> # Try to shrink paper area needed for the big plot

julia> m2ps = minimum_model_to_paper_factor_for_non_overlapping_labels(m; halign, offset, min_factor = 0.07, max_factor = 0.15)
0.08546875000000001

julia> # Resize the output from model accordingly.

julia> m.limiting_width[] = round(boxwidth(model_bb * m2ps) + m.margin.r + m.margin.l)
9532.0

julia> m.limiting_height[] = round(boxheight(model_bb * m2ps) + m.margin.t + m.margin.b)
6245.0

julia> println("Output is A4 pages wide: ", ceil(m.limiting_width[] / 595), " at model_to_paper_factor = ", round(m2ps, digits = 5), "\n  and A4 pages high:", ceil(m.limiting_width[] / 895))
Output is A4 pages wide: 17.0 at model_to_paper_factor = 0.08547
  and A4 pages high:11.0

julia> snap_with_labels(m)  # This is displayed depending on context.
Cairo.CairoSurfaceBase{UInt32}(Ptr{Nothing} @0x0000022584cace20, 9415.0, 6245.0)
```
"""
function minimum_model_to_paper_factor_for_non_overlapping_labels(m::ModelSpace; 
    min_factor = 0.1, max_factor = 0.9, iterations = 20, tol = 0.001,
    kwds...)
    #
    update_layout(m)
    #
    if length(m.labels) == 0
        @info "No labels in model."
        return snap()
    end
    model_bb = inkextent_user_get()
    # This single-parameter function captures all parameters in this context, 
    # except the factor (which is to be the output from this context). 
    function boolean_step(model_to_paper_factor)
        # The following is hardly always correct, but we can't see that it does matter here. TODO: Study this.
        O_model_in_paper_space = midpoint(O - model_bb) * model_to_paper_factor
        labels_ps = labels_paper_space_from_model_and_keywords(m;
            model_to_paper_factor,  O_model_in_paper_space, kwds...)
        # Now optimize the offset positions of paper space labels:
        LuxorLabels.optimize_offset_direction_diagonal!(labels_ps, plot_label_return_bb)
        # 
        prioritized_indexes, boundary_boxes = indexes_and_bbs_prioritized_at_given_offset(;labels = labels_ps)
        dropped_indexes = setdiff(1:length(labels_ps), prioritized_indexes)
        if length(dropped_indexes) < 4
            msg = join([string(i) * " " * string(l) for (i,l) in zip(dropped_indexes, m.labels[dropped_indexes])], "\n" )
        else
            msg = join([string(i) for i in dropped_indexes], ", " )
        end
        if length(dropped_indexes) > 0
            @info "At model_to_paper_factor = $(round(model_to_paper_factor; digits = 6)), we would drop $(length(dropped_indexes)) labels:\n$msg"
        else
            @info "All labels fit at model_to_paper_factor = $(round(model_to_paper_factor; digits = 6)). " 
        end
        # Return true if no drop!
        length(prioritized_indexes) == length(labels_ps)
    end
    # Now find the step in `boolean_step` by iteration. Return the minimum such that:
    # factor |> boolean_step --> true
    find_boolean_step_using_interval_halving(boolean_step; lower = min_factor, upper = max_factor, iterations, tol)
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
        return x
    end
    # Make sure we're not returning an x for which step_func was never evaluated.
    # That would happen if all evaluations for x < upper returned false.
    if x < upper
        if step_func(x)
            return x
        else
            return upper
        end
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
        @debug "Found root $round(upper, 5) of $step_func with $iterations unused iterations. tol = $tol"
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


"""
    sort_by_vector!(legs::Vector{Leg}, positive_easting, positive_northing)
    sort_by_vector!(labels::Vector{T}, positive_easting, positive_northing) where T<:RouteMap.Label
    ---> Vector of Leg or Label

In-place sorting along the direction defined by [positive_easting, positive_northing].
"""
function sort_by_vector!(legs::Vector{Leg}, positive_easting, positive_northing)
    function position_projected_on_vector(leg)
        bb = leg.bb_utm
        east, nort = midpoint(bb)
        east * positive_easting + nort * positive_northing
    end
    sort!(legs, by = position_projected_on_vector)
end
function sort_by_vector!(labels::AbstractVector{T}, positive_easting, positive_northing) where T<:RouteMap.Label
    function position_projected_on_vector(label)
        east, nort = label.x, label.y
        east * positive_easting + nort * positive_northing
    end
    sort!(labels, by = position_projected_on_vector)
end