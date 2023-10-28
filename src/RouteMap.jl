module RouteMap

export Leg, add_or_update_if_not_redundant!, LabelUTM, LabelModelSpace
export model_activate, plot_leg_in_model_space, snap_with_labels
using LuxorLayout, LuxorLabels, ColorSchemes
using ColorSchemes: Colorant
import Luxor
using Luxor: Drawing, background, setline, settext, BoundingBox
using Luxor: sethue, get_current_color, poly, Point, setcolor, fontsize
using Luxor: @layer, O, textextents, setopacity, text, setdash, line, circle
using Luxor: midpoint, box, boundingboxesintersect
using Luxor: newpath, do_action
import Base: show
import Base.Iterators


"An alias. A conversion of a 'multi_linestring' to numeric nested 3D"
const Mls = Vector{Vector{Tuple{Float64, Float64, Float64}}}


abstract type Label end
"""
Legs exist in the world space, UTM. We don't want
its labels to depend on each model space.
"""
struct LabelUTM <:Label
    text::String
    prominence::Float64
    x::Float64           # "World (UTM) space".
    y::Float64
end

"""
A label may not be have high enough prominence to be displayed.
The check for that is done by mapping model to paper space.
"""
struct LabelModelSpace <: Label
    text::String
    prominence::Float64
    x::Float64           # "Model space".
    y::Float64
end


# The input geometry format is 'multi_linestring', kept from data source.
# Those are nested in segments, which are closed intervals: Ends within a leg
# repeats border points. Drop the 'segments' division by calling
# `RouteSlopeDistance.unique_unnested_coordinates_of_multiline_string(mls)`

"""
Leg is used for storing data for drawing a leg on a 2d birds-eye map.

Rules to implement:

1)    A to B and B to A may not exist in the same collection.

2)    Legs may have two paths (multi_linestring), but only if they are not symmetric.

3)    If a Leg with a low-priority label exists in a collection, and
      a leg with equal boundingbox is attempted to be added, then:
      Labels with low prominence are replaced by high prominence labels.

4)    The boundingbox encompasses both paths. It is intended for selecting legs.
"""
struct Leg
    label_A:: LabelUTM
    label_B:: LabelUTM
    bb_utm::BoundingBox
    # World space (utm) horizontal projection
    ABx::Vector{Float64}
    ABy::Vector{Float64}
    BAx::Vector{Float64}
    BAy::Vector{Float64}
end

@kwdef struct ModelSpace
        # Start at 9 leads to first file at 10.
        # Thus, following snapshot will be sorted well in file explorer.
        countimage_startvalue::Int64 = 9
        colorscheme::ColorScheme = ColorSchemes.browncyan
        world_to_model_scale::Float64 = 1.0
        originE::Int64 = 26561
        originN::Int64 = 6940224
        background::Colorant = colorscheme[5]
        linewidth::Float64 = 9.0
        foreground::Colorant = colorscheme[1]
        # Font size for Toy API
        FS = 22
        # The unit EM, as in .css, corresponds to text + margins above and below
        EM = Int(round(FS * 1.16))
        limiting_height::Int64 = 1344
        limiting_width::Int64 = 1792
        margin::NamedTuple{(:t, :b, :l, :r), NTuple{4, Int64}} = (t = 54, b = 81, l = 72, r = 72)
        # LuxorLabels finds the boundingboxes for labels, but isn't properly aware of the current font size.
        # We adjusted this value by feedback from removing comment in `plot_prominent_labels_from_paper_space`
        # We could also adjust the value by prominence, but don't find that necessary.
        crashpadding::Float64 = 2.14
        marker_color::Colorant = foreground
        labels::Vector{LabelModelSpace} = LabelModelSpace[]
end

include("utils.jl")
include("world_space.jl")
include("model_space.jl")
include("paper_space.jl")
include("io.jl")
end