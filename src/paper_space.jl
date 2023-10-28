function plot_prominent_labels_from_paper_space(; model_to_paper_scale, O_model_in_paper_space, model::ModelSpace)
    # This function is run in a separate thread, working on 'paper space',
    # and without affecting what's on the canvas (model space).
    text = map(l -> l.text, model.labels)
    prominence = map(l -> l.prominence, model.labels)
    pt_in_paper_space = map(model.labels) do l
        O_model_in_paper_space + (l.x * model_to_paper_scale, - l.y *  model_to_paper_scale)
    end
    # Since we're in paper space now, line thickness won't zoom away as much
    setline(0.5)
    # Our single label plotting function `text_offset_dropshadow` takes four positional arguments, while 
    # the function that prioritizes and then call plot expects three arguments.
    # We define a three-variable plotting function by capturing model:
    f(label, pos, pri) = text_offset_dropshadow(label, pos, pri, model;
        posline = true)
    selected_indexes, selected_padding_bounding_boxes = labels_prominent(f, text, pt_in_paper_space, prominence;
        crashpadding = model.crashpadding, anchor = "left")
    # Mark anchor points and boundingboxes used for prioritizing for adjustment
    #for (i, b) in zip(selected_indexes, selected_padding_bounding_boxes)
    #    circle(pt_in_paper_space[i], 1, :stroke)
    #    box(b, :stroke)
    #end
end


function snap_with_labels(m::ModelSpace) 
    model_to_paper_scale = scale_limiting_get()
    O_model_in_paper_space = (O - midpoint(inkextent_user_with_margin())) * scale_limiting_get()
    snap(plot_prominent_labels_from_paper_space; 
        model = m,
        model_to_paper_scale,
        O_model_in_paper_space)
end


"""
    text_offset_dropshadow(txt, pt, prominence, m::ModelSpace;
        offs = (-1.5 * m.EM, 2 * m.EM), 
        posline = false, specialcolor = false)
    
Toy API
"""
function text_offset_dropshadow(txt, pt, prominence, m::ModelSpace;
        offs = (-1.5 * m.EM, 2 * m.EM), 
        posline = false, specialcolor = false)
    lins = string.(split(txt, '\n'))
    shadowoffset = (1, 1) .* m.FS ./ 37.5
    α = atan(-offs[2], offs[1])
    if α < -10π / 18 && α < -π / 2
        lineoffs = offs .+ (width_of_toy_string(lins[1]) * 0.25, -height_of_toy_font())
    else
        lineoffs = offs
    end
    @layer begin
        fontsize(m.FS + 4 - 4 * prominence)
        setopacity(1)
        sethue(m.colorscheme[9])
        # Text shadow 
        for i in 1:length(lins)
            text(lins[i], pt + offs + shadowoffset - (0, -(i-1) * 1.25 * height_of_toy_font()) )
        end
        if posline
            setdash("shortdashed")
            line(pt + shadowoffset, pt + lineoffs + shadowoffset, :stroke)
        end
        sethue(m.colorscheme[specialcolor ? 2 : 1])
        for i in 1:length(lins)
            text(lins[i], pt + offs - (0, -(i-1) * 1.25 * height_of_toy_font()))
        end
        if posline
            line(pt, pt + lineoffs, :stroke)
        end
    end
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