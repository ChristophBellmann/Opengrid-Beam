/* 
openGrid Edge Filler Library
Autor: ChatGPT + Christoph :)

L-förmiger Kantenfüller für openGrid-Tiles (Full, Lite, Heavy).

Geometrie:
- Schenkel-DICKE = Tile_Thickness / Lite_Tile_Thickness / Heavy_Tile_Thickness
- Schenkel-LÄNGE = DICKE + ½ Connector-Länge
- Ein Segment hat Länge = tileSize (Tile_Size)
- Für Board_Width/Board_Height werden entsprechend viele Segmente generiert.
- Die Filler werden per Connector_Holes_* ein/ausgeschaltet, analog zu
  den Connector-Ausnehmungen in openGrid.scad.

Benötigt:
    include <BOSL2/std.scad>;
    include <openGrid/openGrid.scad>;
*/

include <BOSL2/std.scad>;
include <openGrid/openGrid.scad>;

Full_or_Lite = "Full";
Board_Length_Tiles = 1;

color("orange")
    openGrid_edge_filler_segment(
        tileSize  = Tile_Size,
        boardType = Full_or_Lite,
        anchor    = CENTER
    );
    
// ======================================================================
// Hilfsfunktionen / Konstanten
// ======================================================================

// Connector-Parameter wie in openGrid (connector_cutout_delete_tool)
connector_cutout_radius        = 2.6;
connector_cutout_dimple_radius = 2.7;
connector_cutout_separation    = 2.5;
connector_cutout_height        = 2.4;

// daraus abgeleitete „Länge“ des Schnapp-Features
connector_length_nominal = 2 * (connector_cutout_radius + connector_cutout_separation); // ≈ 10.2 mm

connector_length_half = connector_length_nominal /2;

// Kacheldicke abhängig vom Typ
function og_edge_tile_thickness(boardType) =
    boardType == "Lite"  ? Lite_Tile_Thickness :
    boardType == "Heavy" ? Heavy_Tile_Thickness :
                           Tile_Thickness;



// ======================================================================
// 2D-L-Profil (Querschnitt) mit Chamfer und gefülltem Dreieck
// ----------------------------------------------------------------------
// Lokale 2D-Koordinaten: (x,y)  – wir interpretieren sie später als
// (Y,Z) des 3D-Objekts.
//
// innere Ecke an den Tiles: (0,0)
// Boden-Schenkel : 0 <= x <= leg_len, 0 <= y <= th
// Wand-Schenkel  : 0 <= x <= th,      0 <= y <= leg_len
//
// Chamfer:
//  - innen: Dreieck [th,th]–[leg_len,th]–[th,leg_len]
//  - außen: Dreieck [0,0]–[th,0]–[0,th] wird weggeschnitten.
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
// EIN SEGMENT (eine Tile-Kante)
// ======================================================================
//
// Ziel: ein V-förmig druckbares „L“, das man in die Ecke zwischen
// Boden-Tile und Wand-Tile schieben kann.
//
// Globale Orientierung nach allen Transformationen:
//
//   - Lange Richtung des Segments: ungefähr Welt-X
//   - Das V (Chamfer) liegt außen, so dass das Teil „auf dem Rücken“ liegt
//     und im 45°-Winkel druckbar ist.
//
// Transformations-Pipeline (von innen nach außen):
//
//   1) og_edge_L_profile(th)   → 2D in (x,y),
//   connector_length_half und dicke zusammen ist min. platz für conn. in 45° Winkel 
//
//   2) linear_extrude(height = len_total)
//         → 3D-Block; Extrusion entlang lokaler +Z
//           Profil liegt weiterhin in (x,y), Länge in Z.
//
//   3) rotate([90,-45,0])
//        - Erst 90° um X: Z → Y, Y → -Z
//        - Dann -45° um Y: kippt das L in ein „V“.
//
//   4) translate([0, tileSize/2, -back_offset])
//        - schiebt das V so, dass die innere Ecke auf der „Kontaktkante“ liegt
//
//   5) zrot(90)
//        - dreht alles, damit die lange Achse ungefähr entlang Welt-X liegt.
//
//   6) attachable(... size=[len_total,leg_len,leg_len])
//        - sorgt dafür, dass das ganze Segment nach außen hin sauber
//          zentriert ist und wie ein BOSL-„Baustein“ benutzt werden kann.
// ==== einzelnes Segment (eine Tile-Kante) ===================================
//
// L-Profil mit Chamfer, „auf dem Rücken“ liegend (45°-Fase außen),
// extrudiert über tileSize. Segment wird zentriert via BOSL2 attachable().
// Rechts und links einfache rechteckige End-Aussparungen.
//
// ==== einzelnes Segment (eine Tile-Kante) ===================================
//
// L-Profil mit Chamfer, „auf dem Rücken“ liegend (45°-Fase außen),
// extrudiert über tileSize. Segment wird zentriert via BOSL2 attachable().
// Hier: einfache rechteckige End-Cutouts (Filler-zu-Filler-Verbindung).
//
module openGrid_edge_filler_segment(
    tileSize  = Tile_Size,
    boardType = Full_or_Lite,
    anchor    = CENTER,
    spin      = 0,
    orient    = UP
) {
    th         = og_edge_tile_thickness(boardType);
    echo("dasisttileheight");
    echo(th);
    leg_len    = th + connector_length_half;
    len_total  = tileSize;
    back_offset = th / sqrt(2);   // Abstand der Chamfer-Ecke

    // Boundingbox des fertigen Fillers:
    // X ≈ len_total (Segmentlänge)
    
    // nicht    Board_Length_Tiles,            // Anzahl Tiles, damit bei einer reihe nicht connectors innerhalb des fillers sind. connectors nur am Anfang und am Ende einer Reihe.
        
        
    // Y/Z ≈ leg_len (Schenkellängen + Chamfer)
    attachable(
        anchor = anchor,
        spin   = spin,
        orient = orient,
        size   = [len_total, leg_len, leg_len]
    ) {

        // *** WICHTIG: ab hier arbeiten wir in einem lokalen Segmentraum ***
        //
        // 1. L-Profil entsteht in XY und wird entlang +Z extrudiert (0..len_total).
        // 2. Dann wird der ganze Block gedreht/verschoben, aber die Cutouts
        //    bekommen GENAU DIESELBE Transformationskette, daher passt alles.

        zrot(90)
        translate([0, tileSize/2, -back_offset])
        rotate([90, -45, 0])
        
        difference() {

            // ---------- 1) Volumen des L-Fillers ----------
            linear_extrude(height = len_total)
                og_edge_L_profile(th = th);

            // ---------- 2) End-Cutouts mit Library-Cutout ----------

         // Querschnitt-Mitte für den Cutout (im L-Profil)
            cut_xy = th + connector_length_half/2 - th/2 + (th-4)/4;    // Punkt mitten in der V-Brücke.
            
            connector_cutout_offset = connector_cutout_radius - 0.05;
            
            // linker End-Cutout (Segmentanfang, z = 0)
            tag("remove")
                translate([cut_xy, cut_xy, connector_cutout_offset])      // X/Y: im Segmentraum , Z: Segmentanfang
                    rotate([0, 90, 45])         // Orientierung des Cutouts
                        connector_cutout_delete_tool(anchor=CENTER,spin=180);

            // rechter End-Cutout (Segmentende, z = len_total)
            tag("remove")
                translate([cut_xy, cut_xy, len_total - connector_cutout_offset])
                    rotate([0, 90, 45])
                        connector_cutout_delete_tool(anchor=CENTER);
        }


        children();
    }
}




// ======================================================================
// REIHE VON SEGMENTEN (entlang einer Board-Kante)
// ======================================================================
//
// entlang="X":
//   - gesamte Reihe läuft entlang Welt-X
//   - n Segmente werden nebeneinander gesetzt
//
// entlang="Y":
//   - ganze Reihe wird um 90° gedreht (zrot(90)), so dass
//     die Segmente insgesamt entlang Y laufen.
// ======================================================================
// ==== Reihe von Segmenten entlang X oder Y =============================
//
// entlang="X" → Reihe entlang X (eine Segmentlänge = tileSize)
// entlang="Y" → gleiche Geometrie, aber Segmente werden entlang Y gesetzt
//
module openGrid_edge_filler_row(
    Board_Length_Tiles,            // Anzahl Tiles entlang dieser Kante
    tileSize   = Tile_Size,
    boardType  = "Lite",
    entlang    = "X",              // "X" oder "Y"
    anchor     = CENTER,
    spin       = 0,
    orient     = UP
) {
    th        = og_edge_tile_thickness(boardType);
    leg_len   = th + connector_length_half;
    total_len = Board_Length_Tiles * tileSize;

    attachable(anchor, spin, orient,
               size=[
                   entlang == "X" ? total_len : leg_len,
                   entlang == "X" ? leg_len   : total_len,
                   leg_len
               ]) {

        for (i = [0:Board_Length_Tiles-1]) {
            offset = (i + 0.5) * tileSize - total_len/2;

            if (entlang == "X") {
                // Reihe entlang X
                translate([offset, 0, 0])
                    openGrid_edge_filler_segment(
                        tileSize  = tileSize,
                        boardType = boardType,
                        anchor    = CENTER
                    );
            } else {
                // Reihe entlang Y
                translate([0, offset, 0])
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



// ======================================================================
// Filler für ein komplettes Board – orientiert wie openGrid/openGridLite
// ======================================================================
//
// Das Board wird wie in openGrid mit anchor=CENTER angenommen.
//
// Die Filler sitzen direkt an den Kanten eines Boards:
//   - rechte Kante (+X)
//   - linke  Kante (-X)
//   - obere  Kante (+Y)
//   - untere Kante (-Y)
//
// Sie werden mit den gleichen Flags wie die Connector-Holes gesteuert:
//   Connector_Holes_*, Connector_Holes.
// ======================================================================
module openGrid_edge_fillers_for_board(
    Board_Width,
    Board_Height,
    tileSize  = Tile_Size,
    boardType = "Lite",
    anchor    = CENTER,
    spin      = 0,
    orient    = UP
) {
    board_w = Board_Width  * tileSize;
    board_h = Board_Height * tileSize;
    th      = og_edge_tile_thickness(boardType);
    leg_len = th + conn_h;

    attachable(anchor, spin, orient,
               size=[board_w, board_h, leg_len]) {

        if (Connector_Holes) {

            // rechte Kante (+X), Reihe entlang Y
            if (Connector_Holes_Right && Board_Height > 0) {
                translate([ board_w/2, 0, 0 ])
                    openGrid_edge_filler_row(
                        Board_Length_Tiles = Board_Height,
                        tileSize   = tileSize,
                        boardType  = boardType,
                        entlang    = "Y",
                        anchor     = CENTER
                    );
            }

            // linke Kante (-X), Reihe entlang Y (gespiegelt)
            if (Connector_Holes_Left && Board_Height > 0) {
                translate([-board_w/2, 0, 0 ])
                    yrot(180)
                        openGrid_edge_filler_row(
                            Board_Length_Tiles = Board_Height,
                            tileSize   = tileSize,
                            boardType  = boardType,
                            entlang    = "Y",
                            anchor     = CENTER
                        );
            }

            // obere Kante (+Y), Reihe entlang X
            if (Connector_Holes_Top && Board_Width > 0) {
                translate([0, board_h/2, 0])
                    openGrid_edge_filler_row(
                        Board_Length_Tiles = Board_Width,
                        tileSize   = tileSize,
                        boardType  = boardType,
                        entlang    = "X",
                        anchor     = CENTER
                    );
            }

            // untere Kante (-Y), Reihe entlang X (gespiegelt)
            if (Connector_Holes_Bottom && Board_Width > 0) {
                translate([0, -board_h/2, 0])
                    yrot(180)
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


// ======================================================================
// MINI-TEST (kannst du in deiner corner-demo.scad einkommentieren)
//
//   include <openGrid/openGrid_edge_filler.scad>;
//
//   Full_or_Lite = "Lite";
//
//   color("orange")
//       openGrid_edge_filler_segment(tileSize=Tile_Size, boardType="Lite");
//
// ======================================================================
