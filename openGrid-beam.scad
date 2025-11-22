/* 
openGrid Beam Library
Autor: ChatGPT + Christoph :)

L-förmiger Kantenfüller Edge Beam für openGrid-Tiles (Full, Lite, Heavy).

Geometrie:
- Schenkel-DICKE = Tile_Thickness / Lite_Tile_Thickness / Heavy_Tile_Thickness
- Schenkel-LÄNGE = DICKE + ½ Connector-Länge
- Ein Segment hat Länge = Tile_Size (Tile_Size)
- Für Beam_width werden entsprechend viele Segmente generiert.
- Die Filler verwenden das originale openGrid-Cutout-Tool.
*/

include <BOSL2/std.scad>;
// include <openGrid/openGrid.scad>;

// ======================================================================
// [Beam Configuration]
// ======================================================================

/*[Beam Configuration]*/
Full_or_Lite = "Lite"; // [Full, Lite]
Beam_width   = 2;      // „logische“ Länge in Zellen (siehe unten)
Tile_Size    = 28;

// Umschalten: Endsegmente halb oder voll
Half_left_end_segment  = true;   // true = linkes Endsegment halb
Half_right_end_segment = true;   // true = rechtes Endsegment halb

// ToDo Endabschluss bauen
Chamfered_at_left_end  = false;
Chamfered_at_right_end = false;
// ToDo Ecke bauen
Left_end_is_corner  = false;
Right_end_is_corner = false;

// ======================================================================
// openGrid-Parameter
// ======================================================================

// Kacheldicken aus openGrid
Full_Tile_Thickness  = 6.8;
Lite_Tile_Thickness  = 4;
Heavy_Tile_Thickness = 13.8;

// Connector-Features aus openGrid cut-out tool
connector_cutout_radius        = 2.6;
connector_cutout_dimple_radius = 2.7;
connector_cutout_separation    = 2.5;
connector_cutout_height        = 2.4; //  + 0.01?
lite_cutout_distance_from_top  = 1;

// Connector-Features abgeleitet
connector_length_half    = connector_cutout_radius + connector_cutout_separation; 
connector_length_nominal = connector_length_half * 2; // ≈ 10.2 mm

// openGrid-border Parameters
Connector_Tolerance   = 0.05; // better 0.1; ? maybe...
Connector_Protrusion  = 2.0;

// Kacheldicke abhängig vom Typ
function og_edge_tile_thickness(boardType) =
    boardType == "Lite"  ? Lite_Tile_Thickness :
    boardType == "Heavy" ? Heavy_Tile_Thickness :
                           Tile_Thickness;

// ======================================================================
// Längen-Funktionen für den Beam
// ======================================================================

// Länge eines Segments i (0..n-1)
function beam_seg_len(i, n) =
    (n <= 1) ? Tile_Size :  // Sonderfall: 1 Segment -> immer voll
    (
        i == 0
            ? (Half_left_end_segment  ? Tile_Size/2 : Tile_Size)
        : i == n-1
            ? (Half_right_end_segment ? Tile_Size/2 : Tile_Size)
        : Tile_Size
    );

// Gesamtlänge des Beams (Summe aller Segmentlängen)
function beam_total_len(n) =
    sum([for (k = [0 : n-1]) beam_seg_len(k, n)]);

// Prefix-Summe bis vor Segment i (Abstand vom linken Ende)
function beam_seg_prefix(i, n) =
    (i <= 0) ? 0 :
    sum([for (k = [0 : i-1]) beam_seg_len(k, n)]);

// Mittelpunkt eines Segments i in X-Richtung
function beam_seg_center(i, n) =
    let(
        L   = beam_total_len(n),
        pre = beam_seg_prefix(i, n),
        li  = beam_seg_len(i, n)
    )
    -L/2 + pre + li/2;

// ======================================================================
// 2D-L-Profil (Querschnitt) mit Chamfer und gefülltem Dreieck
// ======================================================================

module og_edge_L_profile(th) {
    leg_len = th + connector_length_half;

    difference() {
        union() { 
            // Boden-Schenkel
            square([leg_len, th], center=false);
            // Wand-Schenkel
            square([th, leg_len], center=false);
            // Dreieck-Füllung innen (V-förmige „Brücke“)
            polygon([
                [th,      th     ],
                [leg_len, th     ],
                [th,      leg_len]
            ]);
        }

        // äußere 90°-Ecke abflachen (Chamfer außen)
        polygon([
            [0, 0],   // 90°-Ecke
            [th, 0],  // Punkt auf x-Achse
            [0, th]   // Punkt auf y-Achse
        ]);
    }
}

// ======================================================================
// Cutout-Tool aus openGrid
// ======================================================================

module connector_cutout_delete_tool(anchor = CENTER, spin = 0, orient = UP) {
    //Begin connector cutout profile
    connector_cutout_radius        = 2.6;
    connector_cutout_dimple_radius = 2.7;
    connector_cutout_separation    = 2.5;
    connector_cutout_height        = 2.4;
    dimple_radius                  = 0.75 / 2;

    attachable(anchor, spin, orient,
               size=[connector_cutout_radius * 2 - 0.1,
                     connector_cutout_radius * 2,
                     connector_cutout_height]) {
        tag_scope()
            translate([-connector_cutout_radius + 0.05, 0, -connector_cutout_height / 2])
                render()
                    half_of(RIGHT, s=connector_cutout_dimple_radius * 4)
                        linear_extrude(height=connector_cutout_height)
                            union() {
                                left(0.1)
                                    diff() {
                                        $fn = 50;
                                        //primary round pieces
                                        hull()
                                            xcopies(spacing=connector_cutout_radius * 2)
                                                circle(r=connector_cutout_radius);
                                        //inset clip
                                        tag("remove")
                                            right(connector_cutout_radius - connector_cutout_separation)
                                                ycopies(spacing=(connector_cutout_radius + connector_cutout_separation) * 2)
                                                    circle(r=connector_cutout_dimple_radius);
                                    }
                                //outward flare fillet für leichteres Einrasten
                                rect([1,
                                      connector_cutout_separation * 2
                                      - (connector_cutout_dimple_radius - connector_cutout_separation)],
                                     rounding=[0, -.25, -.25, 0],
                                     $fn=32, corner_flip=true, anchor=LEFT);
                            }
        children();
    }
}

// ======================================================================
// EIN SEGMENT (eine Tile-Kante)
// left_mode/right_mode: "end" = Cutout setzen, "top_bot" = mittlere
// ======================================================================

module openGrid_edge_filler_segment(
    boardType = Full_or_Lite,
    anchor    = CENTER,
    spin      = 0,
    orient    = UP,
    left_mode  = "end",   // "end" oder "top_bot"
    right_mode = "end",
    seg_len    = Tile_Size
) {
    th          = og_edge_tile_thickness(boardType);
    leg_len     = th + connector_length_half;
    back_offset = th / sqrt(2);   // Abstand der Chamfer-Ecke
        
    attachable(
        anchor = anchor,
        spin   = spin,
        orient = orient,
        size   = [seg_len, leg_len, leg_len]
    ) {

        zrot(90)
        translate([0, seg_len/2, -back_offset])
        rotate([90, -45, 0])
        difference() {

            // ---------- 1) Volumen des L-Fillers ----------
            linear_extrude(height = seg_len)
                og_edge_L_profile(th = th);

            // ---------- 2) Cutouts für Connectoren ----------

            // Punkt im V-Bereich (XY-Position des Connectors)
            cut_xy = (2*th + connector_length_half - Lite_Tile_Thickness) / 2;
            
            // top center position in V-shape
            cut_zy = Connector_Tolerance + Connector_Protrusion + cut_xy; 
            
            // top lite_cutout_side 45°. 1 mm if Lite. Else, th/2 is centered.
            cut_yz = (th == Lite_Tile_Thickness)
                     ? lite_cutout_distance_from_top + connector_cutout_height/2
                     : th/2; 
            
            // linker End-Cutout (Segmentanfang)
            if (left_mode == "end")
                tag("remove")
                    translate([cut_xy, cut_xy, connector_cutout_radius - Connector_Tolerance])
                        rotate([0, 90, 45])
                            connector_cutout_delete_tool(anchor=CENTER, spin=180);
                            
            // bottom mittlerer Cutout links (Segmentmitte bottom left)
            if (right_mode == "top_bot") {
                tag("remove")  
                    translate([cut_yz, cut_zy, seg_len])
                        rotate([-90, -90, -90])
                            connector_cutout_delete_tool(anchor=CENTER, spin=90);
                            
                // top mittlerer Cutout links (Segmentmitte top left)
                tag("remove")  
                    translate([cut_zy, cut_yz, seg_len])
                        rotate([0, 90, 90])
                            connector_cutout_delete_tool(anchor=CENTER, spin=90);      
            }
            
            // rechter End-Cutout (Segmentende)
            if (right_mode == "end") 
                tag("remove")
                    translate([cut_xy, cut_xy, seg_len])
                        rotate([0, 90, 45])
                            connector_cutout_delete_tool(anchor=CENTER);
                                        
            // bottom mittlerer Cutout rechts (Segmentmitte bottom right)
            if (left_mode == "top_bot") {
                tag("remove")  
                    translate([cut_yz, cut_zy, 0])
                        rotate([-90, -90, -90])
                            connector_cutout_delete_tool(anchor=CENTER, spin=90);
                            
                // top mittlerer Cutout right (Segmentmitte top right)
                tag("remove")  
                    translate([cut_zy, cut_yz, 0])
                        rotate([0, 90, 90])
                            connector_cutout_delete_tool(anchor=CENTER, spin=90);      
            }
        }
        children();
    }
}

// ======================================================================
// Chamfer- und Corner-Elemente für den Beam (an L-Boxen angesetzt)
// ======================================================================

// Keil an der Stirnseite des Beams.
// x=0 ist Stirnfläche, Beam geht nach +X.
module beam_chamfer_fill(left, boardType = Full_or_Lite) {
    th      = og_edge_tile_thickness(boardType);
    leg_len = th + connector_length_half;

    xsign = left ? -1 : 1;

    rotate([0, 90, 0])
        linear_extrude(height = leg_len)
            polygon([
                [0,          0],
                [leg_len,    0],
                [0,         -xsign*leg_len]
            ]);
}

// Eck-Ausschnitt (Corner-Cutout) an der Stirnseite des Beams.
module beam_corner_cutout(left, boardType = Full_or_Lite) {
    th      = og_edge_tile_thickness(boardType);
    leg_len = th + connector_length_half;

    xsign = left ? -1 : 1;

    color("Purple")
    rotate([0, 90, 0])
        linear_extrude(height = leg_len*1.5)
            polygon([
                [-(leg_len),  leg_len],
                [-(leg_len), -leg_len],
                [ (leg_len), -xsign*leg_len]
            ]);
}

// ======================================================================
// BEAM: mehrere Segmente + optionale Chamfers / Corner-Cutouts
// ======================================================================

module openGrid_edge_beam(
    boardType  = Full_or_Lite,
    beam_width = Beam_width,  // Anzahl Segmente
    anchor     = CENTER,
    spin       = 0,
    orient     = UP
) {
    th      = og_edge_tile_thickness(boardType);
    leg_len = th + connector_length_half;
    span    = beam_total_len(beam_width);   // NEU: echte Gesamtlänge

    attachable(
        anchor = anchor,
        spin   = spin,
        orient = orient,
        size   = [span, leg_len, leg_len]
    ) {

        difference() {

            // (a) POSITIVER Körper: alle Segmente + Chamfer
            union() {
                if (beam_width >= 1) {

                    // Manuelles Platzieren mit variabler Segmentlänge
                    for (i = [0 : beam_width-1]) {
                        segL = beam_seg_len(i, beam_width);
                        xctr = beam_seg_center(i, beam_width);

                        translate([xctr, 0, 0])
                            openGrid_edge_filler_segment(
                                boardType  = boardType,
                                anchor     = CENTER,
                                left_mode  = (i == 0) ? "end"     : "top_bot",
                                right_mode = (i == beam_width-1) ? "end" : "top_bot",
                                seg_len    = segL
                            );
                    }
                }

                // Chamfer-Füller direkt an den Enden (Stirnflächen)
                if (Chamfered_at_left_end)
                    translate([-span/2, 0, 0])
                        beam_chamfer_fill(true,  boardType);

                if (Chamfered_at_right_end)
                    translate([+span/2, 0, 0])
                        beam_chamfer_fill(false, boardType);
            }

            // (b) NEGATIVER Körper: Corner-Cutouts
            union() {
                if (Left_end_is_corner)
                    translate([-span/2, 0, 0])
                        beam_corner_cutout(true,  boardType);
                if (Right_end_is_corner)
                    translate([+span/2, 0, 0])
                        beam_corner_cutout(false, boardType);
            }
        }

        children();
    }
}



// ======================================================================
// Vorschau / Render-Call
// ======================================================================

color("orange")
    openGrid_edge_beam(
        boardType  = Full_or_Lite,
        beam_width = Beam_width,
        anchor     = CENTER
    );
