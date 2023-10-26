# In world space, we're using UTM coordinates, where one unit 
# cooresponds closely to one meter.

# Here, we jump through some hoops to avoid overlapping legs, from different journeys.
# The vector drawings we make may be very much smaller / lighter because of it.
"""
    Leg(;ABx = Float64[], 
        ABy = Float64[], 
        BAx = Float64[], 
        BAy = Float64[], 
        text_A::String = "", 
        text_B::String = "",
        prominence_A::Float64 = 1.0,
        prominence_B::Float64 = 1.0)
    ---> Leg

# Example
```
julia> Leg(;ABx = [1.0, 2],
                 ABy = [1.0, 2],
                 BAx = [2, 1.5, 1],
                 BAy = [2, 1.5, 1],
                 text_A = "Important",
                 text_B = "Intermediate stop",
                 prominence_A = 1.0,
                 prominence_B = 2.0)
Leg with  asymmetric AB:
 label_A = LabelUTM("Important", 1.0, 1.0, 1.0)
 label_B = LabelUTM("Intermediate stop", 2.0, 2.0, 2.0)
 bb_utm = Luxor.BoundingBox(Point(1.0, 1.0) : Point(2.0, 2.0))
 ABx =    [1.0  …  2.0] (2 elements)
 ABy =    [1.0  …  2.0] (2 elements)
 BAx =    [2.0  …  1.0] (3 elements)
 BAy =    [2.0  …  1.0] (3 elements)
```
"""
function Leg(;ABx = Float64[], 
        ABy = Float64[], 
        BAx = Float64[], 
        BAy = Float64[], 
        text_A::String = "", 
        text_B::String = "",
        prominence_A::Float64 = 1.0,
        prominence_B::Float64 = 1.0)
    @assert ! isempty(ABx) "Keyword arguments ABx and ABy must be defined."
    @assert length(ABx) == length(ABy)
    @assert length(BAx) == length(BAy)
    xa, ya = ABx[1], ABy[1]
    xb, yb = ABx[end], ABy[end]
    if ! isempty(BAx)
        # An alternative path, if provided, must 
        # start and end in proximity to A and B.
        # The difference, if any, is from stops where
        # exit and enty points differ. Less than 100 m...
        xb_alt, yb_alt = BAx[1], BAy[1]
        xa_alt, ya_alt = BAx[end], BAy[end]
        @assert abs(xa_alt - xa) < 100
        @assert abs(ya_alt - ya) < 100
        @assert abs(xb_alt - xb) < 100
        @assert abs(yb_alt - yb) < 100
    end
    lba = LabelUTM(text_A, prominence_A, xa, ya)
    lbb = LabelUTM(text_B, prominence_B, xb, yb)
    bb_utm = BoundingBox(Point.(vcat(ABx, BAx), vcat(ABy, BAy)))
    Leg(lba, lbb, bb_utm, ABx, ABy, BAx, BAy)
end


"""
    add_or_update_if_not_redundant!(legs::Vector{Leg}; 
        AB = Mls(), 
        BA = Mls(), 
        text_A::String = "", 
        text_B::String = "",
        prominence_A = 1.0,
        prominence_B = 1.0) 
    ---> Vector{Leg}

Adds a new Leg to the end of `legs`. The position of label A is tied to the first poin in 


# Rules

    1)    A to B and B to A may not exist in the same collection.

    2)    Legs may have two paths (multi_linestring), but only if they are not symmetric.
    
    3)    If a Leg with a low-priority label exists in a collection, and 
          a leg with equal boundingbox is attempted to be added, then: 
          Labels with low prominence are replaced by high prominence labels.
    
    4)    The boundingbox encompasses both paths. It is intended for selecting legs. 
"""
function add_or_update_if_not_redundant!(legs::Vector{Leg}; 
    ABx = Float64[], 
    ABy = Float64[], 
    BAx = Float64[], 
    BAy = Float64[], 
    text_A::String = "", 
    text_B::String = "",
    prominence_A::Float64 = 1.0,
    prominence_B::Float64 = 1.0)
    # Create the new leg before checking if it fits in the collection of legs
    leg = Leg(;    ABx, ABy, BAx, BAy, text_A, text_B, prominence_A, prominence_B)
    add_or_update_if_not_redundant!(legs, leg)
end
function add_or_update_if_not_redundant!(legs::Vector{Leg}, leg::Leg)
    maybe_equal_indices = indices_of_intersecting_boundary_boxes(legs, leg)
    if isempty(maybe_equal_indices)
        # Nothing with similar boundingbox to leg in legs; add leg!
        return push!(legs, leg)
    end
    indices_close_or_equal = maybe_equal_indices[findall(maybe_equal_indices) do i
        l = legs[i]
        are_paths_close(l, leg)
    end]
    @assert length(indices_close_or_equal) < 2 "Two sufficiently equal legs exist in `legs` already"
    if  length(indices_close_or_equal) == 1
        i = first(indices_close_or_equal)
        # leg practically equals legs[i]. So we don't need to add more legs, 
        # but we want to keep the "best" parts of both 'leg' and legs[i]
        mergedleg = merge_redundant_legs(legs[i], leg)
        legs[i] = mergedleg
        return legs
    else
        # None were equal. Think!
        throw("hmmm")
    end
end

function indices_of_intersecting_boundary_boxes(legs::Vector{Leg}, leg::Leg) 
    findall(legs) do leg_in_collection
        boundingboxesintersect(leg_in_collection.bb_utm, leg.bb_utm)
    end
end


function vectors_approx_equal(v, w)
    length(v) !== length(w) && return false
    for (ve, we) in zip(v, w)
        abs(ve - we) > 2 && return false
    end
    true
end

function merge_redundant_legs(leg1, leg2)
    if are_paths_most_likely_reversed(leg1, leg2)
        merge_redundant_legs_with_opposite_direction(leg1, leg2)
    else
        merge_redundant_legs_with_same_direction(leg1, leg2)
    end    
end

function merge_redundant_legs_with_same_direction(leg1, leg2)
    # We keep the most important label, of both A and B
    lba = label_in_close_proximity_to_keep(leg1.label_A, leg2.label_A)
    lbb = label_in_close_proximity_to_keep(leg1.label_B, leg2.label_B)
    if ! isempty(leg1.BAx)
        # leg1 has asymmetric directions, so keep A1B1 and B1A1
        bb_utm, ABx, ABy, BAx, BAy = leg1.bb_utm, leg1.ABx, leg1.ABy, leg1.BAx, leg1.BAy
    else
        # We don't care if leg2 has an empty reverse path or not.
        # Keep A2B2 and B2A2 (whether B2A2 is empty or not)
        bb_utm, ABx, ABy, BAx, BAy = leg2.bb_utm, leg2.ABx, leg2.ABy, leg2.BAx, leg2.BAy
    end
    Leg(lba, lbb, bb_utm, ABx, ABy, BAx, BAy)
end

function merge_redundant_legs_with_opposite_direction(leg1, leg2)
    # Let us aribrarily say that after merge, A == A1 == B2.
    # We keep the most important label, of both A and B
    lba = label_in_close_proximity_to_keep(leg1.label_A, leg2.label_B)
    lbb = label_in_close_proximity_to_keep(leg1.label_B, leg2.label_A)
    if ! isempty(leg1.BAx)
        # leg1 has asymmetric directions, so keep A1B1 and B1A1, drop leg2 paths.
        bb_utm, ABx, ABy, BAx, BAy = leg1.bb_utm, leg1.ABx, leg1.ABy, leg1.BAx, leg1.BAy
    else
        # Keep A1B1 and A2B2 (which becomes BA). Combine boundary boxes
        ABx, ABy = leg1.ABx, leg1.ABy
        BAx, BAy = leg2.ABx, leg2.ABy
        bb_utm = BoundingBox(Point.(vcat(ABx, BAx), vcat(ABy, BAy)))
    end
    Leg(lba, lbb, bb_utm, ABx, ABy, BAx, BAy)
end


function label_in_close_proximity_to_keep(lab1::Label, lab2::Label)
    if lab1.prominence < lab2.prominence
        lab1
    elseif lab1.prominence > lab2.prominence
        lab2
    elseif lab1.text !== "" 
        # Keep label 1
        if lab1.text !== lab2.text
            @warn "Keeping \"$(lab1.text)\", discarding \"$(lab2.text)\""
        end
        lab1
    else 
        # Keep label 2
        lab2
    end
end



"""
    are_paths_close((leg1, leg2; threshold = 100.0)
    are_paths_close(vx, vy, wx, wy; threshold = 100.0)
    ---> Bool

The default threshold corresponds to a very large roundabout.

# Example
```
julia> begin
    vx = [100.0, 220.00000000000003, 300.0, 409.99999999999994, 500.0, 600.0]
    vy [110.00000000000001, 200.0, 300.0, 200.0, 120.0, 50.0]
    # opposite direction, pretty close path
    wx = [687.6530581703992, 551.083132210278, 365.17099327681194, 315.1178505491685, 126.79176009349516]
    wy = [122.23257209157279, 124.77648298469046, 377.4275715327908, 274.47059574248544, 166.39055278414529]
end;
julia> are_paths_close(vx, vy, wx, wy)
false

julia> julia> are_paths_close(vx, vy, wx, wy; threshold = 150)
true
```
"""
function are_paths_close(vx, vy, wx, wy; threshold = 100.0)
    # If the path v is roughly the reverse of w, we would needlessly iterate from the wrong end
    if are_paths_most_likely_reversed(vx, vy, wx, wy)
        w_iterator = Iterators.reverse(zip(wx, wy))
    else
        w_iterator = zip(wx, wy)
    end
    for (x1, y1) in zip(vx, vy)
        close_enough_found = false
        for (x2, y2) in w_iterator
            if distance(x1, y1, x2, y2) < threshold
                close_enough_found = true
                break
            end
        end
        if ! close_enough_found
            return false
        end
    end
    return true
end
are_paths_close(leg1, leg2; threshold = 100.0) = are_paths_close(leg1.ABx, leg1.ABy, leg2.ABx, leg2.ABy; threshold)

distance(x1, y1, x2, y2) = sqrt((x1 - x2)^2 + (y1 - y2)^2)
are_paths_most_likely_reversed(vx, vy, wx, wy) = distance(vx[1], vy[1], wx[1], wy[1]) > distance(vx[1], vy[1], wx[end], wy[end])
are_paths_most_likely_reversed(leg1, leg2) = are_paths_most_likely_reversed(leg1.ABx, leg1.ABy, leg2.ABx, leg2.ABy) 