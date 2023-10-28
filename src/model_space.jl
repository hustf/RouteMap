function plot_legs_in_model_space(m::ModelSpace, legs::Vector{Leg}; 
        limiting_utm_bb::BoundingBox = BoundingBox(O - Inf, O + Inf))
    for leg in legs
        # Does all or part of leg fall within the limiting boundary box?
        if boundingboxesintersect(leg.bb_utm, limiting_utm_bb)
            plot_leg_in_model_space(m, leg)
        end
    end
end

"""
    plot_leg_in_model_space(m::ModelSpace, l::Leg)
"""
function plot_leg_in_model_space(m::ModelSpace, l::Leg)
    # World (utm) to model coordinates
    # BA may be empty, which is fine.
    abx = l.ABx .- m.originE
    aby = -l.ABy .+ m.originN
    bax = l.BAx .- m.originE
    bay = -l.BAy .+ m.originN
    pointA = Point(abx[1], aby[1])
    if isempty(m.labels)
        # This is the first leg we plot. 
        # Use the opportunity to set inkextent around this first leg.
        # ink extents will be expanded from this as we plot more.
        inkextent_set(BoundingBox(pointA, pointA))
    end
    # Collect paths
    leg_pts_nested = [Point.(abx, aby), Point.(bax, bay)]
    # Plot (both) paths in leg
    poly_with_discontinuities(leg_pts_nested; action=:stroke)
    # expand ink extents
    encompass.(leg_pts_nested)
    # A small circle at start of leg.
    @layer begin
        setcolor(m.marker_color)
        circle(pointA, m.FS / 2, :stroke)
    end
    # Map labels to the models' collection.
    # Depending on zoom etc, some of those labels may not be displayed always.
    # Labels are always drawn in paper space.
    push!(m.labels, LabelModelSpace(m, l.label_A))
    push!(m.labels, LabelModelSpace(m, l.label_B))
end


"""
    poly_with_discontinuities(v_nested::Vector{Vector{Point}};
        action = :none,
        close = false,
        reversepath = false)
    ---> Vector{Vector{Point}}

Calls `Luxor.poly` multiple times. No visual difference, but
this makes one discontinuous path instead of multiple paths.

This could be useful for targetting a discontinuous path in .svg with .css.
"""
function poly_with_discontinuities(v_nested::Vector{Vector{Point}};
        action = :none,
        close = false,
        reversepath = false)
    newpath()
    for v in v_nested
        poly(v; action =:path, close, reversepath)
    end
    do_action(action)
    return v_nested
end

"""
    model_activate(;kw...)
    model_activate(c::ModelSpace)

An activated model referrs a global Drawing object maintained by Luxor, until 
it is finished, i.e. rendered to a file. There can be only one per thread 
of execution. When we take a 'snap', we create such a file, which we now think
of as paper space. We temporarily use another thread to load that file and 
layer text (primarily) on top of it. Thus, we can keep working on the
model

# Example
```
julia> model_activate()
```

# Keywords

See ModelSpace for details.

    countimage_startvalue
    colorscheme
    world_to_model_scale
    originE
    originN
    background
    linewidth
    foreground
    FS
    EM 
    limiting_height
    limiting_width
    margin
    crashpadding
    marker_color
    labels
"""
function model_activate(m::ModelSpace)
    LuxorLayout.LIMITING_WIDTH[] = m.limiting_width
    LuxorLayout.LIMITING_HEIGHT[] = m.limiting_height
    Drawing(NaN, NaN, :rec)
    countimage_setvalue(m.countimage_startvalue)
    inkextent_reset()
    background(m.background)
    setcolor(m.foreground)
    fontsize(m.FS)
    ma = m.margin
    margin_set(Margin(ma.t, ma.b, ma.l, ma.r))
    m
end
function model_activate(;kw...)
    model_config = ModelSpace(; kw...)
    model_activate(model_config)
end

function LabelModelSpace(m::ModelSpace, l::LabelUTM)
    LabelModelSpace(l.text, l.prominence, l.x - m.originE, l.y - m.originN)
end