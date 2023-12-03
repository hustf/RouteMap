# RouteMap.jl

## What does it do?

Aid in plotting maps of travel routes and condensing route tables.

Start by creating and activating a ModelSpace. 

ModelSpace will contain output paper size, font size, the full label collection and a mapping from
world coordinates to model coordinates.

'Activation' establishes a current Cairo recording session, an in-memory current drawing using 
model coordinates from which we can harvest snapshot images.

A route Leg is a path, often with separate paths for separate directions, and two end labels.

User will build and own a collection of Legs, in world (UTM) coordinates.
The function  `add_or_update_if_not_redundant!(legs, ...)` aids
in recognizing when information from different sources can be reduced. For example:

   1) One journey includes a leg, A -> B, and continues. The names and the path is passed to, 
   `add_or_update_if_not_redundant!`, which adds it as a Leg.
   2) Another journey also includes A -> B, but ends at B. The info is passed to, `add_or_update_if_not_redundant!`,
   which recognizes it as a redundant. No new Leg is added to the legs collection. However, 
   B is recognized as a possible journey destination, giving it a higher prominence. 

### Example use, building a Legs collection

A typical procedure collects data from RouteSlopeDistance.jl and StopsAndTimetables.jl
and feeds into a collection of Legs.

```
julia> using RouteMap

julia> legs = Leg[]  # An empty vector 
Leg[]

julia> add_or_update_if_not_redundant!(legs;
            ABx, ABy, text_A, text_B, prominence_A,
            prominence_B, threshold);

julia> legs[end]
Leg with  AB <=> BA:
 label_A = LabelUTM("Dragsund sør", 2.0, 24823.0, 6.93904e6)
 label_B = LabelUTM("Kjeldsundkrysset", 2.0, 23918.0, 6.93813e6)
 bb_utm = BoundingBox(Point(23918.0, 6.93813e6) : Point(24822.8, 6.93904e6))
 ABx =    [24822.8  …  23918.0] (81 elements)
 ABy =    [6.93904e6  …  6.93813e6] (81 elements)


```

### Example, plotting a default map

```
julia> model_activate()
RouteMap.ModelSpace(    countimage_startvalue  = 9, 
        colorscheme            = ColorSchemes.ColorScheme{Vector{ColorTypes.RGB{Float64}}, String, String}(ColorTypes.RGB{Float64}[RGB{Float64}(0.347677,0.199863,0.085069), RGB{Float64}(0.560535,0.419142,0.29185), RGB{Float64}(0.729634,0.613774,0.512), RGB{Float64}(0.822643,0.763401,0.698769), RGB{Float64}(0.836049,0.882901,0.85903), RGB{Float64}(0.762289,0.939134,0.951842), RGB{Float64}(0.639101,0.925688,0.971463), RGB{Float64}(0.504741,0.85335,0.938049), RGB{Float64}(0.342992,0.650614,0.772702)], "general", ""),
        world_to_model_scale   = 1.0, 
        originE                = 26561,
        originN                = 6940224,
        background             = RGB{Float64}(0.836049,0.882901,0.85903), 
        linewidth              = 9.0,
        foreground             = RGB{Float64}(0.347677,0.199863,0.085069),
        FS                     = 22,
        EM                     = 26,
        limiting_height        = 1344,
        limiting_width         = 1792,
        margin                 = (t = 54, b = 81, l = 72, r = 72), 
        crashpadding           = 2.14,
        marker_color           = RGB{Float64}(0.347677,0.199863,0.085069),
        labels                 = LabelModelSpace[], 
        utm_grid_size          = 1000,
        utm_grid_thickness     = 0.5)

julia> plot_legs_in_model_space(model, legs) # This plots the path geometry and updates model's `label` collection

julia> snap_with_labels(model)
```
This creates imgage files '10.png' and '10.svg'. The png is displayed depending on your setup, e.g. using VScode or a terminal.


# More on label selection and map sizing

Fitting many readable labels onto the available paper is challenging, and we plan to expand the options here. 

So far, overlapping labels are simply not shown by default. See `snap_with_labels` keywords.
(Version 0.0.4 contains the type LabelPaperSpace, which we plan to move to LuxorLabels. Not showing overlapping labels
currently don't fully work.)

Functions for optimizations by now include

`find_boolean_step_using_interval_halving`

This is used with user-defined functions like

```
function non_overlapping_labels_data_from_captured_model(model_to_paper_scale)
    # We take the labels from the model object here, but we could have taken it from 'legs'.
    txtlabels = map(l -> l.text, model.labels)
    prominence = map(l -> l.prominence, model.labels)
    anchors = map(l -> Point(l.x, l.y), model.labels)
    non_overlapping_labels_data(txtlabels, anchors / model_to_paper_scale, prominence)
end

function would_any_labels_be_discarded_from_overlap(model_to_paper_scale)
    txtlabels = map(l -> l.text, model.labels)
    it, _, _, _, _ = non_overlapping_labels_data_from_captured_model(model_to_paper_scale)
    length(it) !== length(txtlabels)
end
```
