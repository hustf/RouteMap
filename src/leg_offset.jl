# This contains functions for making offset Legs.
# The intention is drawing parallel route legs, as in e.g.
# when line 338 and 330 both travel on the same road.
# The offset refers to paper space units.:

"""
    leg_offset(m::ModelSpace, l::Leg, n; allow_self_intersection = false)
    leg_offset(l::Leg, offset::Float64; allow_self_intersection = false)
    ---> Leg

# Example
```
julia> m = model_activate()
RouteMap.ModelSpace(
    ⋮
        linewidth              = 9.0,
    )

julia> l = Leg(;ABx = .0:5:10, ABy = repeat([0.0] , 3))
    Leg with  AB <=> BA:
     label_A = LabelUTM("", 1.0, 0.0, 0.0)
     label_B = LabelUTM("", 1.0, 10.0, 0.0)
     bb_utm = Luxor.BoundingBox(Point(0.0, 0.0) : Point(10.0, 0.0))
     ABx =    [0.0  …  10.0] (3 elements)
     ABy =    [0.0  …  0.0] (3 elements)

julia> lego = leg_offset(m, l, 1)
     Leg with  AB <=> BA:
      label_A = LabelUTM("", 1.0, 0.0, 0.0)
      label_B = LabelUTM("", 1.0, 10.0, 0.0)
      bb_utm = Luxor.BoundingBox(Point(0.0, 0.0) : Point(10.0, 0.0))
      ABx =    [0.0  …  10.0] (3 elements)
      ABy =    [9.0  …  9.0] (3 elements)
```
"""
leg_offset(m::ModelSpace, l::Leg, n; allow_self_intersection = false) =  leg_offset(l, n * m.linewidth; allow_self_intersection)
leg_offset(l::Leg, offset::Float64; allow_self_intersection = false) = 
    _leg_offset(l.label_A, l.label_B, l.bb_utm, l.ABx, l.ABy, l.BAx, l.BAy, offset; allow_self_intersection)

function _leg_offset(label_A::LabelUTM, label_B::LabelUTM, bb_utm::BoundingBox,
    ABx::T, ABy::T, BAx::T, BAy::T, offset::Float64; allow_self_intersection = false) where T<:Vector{Float64}
    #
    ABxo, AByo = path_offset_along_normal(ABx, ABy, offset; allow_self_intersection)
    BAxo, BAyo = path_offset_along_normal(BAx, BAy, offset; allow_self_intersection)
    Leg(label_A, label_B, bb_utm,    ABxo, AByo, BAxo, BAyo)
end

function path_offset_along_normal(px, py, offset; allow_self_intersection = false)
    @assert length(px) == length(py)
    if isempty(px)
        return px, py
    end
    s = progression_at_each_coordinate(px, py)
    @assert length(px) == length(s)
    # The detailed progression, s, for this part is used as breakpoints:
    b  = BSplineBasis(4, s)
    # We'll make two curves (and their derivatives). Each is padded at the end with tangents
    xe = vcat(2 * px[1] - px[2], px, 2 * px[end] - px[end - 1])
    ye = vcat(2 * py[1] - py[2], py, 2 * py[end] - py[end - 1])
    # The smooth curves... Wrapping in Function ensures that NaN will be
    # returned for any parameter outside of b's 'support' or 'range', s.
    sx´ = Function(Spline(b, xe), Derivative(1))
    sy´ = Function(Spline(b, ye), Derivative(1))
    nx(s) = -sy´(s) * offset / hypot(sx´(s), sy´(s))
    ny(s) = sx´(s) * offset / hypot(sx´(s), sy´(s))
    ox = map(enumerate(s)) do (i, σ)
        px[i] + nx(σ)
    end
    oy = map(enumerate(s)) do (i, σ)
        py[i] + ny(σ)
    end
    if ! allow_self_intersection
        loopstart, loopend = indices_surrounding_si_loop(ox, oy)
        while ! isnothing(loopstart)
            splice!(ox, loopstart : loopend )
            splice!(oy, loopstart : loopend )
            loopstart, loopend = indices_surrounding_si_loop(ox, oy)
        end
    end
    return ox, oy
end

"""
    progression_at_each_coordinate(p_x, p_y)

Accumulated 2d point-to-point distance, for graphical purposes.
This function is adapted from RouteSlopeDistance.jl, rather than adding the dependency.

# Example
```
```
"""
function progression_at_each_coordinate(p_x, p_y)
    n = length(p_x)
    @assert length(p_y) == n
    p0 = [(p_x[i], p_y[i]) for i in 1:(n - 1)]
    p1 = [(p_x[i], p_y[i]) for i in 2:n]
    Δls = distance_between.(p0, p1)
    append!([0.0], cumsum(Δls))
end

distance_between(pt1, pt2) = hypot(pt2[1] - pt1[1], pt2[2] - pt1[2])



"""
    do_lines_intersect(p1x, p1y, q1x, q1y, p2x, p2y, q2x, q2y)
    ---> Bool

Do finite 2d lines (p1, q1) and (p2, q2) intersect?
"""
function do_lines_intersect(p1x, p1y, q1x, q1y, p2x, p2y, q2x, q2y)
    # Direction vectors for the lines
    d1x = q1x - p1x
    d1y = q1y - p1y
    d2x = q2x - p2x
    d2y = q2y - p2y
    # Cross product 
    crpr = d1x * d2y - d1y * d2x
    # A well known test for parallel lines is this. It also means the finite 
    # lines can't intersect.
    if crpr ≈ 0
        return false
    end
    # Paremtric equations for both lines
    # p1x + t1 * d1x == x     where 0 <= t1 <= 1
    # p1y + t1 * d1y == y     where 0 <= t1 <= 1
    # p2x + t2 * d2x == x     where 0 <= t2 <= 1
    # p2y + t2 * d2y == y     where 0 <= t2 <= 1
    #
    # Eliminating x and y since they are equal at a crossing point:
    # p1x + t1 * d1x == p2x + t2 * d2x
    # p1y + t1 * d1y == p2y + t2 * d2y
    #
    # Solving both equations for t1:
    # t1 == (p2x - p1x + t2 * d2x) / d1x 
    # t1 == (p2y - p1y + t2 * d2y) / d1y 
    #
    # Eliminating t1:
    # (p2x - p1x + t2 * d2x) / d1x == (p2y - p1y + t2 * d2y) / d1y 
    #
    # Solving for t2:
    # <=>
    # (p2x - p1x + t2 * d2x) * d1y == (p2y - p1y + t2 * d2y) * d1x
    # <=>
    # p2x * d1y - p1x * d1y + t2 * d2x * d1y  - p2y * d1x + p1y * d1x - t2 * d2y* d1x == 0
    # <=>
    # t2 *(d2x * d1y - d2y * d1x)  +  p2x * d1y - p1x * d1y   - p2y * d1x + p1y * d1x  == 0
    # <=>
    # t2  ==  (-p2x * d1y + p1x * d1y + p2y * d1x - p1y * d1x ) / (d2x * d1y - d2y * d1x)
    # 
    # Evaluate t2.
    t2  =  (-p2x * d1y + p1x * d1y + p2y * d1x - p1y * d1x ) / (d2x * d1y - d2y * d1x)
    if ! (0 <= t2 <= 1)
        return false
    end
    # Evaluate t1 from the first equation for it above:
    t1 = (p2x - p1x + t2 * d2x) / d1x 
    if ! (0 <= t1 <= 1)
        return false
    end
    return true
end

"""
    indices_surrounding_si_loop(vx, vy)
    ---> Tuple{Int or Nothing}

Return indices immediately before and after the polyline crosses itself.

# Example
```
julia> let
    #     1  2  3   4    5
    #     o  i  i   o    o     
    vx = [0, 1, -1, 0.5,  1] .* 10
    vy = [0.1, 1, 1,  0.0, -1] .* 10
    indices_surrounding_si_loop(vx, vy)
end
(1, 4)
```
"""
function indices_surrounding_si_loop(vx, vy)
    n = length(vx)  # Number of points
    for i in 1:(n-3)  # Iterate over lines, skipping the last one and avoiding immediate neighbor check
        for j in (i+2):(n-1)  # Compare with non-adjacent lines
            if do_lines_intersect(vx[i], vy[i], vx[i+1], vy[i+1], vx[j], vy[j], vx[j+1], vy[j+1])
                return i, j + 1
            end
        end
    end
    return nothing, nothing
end

"""
    is_polyline_self_intersecting(vx, vy)
    ---> Bool

Detect if a polyline defined by vx and vy is self-intersecting.
"""
function is_polyline_self_intersecting(vx, vy)
    i, j = indices_surrounding_si_loop(vx, vy)
    isnothing(i) ? false : true
end

