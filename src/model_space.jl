"""
    plot_legs_in_model_space_and_push_labels_to_model!(m::ModelSpace, legs::Vector{Leg}; 
        limiting_utm_bb::BoundingBox = BoundingBox(O - Inf, O + Inf))
"""
function plot_legs_in_model_space_and_push_labels_to_model!(m::ModelSpace, legs::Vector{Leg}; 
        limiting_utm_bb::BoundingBox = BoundingBox(O - Inf, O + Inf))
    for leg in legs
        # Does all or part of leg fall within the limiting boundary box?
        if boundingboxesintersect(leg.bb_utm, limiting_utm_bb)
            plot_leg_in_model_space_and_push_labels_to_model!(m, leg)
        else
            @debug "Some Leg(s) were not plotted because it falls outside of the defined boundary." maxlog = 1
        end
    end
    # We want to avoid world_to_paper_factor(m) > 1,
    # because zooming in makes the circles and labels look silly.
    if world_to_paper_factor(m) > 1
        @warn "Currently, world_to_paper_factor(model) = $(round(world_to_paper_factor(m), digits = 4)) > 1. If intentional, plots may look bad."
    end
    m.labels
end

"""
    plot_leg_in_model_space_and_push_labels_to_model!(m::ModelSpace, l::Leg)

Plot the leg path, and update the collection of labels in 'model'.
If this is the first leg to be plotted, centers 'inkextent' around it.
Otherwise, extends 'inkextent' to encompass this leg, too.

The drawing was activated in `model_activate`. The active drawing
is a global that is not referred from 'model', but 'model' keeps 
metadata like the labels. Labels may be plotted separately on
a 'paper space' overlay.
"""
function plot_leg_in_model_space_and_push_labels_to_model!(m::ModelSpace, l::Leg)
    # World (utm) to model coordinates
    # BA may be empty, which is fine.
    abx = easting_to_model_x(m, l.ABx)
    aby = northing_to_model_y(m, l.ABy)
    bax = easting_to_model_x(m, l.BAx)
    bay = northing_to_model_y(m, l.BAy)
    if isempty(m.labels)
        # This is (very likely) the first leg we plot. 
        # Use the opportunity to set inkextent around this first leg.
        # ink extents will be expanded from this as we plot more.
        bbm = utm_to_model(m, l.bb_utm)
        inkextent_set(bbm)
    end
    # Collect coordinates in paths
    leg_pts_nested = [Point.(abx, aby), Point.(bax, bay)]
    # Plot (both) paths in leg
    @layer begin
        setline(m.linewidth)
        setlinecap(:round)
        setlinejoin("round")
        poly_with_discontinuities(leg_pts_nested; action=:stroke)
    end
    # expand ink extents
    encompass.(leg_pts_nested)
    # Store the labels in model. They are not currently transformed to model space,
    # because we want to keep the UTM coordinates for filtering and feedback.
    update_labels_and_plot_small_circle!(m, l.label_A)
    update_labels_and_plot_small_circle!(m, l.label_B)
    nothing
end


""""
    update_labels_and_plot_small_circle!(m::ModelSpace, lab::LabelUTM; closest_identical_labels_distance_ws = 200)
    ---> ::ModelSpace

This adds a label to the collection in legs, while avoiding duplicate labels and close-duplicates.
If merged with another label, the highest prominence (high = low value!) is kept.

closest_identical_labels_distance_ws is the minimum world space distance between two labels.
"""
function update_labels_and_plot_small_circle!(m::ModelSpace, lab::LabelUTM; 
    closest_identical_labels_distance_ws = 200, closest_label_distance_ws = 10.0)
    @assert eltype(m.labels) == typeof(lab)
    xx = lab.x
    yy = lab.y
    txt = lab.text
    if isempty(m.labels) 
        return add_label_to_collection_and_plot_small_circle!(m, lab)
    end
    # Although LuxorLabels helps us avoid plotting overlapping labels,
    # we still do not want to unnecessarily add labels which are already present.
    # Therefore, we'll drop adding the label 'lab' to the model's collection of 
    # lables if it's within 200 m from a collected label with the same text.
    i_matching_x = findall(m.labels) do l 
        abs(l.x - xx) <= closest_identical_labels_distance_ws  && l.text == txt
    end
    if isempty(i_matching_x) 
        return add_label_to_collection_and_plot_small_circle!(m, lab; closest_label_distance_ws)
    end
    i_matching_xy_in_matching_x = findall(m.labels[i_matching_x]) do l
        abs(l.y - yy) <= closest_identical_labels_distance_ws
    end

    if isempty(i_matching_xy_in_matching_x)
        return add_label_to_collection_and_plot_small_circle!(m, lab; closest_label_distance_ws)
    end
    @assert length(i_matching_xy_in_matching_x) == 1 "Several similar labels have been added to the collection by mistake"
    # We found one (more would indicate something went wrong earier) labels 
    # with the same text and position within a square with side lengts = closest_identical_labels_distance_ws .
    # We will merge those labels, keeping the most important prominence.
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


function add_label_to_collection_and_plot_small_circle!(m, lab; closest_label_distance_ws = 10.0)
    # We know from the callee that no labels with identical text interfere.
    # Let us however also check if ANY labels are too close for comfort.
    i_xy = findall(m.labels) do l 
        abs(l.x - lab.x) <= closest_label_distance_ws && abs(l.y - lab.y) <= closest_label_distance_ws
    end
    if ! isempty(i_xy)
        labcoll = m.labels[first(i_xy)]
        @warn("The position ($(round(labcoll.x)), $(round(labcoll.y))) is already occupied by a label '$(labcoll.text)'. 
            Since the text '$(lab.text)' for the new label is different, we can't merge.
            And we can't add another label at position ($(round(lab.x)), $(round(lab.y))),
            because the distance to the existing label is, in world space meters: 
            $(hypot(labcoll.x - lab.x, labcoll.y -lab.y)))
            Clean your data closer to the source! I.e. in  RouteSlopeDistance.jl or StopsAndTimetables.jl!")
        throw(ArgumentError("We don't like $lab . See the warning above."))
    end
    modx = easting_to_model_x(m, lab.x) 
    mody = northing_to_model_y(m, lab.y)
    draw_and_encompass_circle(m, Point(modx, mody))
    push!(m.labels, lab)
    return m
end

"""
    draw_and_encompass_circle(m::ModelSpace, pt)
    draw_and_encompass_circle(pt::Point; r = 11.0, linewidth = 1.0)

Draws on the model space canvas, which is a global activated through `model_activate`.
"""
draw_and_encompass_circle(m::ModelSpace, pt) = draw_and_encompass_circle(pt; 
    r = m.linewidth * 1.5, 
    linewidth = m.linewidth)
function draw_and_encompass_circle(pt::Point; r = 11.0, linewidth = 1.0)
    @layer begin
        setline(linewidth)
        circle(pt, r, :fill)
    end
    encompass(pt + r)
    encompass(pt - r)
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
    world_to_model_factor
    originE
    originN
    background
    linewidth
    foreground
    FS
    EM 
    limiting_height    In this context, paper width in pt (landscape mode).
    limiting_width     In this context, paper height in pt (landscape mode).
    margin
    labels
    utm_grid_size
    utm_grid_thickness
"""
function model_activate(m::ModelSpace)
    update_layout(m)
    # Set model space ink extents identical to
    # paper space extents minus margins. 
    # This is better thought of as setting 'model_to_paper_factor = 1'.
    inkextent_reset() 
    # Make a new Luxor drawing (canvas corresponding to 'model space')
    Drawing(NaN, NaN, :rec)
    background(m.background)
    setcolor(m.foreground)
    fontsize(m.FS)
    countimage_set(m.countimage_startvalue)
    m
end
model_activate(;kw...) = model_activate(ModelSpace(; kw...))


function LabelModelSpace(m::ModelSpace, l::LabelUTM)
    LabelModelSpace(l.text, l.prominence, easting_to_model_x(m, l.x), northing_to_model_y(m, l.y))
end