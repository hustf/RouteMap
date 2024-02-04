# This splits a large svg file into A4-sized partitions,
# without scaling but with rotation. This is handy for 
# preserving text size.
printstyled("Run me like this:\n julia> julia\\dev\\RouteMap> julia --project=. -t2 example/Split/ex_split.jl\n\n", color =:green)
@show Threads.nthreads()
using LuxorLayout
using LuxorLayout: assert_file_exists, byte_description, LIMIT_fsize_read_svg, _read_image
import Luxor
using Luxor: BoundingBox, Point, Drawing, finish, placeimage, snapshot
using Luxor: origin, O, rotate, Partition, settext, box, boxwidth, boxheight

const FILELARGE::Ref{String} = "example/split/Routemap.svg"
function fnam_out(i::Int, j::Int)
    fin = FILELARGE[]
    assert_file_exists(fin)
    @assert uppercase(splitext(fin)[2]) == ".SVG"
    split_suffix = "-" * lpad(i, 3, '0') * "-" * lpad(j, 3, '0')
    splitext(fin)[1] * split_suffix * splitext(fin)[2]
end

# Generate a corresponding autohotkey script to print each file.
# This currently does not close the tabs afterwards properly.
function generate_ahk_script(svgfi::String)
    fi = "\\" * splitpath(svgfi)[end]
    scriptfi = joinpath(splitext(svgfi)[1:end-1]) * ".ahk"
    ahk_script = """
    ; AutoHotKey v2 script to open and print an SVG file
    fileName := "$fi"
    ; Get the directory where the script is located
    scriptDir := A_ScriptDir
    
    ; Full path to the file
    filePath := scriptDir . fileName
    
    ; Start Google Chrome with the SVG file
    Run("chrome.exe " . filePath)
    
    ; Wait for Chrome to load the file
    WinWait("ahk_exe chrome.exe")
    
    ; Sleep for .5  seconds to ensure the page has loaded
    Sleep(500)
    
    ; Press Ctrl+P to open the print dialog
    Send("^p")
    
    ; Wait for 0.5 seconds
    Sleep(500)
    
    ; Send the Enter key to confirm the print command
    Send("{Enter}")

    ; Wait for 1.5 seconds
    Sleep(1500)

    ; Press Ctrl+W to close the tab
    Send("^p")

    ; Wait for 1.5 seconds
    Sleep(1500)

    ; Press Alt + Esc to send Chrome to the back
    Send("!{Esc}")
    """
    # Write the AHK script to a file
    open(scriptfi, "w") do file
        write(file, ahk_script)
    end
end

# Shorthand
bb(x0, y0, x1, y1) = BoundingBox(Point(x0, y0), Point(x1, y1))
function bobox(ptc, dx, Δx, gx, dy, Δy, gy)
    x0 = ptc.x - dx + Δx - gx
    y0 = ptc.y - dy + Δy - gy
    x1 = ptc.x + dx + Δx + gx
    y1 = ptc.y + dy + Δy + gy
    bb(x0 , y0, x1, y1)
end
# Gutter overlap: When printing the results from 
# Inkscape we find that 10 mm is missing from each page. Hence, we add 10 mm
# total horizontally and vertically.  
# 595 pt * 10 mm / 210 mm = 28 pt
# 842 pt * 10 mm / 210 mm = 28
# When printing from Chrome (set the default headers off - it will remember),
# nothing disappears. We set the gutter_overlap to zero.
function partition(;pagewidth = 595, pageheight = 842, 
    gutter_overlap_x = 0,
    gutter_overlap_y = 0,
    centre_rot_cw = 0 * π / 180, Δx = 0.0, Δy = 0.0,
    keep = Tuple[])
    # Body
    rimg = _read_image(FILELARGE[])
    iw, ih  = rimg.width, rimg.height
    w = iw * abs(cos(centre_rot_cw)) + ih * abs(sin(centre_rot_cw)) - gutter_overlap_x
    h = iw * abs(sin(centre_rot_cw)) + ih * abs(cos(centre_rot_cw)) - gutter_overlap_y
    Drawing(w, h, :rec)
    origin() # Centre of import area
    rotate(centre_rot_cw)
    placeimage(rimg; centered = true)
    origin() # Drop any rotation
    dx, dy = pagewidth / 2, pageheight / 2
    # Time to start slicing
    gx = gutter_overlap_x / 2
    gy = gutter_overlap_y / 2
    # Parition looks nice initially, but it rounds down the number of paritions.
    # We want to include the entire image instead, so we tweak w -> ww and h -> hh, 
    # increased to an integer number of tiles:
    ncols = w / pagewidth |> ceil |> Integer
    nrows = h / pageheight |> ceil |> Integer
    ww = ncols * pagewidth
    hh = nrows * pageheight
    @info "Partition parameters:" iw ih w h gx gy cos(centre_rot_cw) sin(centre_rot_cw) pagewidth, pageheight
    partitions = Partition(ww, hh, pagewidth, pageheight)
    for (ptc, n) in partitions
        i, j = partitions.currentrow, partitions.currentcol
        cb = bobox(ptc, dx, Δx, gx, dy, Δy, gy)
       # @show i j cb boxwidth(cb) boxheight(cb)
        if isempty(keep) || (i, j) ∈ keep
            fname = fnam_out(i, j)
            snapshot(;fname, cb)
            generate_ahk_script(fname)
        end
    end
    # Also create a snapshot for zoomed-out inspection
    for (ptc, n) in partitions
        i, j = partitions.currentrow, partitions.currentcol
        cb = bobox(ptc, dx, Δx, gx, dy, Δy, gy)
        box(cb, action = :stroke)
        settext(fnam_out(i, j), ptc + Point(Δx -0.6 * dx, Δy))
    end
    snapshot(fname = joinpath(splitpath(fnam_out(1,1))[1:end - 1]..., "Paritions_overview.svg"))
end
partition(; centre_rot_cw = -51 * π / 180, Δx = 125, keep = [(5,4),
    (4,4),
    (4,3),
    (3,3),
    (2,3),
    (2,4),
    (1,4)])
finish()
#= 
FILELARGE[] = "example/split/t6_font_family.svg"
partition(; pageheight = 822)
=#
