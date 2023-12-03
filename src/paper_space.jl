function labels_paper_space(model::ModelSpace;  model_to_paper_scale = 1, O_model_in_paper_space = O, 
        leaderline = true, halign = :left, offsetbelow = true)
    offset = Point((-1.5, 2.0) .* model.EM)
    fontsize_prominence_1 = model.FS
    shadowcolor = model.colorscheme[9]
    textcolor = model.colorscheme[1]
    map(model.labels) do l
        px = model_x_to_paper_x(O_model_in_paper_space[1],  model_to_paper_scale, l.x)
        py = model_y_to_paper_y(O_model_in_paper_space[2],  model_to_paper_scale, l.y)
        LabelPaperSpace(text = l.text, prominence = l.prominence, x = px, y = py;
            offset, halign, offsetbelow, shadowcolor, textcolor, leaderline, fontsize_prominence_1)
    end
end

"""
    plot_prominent_labels_from_paper_space(model::ModelSpace; model_to_paper_scale, O_model_in_paper_space, 
        plot_guides = false, plot_overlapping = false, leaderline = true,
        halign = :left, offsetbelow = true)

This plots labels (assumedly on the paper space overlay, but simply uses the current cairo context).
"""
function plot_prominent_labels_from_paper_space(model::ModelSpace; model_to_paper_scale, O_model_in_paper_space, 
            plot_guides = false, plot_overlapping = false, leaderline = true,
            halign = :left, offsetbelow = true)
    pslabels = labels_paper_space(model; model_to_paper_scale, O_model_in_paper_space, 
        leaderline, halign, offsetbelow)
    throw("Only used for testing? Drop this")
    plot_prominent_labels_from_paper_space(pslabels; plot_guides, plot_overlapping)
end
function plot_prominent_labels_from_paper_space(pslabels; plot_guides = false, plot_overlapping = false)
    # Since we're in paper space now, line thickness won't zoom away as much
    # setline(0.5)
    bbs = BoundingBox[]
    if plot_overlapping
        for l in pslabels
            bb = plot_label_bounding_box(l; plot_guides)
            push!(bbs, bb)
        end 
    else
        for l in pslabels
            throw("plot_overlapping == false:  not currently implemented. TODO: implement in LuxorLabels")
            bb = plot_label_bounding_box(l; plot_guides = false, noplot = true)
            push!(bbs, bb)
        end 
    end
    # Our single label plotting function `text_offset_dropshadow` takes four positional arguments, while 
    # the function that prioritizes and then call plot expects three arguments.
    # We define a three-variable plotting function by capturing model:
    #=
    f(label) = text_offset_dropshadow(label; plot_guides, leaderline)
    if plot_overlapping
        plotted_indexes, plotted_padding_bounding_boxes = broadcast_all_labels_to_plotfunc(f, pslabels)
    else
        plotted_indexes, plotted_padding_bounding_boxes = broadcast_prominent_labels_to_plotfunc(f, pslabels)
    end
    if plot_guides
        # Mark anchor points and boundingboxes. Use when iterating for a size to display all labels. 
        for (i, b) in zip(plotted_indexes, plotted_padding_bounding_boxes)
            box(b, :stroke)
        end
    end
    =#
    bbs
end



"""
    snap_with_labels(m::ModelSpace; plot_guides = false, draw_grid = true, plot_overlapping = false)

# Example, iterating to find a good plot size for a map.
```
julia> model = model_activate(;countimage_startvalue = 9, limiting_height = 2 * 1344, limiting_width = 2 * 1792) 
julia> plot_legs_in_model_space(model, legs)
julia> using Logging
julia> with_logger(Logging.ConsoleLogger(stderr, Logging.Debug)) do                                                                                                                                                                                 
    snap_with_labels(model)                                                                                                                                                                                                                  
end
julia> snap_with_labels(model; plot_guides = true)
```
"""
function snap_with_labels(m::ModelSpace; plot_guides = false, draw_grid = true, plot_overlapping = false, leaderline = true, halign = :left, offsetbelow = true)
    draw_grid && draw_utm_grid(m)
    model_to_paper_scale = scale_limiting_get()
    O_model_in_paper_space = (O - midpoint(inkextent_user_with_margin())) * scale_limiting_get()
    pslabels = labels_paper_space(m; model_to_paper_scale, O_model_in_paper_space, 
          leaderline, halign, offsetbelow)
    function f()
        bbs = BoundingBox[]
        for l in pslabels
            bb = plot_label_bounding_box(l; plot_guides)
            push!(bbs, bb)
        end
        bbs
    end
    #snap(f; 
    #    model_to_paper_scale,
    #    O_model_in_paper_space, 
    #    plot_guides,
    #    plot_overlapping)
    snap(f)
end

 


"""
    plot_label_bounding_box(l::LabelPaperSpace; noplot = false, plot_guides = true, two_word_lines = true)
    ---> BoundingBox

See inline comments. The bounding box only includes letters, not the leader line.
"""
function plot_label_bounding_box(l::LabelPaperSpace; noplot = false, plot_guides = true, two_word_lines = true)
    # We prefer max two words per line in map labels
    ftext = two_word_lines ? l.text : wrap_to_two_words_per_line(l.text)
    # We'll use the 'toy' text, so need to split text into lines.
    lins = string.(split(ftext, '\n'))
    nlins = length(lins)
    # Font related vars
    shadowoffset = (1, 1) .* l.fontsize_prominence_1 ./ 37.5
    fs = l.fontsize_prominence_1*  ( 1 - 0.182 * (l.prominence - 1))
    em = fs * 13 / 11
    # Find the size of the text box, considering all lines.
    # We read this from Cairo, so need to change Cairo state temporarily.
    Luxor.gsave()
    fontsize(round(l.fontsize_prominence_1*  ( 1 - 0.182 * (l.prominence - 1))))
    xb, yb, w, _, _, _ = textextents(lins[1])
    for i in 2:nlins
        xbi, ybi, wi, _, _, _ = textextents(lins[i])
        if xbi < xb 
            xb = xbi
        end
        if ybi < yb 
            yb = ybi
        end
        if wi > w
            w = wi
        end
    end
    # Place leader offset in its specified quadrant.
    offs = l.offset[1] * (l.halign == :left ? 1 : -1 ), l.offset[2] * (l.offsetbelow ? 1 : -1)
    # Leader line end point
    α = atan(offs[2], offs[1])
    le = hypot(offs...)
    # If offset is below the 'label anchor point' (l.x, l.y), we shorten the leader
    # by δle so as not to cross the first line of text.
    δle = (l.offsetbelow ? abs(yb) * (1 / sin(α)) : 0)
    pointat = Point(l.x, l.y)
    leaderend = pointat + (le - δle) .* (cos(α), sin(α))
    # yte position of first line baseline
    δy = l.offsetbelow ? 0.0 : - (nlins - 1) * em
    yte = l.y + offs[2] + δy 
    # y top of boundary box
    ytl = yte + yb
    # The leader does not point towards
    # the text anchor. Rather, it points to the 'fixed' point. 
    # The text anchor is placed 1 / 3 of line length 
    # to the left of the 'fixed' point (for left aligned text).
    # xte position of first line text anchor point.
    δx = l.halign == :left ? -w / 3 : (-2w / 3)
    # If we right align, the anchor is on the opposite side.
    δxalign = l.halign == :left ? 0 : w
    xte = l.x + offs[1] + δx
    # x left of boundary box
    xtl = xte + xb
    # y bottom of boundary box
    ybr = ytl + nlins * em
    # x right of boundary box
    xbr = xtl + w
    # Boundary box
    bb = BoundingBox(Point(xtl, ytl), Point(xbr, ybr))
    # This label function is typically called once without plotting
    # to retrieve which parts it would cover.
    # If that's okay, it is called again with this keyword:
    if ! noplot
        # Text shadow 
        sethue(l.shadowcolor)
        for i in eachindex(lins)
            text(lins[i], Point(xte, yte) + (δxalign, (i - 1) * em) + shadowoffset; halign = l.halign)
        end
        # Leader line shadow
        if l.leaderline
            @layer begin
                setdash("shortdashed")
                line(pointat + shadowoffset,  leaderend + shadowoffset, :stroke)
                sethue(l.textcolor)
                line(pointat,  leaderend, :stroke)
            end
        end
        # Text
        sethue(l.textcolor)
        for i in eachindex(lins)
            text(lins[i], Point(xte, yte) + (δxalign, (i - 1) * em);  halign = l.halign)            
        end
        if plot_guides
            box(bb, :stroke)
            # 'fixed point', where the uncut leader points.
            circle(pointat + offs, fs / 5, :stroke)
            # offset radius, which help understand how offset modifiers work.
            # Modifiers are l.halign and l.offsetbelow.
            circle(l.x, l.y, hypot(l.offset...), :stroke)
            # text anchor
            circle(Point(xte, yte) + (δxalign, 0), fs / 5, :stroke)
        end 
    end
    # Revert Cairo state
    Luxor.grestore()
    return bb
end



"""
    height_of_toy_font()
    ---> Float64

This depends on the current 'Toy API' text size, and can be changed with
fontsize(fs). 

# Example
```
julia> height_of_toy_font()
9.0
```
"""
height_of_toy_font() = textextents("|")[4]

"""
    width_of_toy_string(s::String)
    ---> Float64

# Example
```
julia> width_of_toy_string("1234")
26.0
```
"""
width_of_toy_string(s::String) = textextents(s)[3]