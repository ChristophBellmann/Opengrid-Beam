include <BOSL2/std.scad>;
include <openGrid/openGrid.scad>;
include <openGrid/openGrid_edge_filler.scad>;

Full_or_Lite = "Lite";

color("orange")
    openGrid_edge_filler_segment(
        tileSize  = Tile_Size,
        boardType = "Lite",
        anchor    = CENTER
    );

// Nur zur Orientierung: dünne Referenzplatte
color("red", 0.5)
    translate([0,0,-0.2])
        cube([Tile_Size*2, 2, 0.4], center = true);
