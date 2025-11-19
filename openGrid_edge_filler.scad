/* 
openGrid Edge Filler Library
Autor: (du)

L-förmiger Kantenfüller für openGrid-Tiles (Full, Lite, Heavy).

- Schenkel-DICKE = Tile_Thickness / Lite_Tile_Thickness / Heavy_Tile_Thickness
- Schenkel-LÄNGE = DICKE + ½ Connector-Länge
- Ein Segment hat Länge = tileSize (Tile_Size)
- Für Board_Width/Board_Height werden entsprechend viele Segmente generiert.
- Die Filler werden per Connector_Holes_* ein/ausgeschaltet, analog zu
  den Connector-Ausnehmungen in openGrid.scad.

Benötigt:
    include <BOSL2/std.scad>;
    use <openGrid/openGrid.scad>;
*/

include <BOSL2/std.scad>;
include <openGrid/openGrid.scad>;

//Tile_Size = 28;
//Tile_Thickness = 6.8;
//Lite_Tile_Thickness = 4.0; //0.1
// Heavy_Tile_Thickness = 13.8;

//Tile_Thickness = Lite_Tile_Thickness;
n  = 1;             // für deinen Test

// ==== Connector-Parameter wie in openGrid (connector_cutout_delete_tool) ====
connector_cutout_radius        = 2.6;
connector_cutout_dimple_radius = 2.7;
connector_cutout_separation    = 2.5;
connector_cutout_height        = 2.4;
// calc
connector_full_length = 4 * connector_cutout_radius;
connector_half_length_default = connector_full_length / 2;
// Ergebnis: 5.2 mm

// ==== Hilfsfunktionen =======================================================

function og_edge_tile_thickness(boardType) =
    boardType == "Lite"  ? Lite_Tile_Thickness :
    boardType == "Heavy" ? Heavy_Tile_Thickness :
                           Tile_Thickness;

function og_edge_connector_half_len(boardType) =
    connector_half_length_default;


// ==== 2D-L-Profil (Querschnitt) mit 2 Dreiecken =========================
//
// Lokale Y/Z-Koordinaten:
//   innere Ecke an den Tiles: (0,0)
//   Boden-Schenkel : 0 <= Y <= leg_len, 0 <= Z <= th
//   Wand-Schenkel  : 0 <= Y <= th,      0 <= Z <= leg_len
module og_edge_L_profile(th, conn_half) {
    leg_len = th + conn_half;
    difference() {
        union() { 
            square([leg_len, th], center=false); // L-Profil Boden-Schenkel
            square([th, leg_len], center=false); // L-Profil Wand-Schenkel
            polygon([             // Dreieck-Füllung Mitte (Chamfer)
                [th, th],
                [leg_len, th],
                [th, leg_len]
            ]);
        }
        polygon([
            [0, 0],   // 90-Grad-Ecke Aussen (Chamfer)
            [th, 0],  // Punkt auf x-Achse
            [0, th]   // Punkt auf y-Achse
        ]);
    }
}

// ==== einzelnes Segment (eine Tile-Kante) ===================================
//
// L-Profil mit Chamfer, „auf dem Rücken“ liegend (45°-Fase außen),
// extrudiert über tileSize. Segment wird zentriert via BOSL2 attachable().
//
module openGrid_edge_filler_segment(
    tileSize  = Tile_Size,
    boardType = Full_or_Lite,
    anchor    = CENTER,
    spin      = 0,
    orient    = UP
) {
    th         = og_edge_tile_thickness(boardType);
    conn_half  = og_edge_connector_half_len(boardType);
    leg_len    = th + conn_half;
    len_total  = tileSize;
    back_offset = th / sqrt(2);   // Abstand des Chamfers von der ursprünglichen Ecke

    // Boundingbox des fertigen Fillers:
    // X ≈ tileSize (Extrusionsrichtung)
    // Y/Z ≈ leg_len (Schenkellängen + Chamfer)
    attachable(
        anchor = anchor,
        spin   = spin,
        orient = orient,
        size   = [len_total, leg_len, leg_len]
    ) {

        // Hier könnte man später mit `difference()` arbeiten, um
        // Connector-Aussparungen hineinzuschneiden.

        // 1. um Z drehen (90°), damit Segment in gewünschter Orientierung liegt
        zrot(90)
            // 2. aus der Mitte nach außen schieben:
            //    - in +Y, damit die „innere“ Ecke an der Tile-Kante liegt
            //    - in -Z um back_offset, damit der Chamfer auf Z=0 liegt
            translate([0, tileSize/2, -back_offset])
                // 3. Profil drehen:
                //    - 90° um X: Profil in XZ-Ebene
                //    - -45° um Y (oder X, wie du es gewählt hast), damit es auf dem Chamfer „liegt“
                rotate([90, -45, 0])
                    // 4. L-Profil extrudieren
                    linear_extrude(height = len_total)
                        og_edge_L_profile(th = th, conn_half = conn_half);

        children();
    }
}


// ==== Reihe von Segmenten entlang X oder Y ==================================
//
// entlang="X" → Reihe entlang X (eine Segmentlänge = tileSize)
// entlang="Y" → gleiche Geometrie, um 90° gedreht, entlang Y
//
module openGrid_edge_filler_row(
    Board_Length_Tiles,            // Anzahl Tiles entlang dieser Kante
    tileSize   = Tile_Size,
    boardType  = Full_or_Lite,
    entlang    = "X",              // "X" oder "Y"
    anchor     = CENTER,
    spin       = 0,
    orient     = UP
) {
    th        = og_edge_tile_thickness(boardType);
    conn_half = og_edge_connector_half_len(boardType);
    leg_len   = th + conn_half;
    total_len = Board_Length_Tiles * tileSize;

    attachable(anchor, spin, orient,
               size=[
                   entlang == "X" ? total_len : leg_len,
                   entlang == "X" ? leg_len   : total_len,
                   leg_len
               ]) {

        for (i = [0:Board_Length_Tiles-1]) {
            offset = (i + 0.5) * tileSize - total_len/2  - tileSize/2;

            if (entlang == "X") {
                translate([offset, 0, 0])
                    yrot(90)
                    openGrid_edge_filler_segment(
                        tileSize  = tileSize,
                        boardType = boardType,
                        anchor    = CENTER
                    );
            } else { // entlang Y
                translate([0, offset, 0])
                    yrot(90)
                        openGrid_edge_filler_segment(
                            tileSize  = tileSize,
                            boardType = boardType,
                            anchor    = CENTER
                        );
            }
        }

        children();
    }
}


// ==== Board-bezogene Filler, gesteuert durch Connector_Holes_* ==============
//
// Das Board wird wie openGrid/openGridLite mit anchor=CENTER angenommen.
// Die Filler sitzen direkt an den Kanten (X/Y), innere Ecke auf der
// Board-Kante. Orientierung des L zeigt nach außen.
//
// Du kannst dieses Modul für ein Board separat rendern (oder nur
// die Seiten verwenden, die dich interessieren).
//
module openGrid_edge_fillers_for_board(
    Board_Width,
    Board_Height,
    tileSize  = Tile_Size,
    boardType = Full_or_Lite,
    anchor    = CENTER,
    spin      = 0,
    orient    = UP
) {
    board_w = Board_Width  * tileSize;
    board_h = Board_Height * tileSize;
    th      = og_edge_tile_thickness(boardType);
    conn_h  = og_edge_connector_half_len(boardType);
    leg_len = th + conn_h;

    attachable(anchor, spin, orient,
               size=[board_w, board_h, leg_len]) {

        if (Connector_Holes) {

            // --- rechte Kante (+X), Reihe entlang Y ---
            if (Connector_Holes_Right && Board_Height > 0) {
                translate([ board_w/2, 0, 0 ])
                    xrot(90)    // L vor die Kante kippen
                        openGrid_edge_filler_row(
                            Board_Length_Tiles = Board_Height,
                            tileSize   = tileSize,
                            boardType  = boardType,
                            entlang    = "Y",
                            anchor     = CENTER
                        );
            }

            // --- linke Kante (-X), Reihe entlang Y ---
            if (Connector_Holes_Left && Board_Height > 0) {
                translate([-board_w/2, 0, 0 ])
                    xrot(90)
                    yrot(180) // L nach außen spiegeln
                        openGrid_edge_filler_row(
                            Board_Length_Tiles = Board_Height,
                            tileSize   = tileSize,
                            boardType  = boardType,
                            entlang    = "Y",
                            anchor     = CENTER
                        );
            }

            // --- obere Kante (+Y), Reihe entlang X ---
            if (Connector_Holes_Top && Board_Width > 0) {
                translate([0, board_h/2, 0])
                    xrot(90)
                    zrot(90)
                        openGrid_edge_filler_row(
                            Board_Length_Tiles = Board_Width,
                            tileSize   = tileSize,
                            boardType  = boardType,
                            entlang    = "X",
                            anchor     = CENTER
                        );
            }

            // --- untere Kante (-Y), Reihe entlang X ---
            if (Connector_Holes_Bottom && Board_Width > 0) {
                translate([0, -board_h/2, 0])
                    xrot(90)
                    zrot(-90)
                        openGrid_edge_filler_row(
                            Board_Length_Tiles = Board_Width,
                            tileSize   = tileSize,
                            boardType  = boardType,
                            entlang    = "X",
                            anchor     = CENTER
                        );
            }
        }

        children();
    }
}


// Filler für eine Board-Kante anhand der Seite platzieren.
// side: "right", "left", "bottom", "top"
// n_tiles: Anzahl Tiles entlang dieser Kante

module openGrid_edge_filler_side(
    side,
    n_tiles,
    tileSize  = Tile_Size,
    boardType = Full_or_Lite,
    anchor    = CENTER,
    spin      = 0,
    orient    = UP
) {
    half_span = n_tiles * tileSize / 2;

    attachable(anchor, spin, orient,
               size=[n_tiles*tileSize, n_tiles*tileSize,
                     og_edge_tile_thickness(boardType)
                     + og_edge_connector_half_len(boardType)]) {

        if (side == "right") {
            // 90° zur X-Achse, parallel zur Y-Achse,
            // um n*(1/2*Tile_Size) nach -X verschoben
            translate([-half_span, 0, 0])
                zrot(90)  // Reihe (X) → parallel Y
                    openGrid_edge_filler_row(
                        Board_Length_Tiles = n_tiles,
                        tileSize   = tileSize,
                        boardType  = boardType,
                        entlang    = "X",
                        anchor     = CENTER
                    );

        } else if (side == "left") {
            // 90° zur X-Achse, parallel Y,
            // um n*(1/2*Tile_Size) nach +X verschoben
            translate([ half_span, 0, og_edge_tile_thickness(boardType)])
                rotate([-90, 0, 90])
                    openGrid_edge_filler_row(
                        Board_Length_Tiles = n_tiles,
                        tileSize   = tileSize,
                        boardType  = boardType,
                        entlang    = "X",
                        anchor     = CENTER
                    );

        } else if (side == "bottom") {
            // 90° zur Y-Achse, parallel X,
            // um n*(1/2*Tile_Size) nach -Y verschoben
            translate([0, -half_span, 0])
                openGrid_edge_filler_row(
                    Board_Length_Tiles = n_tiles,
                    tileSize   = tileSize,
                    boardType  = boardType,
                    entlang    = "X",   // Reihe liegt schon entlang X
                    anchor     = CENTER
                );

        } else if (side == "top") {
            // 90° zur Y-Achse, parallel X,
            // um n*(1/2*Tile_Size) nach +Y verschoben
            translate([0,  half_span, 0])
                openGrid_edge_filler_row(
                    Board_Length_Tiles = n_tiles,
                    tileSize   = tileSize,
                    boardType  = boardType,
                    entlang    = "X",
                    anchor     = CENTER
                );
        }

        children();
    }
}
