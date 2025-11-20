// edge_filler_demo.scad
include <BOSL2/std.scad>;
include <openGrid/openGrid.scad>;
include <openGrid/openGrid_edge_filler.scad>;

Full_or_Lite      = "Lite";
Chamfers          = "Corners";
Screw_Mounting    = "None";
Connector_Holes   = true;
Connector_Holes_Bottom = true;
Connector_Holes_Top    = true;
Connector_Holes_Left   = true;
Connector_Holes_Right  = true;

// --- Parameter -------------------------------------------------------
ts = Tile_Size;                // 28
th = Lite_Tile_Thickness;      // 4

// --- Panels ----------------------------------------------------------

// nach deinen Globals …
n = 1;


module corner_demo() {
/*
    color("magenta") panel_floor();

    // nur Filler unten:
    color("gold")
        openGrid_edge_filler_side(
            side     = "bottom",
            n_tiles  = n,
            tileSize = Tile_Size,
            boardType= Full_or_Lite
        );
    // --- Testaufruf Segment---
    */
    color("orange")
    translate([0,0,0])
        openGrid_edge_filler_segment(
            tileSize  = Tile_Size,
            boardType = "Lite"
        );
        
    /*    
    openGrid_edge_filler_row(
    Board_Length_Tiles,            // Anzahl Tiles entlang dieser Kante
    tileSize   = Tile_Size,
    boardType  = Full_or_Lite,
    entlang    = "X",              // "X" oder "Y"
    anchor     = CENTER,
    spin       = 0,
    orient     = UP
    );
    // Wand später wieder dazu
    */
}


module panel_floor() {
    openGridLite(
        Board_Width       = n,
        Board_Height      = n,
        tileSize          = ts,
        Screw_Mounting    = Screw_Mounting,
        Chamfers          = Chamfers,
        Connector_Holes   = Connector_Holes,
        Add_Adhesive_Base = false,
        anchor            = CENTER
    );
}

module panel_wall() {
    openGridLite(
        Board_Width       = n,
        Board_Height      = n,
        tileSize          = ts,
        Screw_Mounting    = Screw_Mounting,
        Chamfers          = Chamfers,
        Connector_Holes   = Connector_Holes,
        Add_Adhesive_Base = false,
        anchor            = CENTER
    );
}

// --- Demo: Boden + Wand + Edge-Filler an Bottom-Kante des Bodens ----
/*
module corner_demo() {

    // 1) Bodenpanel (XY-Ebene, z=0)
    color("magenta")
        panel_floor();

    // 2) Edge-Filler an BOTTOM-Kante des Bodenpanels:
    //    Filler 90° zur Z-Achse, parallel X, um n*(½*Tile_Size) nach -Y verschoben.
    if (Connector_Holes_Bottom)
        color("gold")
            openGrid_edge_filler_side(
                side     = "left",
                n_tiles  = n,
                tileSize = ts,
                boardType= Full_or_Lite,
                anchor   = CENTER
            );
            
    openGrid_edge_filler_row(
    entlang = "X"
    );

    // 3) Wandpanel:
    //    beginnt da, wo das Bodenpanel „aufhört“.
    //    Verschiebung nach deiner Formel:
    //       n * (½*Tile_Size + Lite_Tile_Thickness) nach +Z
    wall_z = n * (ts/2 + th);

    color("green")
        translate([0, 0, wall_z])
            rotate([-90, 0, 0])   // um X hochklappen
                panel_wall();
}
*/
corner_demo();
