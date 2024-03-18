using LuxorLayout
using LuxorLayout: assert_file_exists, byte_description, LIMIT_fsize_read_svg, _read_image
import Luxor
using Luxor: BoundingBox, Point, Drawing, finish, placeimage, snapshot
using Luxor: origin, O, rotate, Partition, settext, box, boxwidth, boxheight
using Luxor: scale, @layer, translate


# The file is copied here, but generated in environment 'MakeMaps'.
const FILELARGE::Ref{String} = "example/split/Routemap.svg"
function fnam_out(i::Int, j::Int)
    fin = FILELARGE[]
    assert_file_exists(fin)
    @assert uppercase(splitext(fin)[2]) == ".SVG"
    split_suffix = "-" * lpad(i, 3, '0') * "-" * lpad(j, 3, '0')
    splitext(fin)[1] * split_suffix * splitext(fin)[2]
end

function image_width_height()
    rimg = _read_image(FILELARGE[])
    rimg.width, rimg.height
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


# TODO:✓1) inline _partitions and check.
#       2) Make a function that creates boundary boxes (to keep), and their indices i and jl
#       3) Incorporate that, too in 'partition'
#       4) Make a new function that also take the parameters necessary for world-to-paper space scaling (or take ModelSpace),
#          and outputs world space boundary boxes and indices.
#       5) Make a new function that takes model space and produces geotiff files.

# Just the math of `partition`, separated out for reuse.
function parameters_for_partitioning(iw, ih; pagewidth = 595, pageheight = 842, 
    gutter_overlap_x = 0,
    gutter_overlap_y = 0,
    centre_rot_cw = 0 * π / 180, Δx = 0.0, Δy = 0.0)
    #
    # Body
    w = iw * abs(cos(centre_rot_cw)) + ih * abs(sin(centre_rot_cw)) - gutter_overlap_x
    h = iw * abs(sin(centre_rot_cw)) + ih * abs(cos(centre_rot_cw)) - gutter_overlap_y
    dx, dy = pagewidth / 2, pageheight / 2
    gx = gutter_overlap_x / 2
    gy = gutter_overlap_y / 2
    # Partition looks nice initially, but it rounds down the number of partitions.
    # We want to include the entire image instead, so we tweak w -> ww and h -> hh, 
    # increased to an integer number of tiles:
    ncols = w / pagewidth |> ceil |> Integer
    nrows = h / pageheight |> ceil |> Integer
    ww = ncols * pagewidth
    hh = nrows * pageheight
    partitions = Partition(ww, hh, pagewidth, pageheight)
    w, h, partitions, gx, gy, dx, dy, ncols, nrows
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
    # Find the width and height of the big drawing on disk.
    rimg = _read_image(FILELARGE[])
    iw, ih  = rimg.width, rimg.height
    # Find the parameters we'll use to split the big drawing.
    # 'partitions' is an iterator defined by Luxor.
    w, h, partitions, gx, gy, dx, dy, ncols, nrows = parameters_for_partitioning(iw, ih; pagewidth, pageheight, gutter_overlap_x, gutter_overlap_y, centre_rot_cw)
    # Place the large disk image on a boundless recording canvas
    Drawing(w, h, :rec)
    origin() # Centre of import area
    rotate(centre_rot_cw)
    placeimage(rimg; centered = true)
    origin() # Drop any rotation
   # rimg = nothing # The image may be extremely large if it contains background bitmaps. Julia would probably release this on its own accord anyway.
    # Take snapshots of printable pieces of the large drawing.
    # Also make an autohotkey script for printing each snapshotted file.
    for (ptc, n) in partitions
        i, j = partitions.currentrow, partitions.currentcol
        cb = bobox(ptc, dx, Δx, gx, dy, Δy, gy)
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
    snapshot(fname = joinpath(splitpath(fnam_out(1,1))[1:end - 1]..., "Partitions_overview.svg"))
end

