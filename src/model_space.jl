function plot_legs_in_model_space(m::ModelSpace, legs::Vector{Leg}; 
        limiting_utm_bb::BoundingBox = BoundingBox(O - Inf, O + Inf))
    for leg in legs
        # Does all or part of leg fall within the limiting boundary box?
        if boundingboxesintersect(leg.bb_utm, limiting_utm_bb)
            plot_leg_in_model_space(m, leg)
        else
            @debug "Some Leg(s) were not plotted because it falls outside of the defined boundary." maxlog = 1
        end
    end
end

"""
    plot_leg_in_model_space(m::ModelSpace, l::Leg)

Plot the leg line, and update the collection of labels in 'model'.
If this is the first leg to be plotted, centers 'inkextent' around it.
Otherwise, extends 'inkextent' to encompass this leg, too.

The drawing was activated in `model_activate`. The active drawing
is a global that is not referred from 'model', but 'model' keeps 
metadata like the labels. Labels may be plotted separately on
a 'paper space' overlay.
"""
function plot_leg_in_model_space(m::ModelSpace, l::Leg)
    # World (utm) to model coordinates
    # BA may be empty, which is fine.
    abx = easting_to_model_x(m, l.ABx)
    aby = northing_to_model_y(m, l.ABy)
    bax = easting_to_model_x(m, l.BAx)
    bay = northing_to_model_y(m, l.BAy)
    if isempty(m.labels)
        # This is the first leg we plot. 
        # Use the opportunity to set inkextent around this first leg.
        # ink extents will be expanded from this as we plot more.
        pointA = Point(abx[1], aby[1])
        inkextent_set(BoundingBox(pointA, pointA))
    end
    # Collect coordinates in paths
    leg_pts_nested = [Point.(abx, aby), Point.(bax, bay)]
    # Plot (both) paths in leg
    poly_with_discontinuities(leg_pts_nested; action=:stroke)
    # expand ink extents
    encompass.(leg_pts_nested)
    # Map labels to the models' collection, avoiding duplicate labels.
    # Depending on zoom etc, some of those labels may not be displayed always.
    # Labels are always drawn in paper space.
    lbma = LabelModelSpace(m, l.label_A)
    lbmb = LabelModelSpace(m, l.label_B)
    update_labels_and_plot_small_circle!(m, lbma)
    update_labels_and_plot_small_circle!(m, lbmb)
    nothing
end

function update_labels_and_plot_small_circle!(m::ModelSpace, lab::LabelModelSpace; closest_identical_labels_distance_ws = 200)
    @assert eltype(m.labels) == typeof(lab)
    xx = lab.x
    yy = lab.y
    txt = lab.text
    isempty(m.labels) && return add_label_to_collection_and_plot_small_circle!(m, lab)
    # Although LuxorLabels helps us avoid plotting overlapping labels,
    # we still do not want to unnecessarily add labels which are already present.
    # Therefore, we'll drop adding the label 'lab' to the model's collection of 
    # lables if it's within 200 m from a collected label with the same text.
    closest_identical_labels_distance = closest_identical_labels_distance_ws / m.world_to_model_scale
    i_matching_x = findall(m.labels) do l 
        abs(l.x - xx) <= closest_identical_labels_distance && l.text == txt
    end
    isempty(i_matching_x) && return add_label_to_collection_and_plot_small_circle!(m, lab)
    i_matching_xy_in_matching_x = findall(m.labels[i_matching_x]) do l
        abs(l.y - yy) <= closest_identical_labels_distance
    end
    isempty(i_matching_xy_in_matching_x) && return add_label_to_collection_and_plot_small_circle!(m, lab)
    # We found one (don't expect more) labels with roughly matching position and the same text.
    @assert length(i_matching_xy_in_matching_x) == 1
    i_existing = Int64(first(i_matching_x[first(i_matching_xy_in_matching_x)]))
    existing = m.labels[i_existing]
    if existing.prominence > lab.prominence
        # A label with same text is being added to the roughly same location, 
        # but this time with more important (numeric value lower) prominence.
        # Replace the existing label.
        m.labels[i_existing] = lab
        return m
    end
    # The label matches completely with an existing one. Nothing to do.
    return m
end

function add_label_to_collection_and_plot_small_circle!(m, lab; closest_labels_distance = 1.0 / m.world_to_model_scale)
    i_xy = findall(m.labels) do l 
        abs(l.x - lab.x) <= closest_labels_distance && abs(l.y - lab.y) <= closest_labels_distance
    end
    if ! isempty(i_xy)
        @show closest_labels_distance
        labcoll = m.labels[first(i_xy)]
        throw("The position ($(round(labcoll.x)), $(round(labcoll.y))) is already occupied by a label '$(labcoll.text)'. 
            Can't add '$(lab.text)' at position ($(round(lab.x)), $(round(lab.y)))!")
    end
    draw_small_circle(m, Point(lab.x, lab.y))
    push!(m.labels, lab)
    return m
end

"""
    draw_small_circle(m::ModelSpace, pt)
    draw_small_circle(pt::Point; r = m.FS / 2, marker_color = m.marker_color)

Draws on the model space canvas, which is a global activated through `model_activate`.
"""
draw_small_circle(m::ModelSpace, pt) = draw_small_circle(pt; r = m.FS / 2, marker_color = m.marker_color)
function draw_small_circle(pt::Point; r = 11.0, marker_color = ColorSchemes.browncyan[1])
    @layer begin
        setcolor(marker_color)
        circle(pt, r, :stroke)
    end
    encompass(pt + r)
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
        if ! isempty(v)
            poly(v; action =:path, close, reversepath)
        end
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
    LabelModelSpace(l.text, l.prominence, easting_to_model_x(m, l.x), northing_to_model_y(m, l.y))
end