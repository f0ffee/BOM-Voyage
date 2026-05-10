// ============================================================
//  CytoscapeRenderer — Cytoscape.js + dagre rendering engine
// ============================================================

var CytoscapeRenderer = (function () {
    var cy = null;
    var onZoomChange = null;

    // ───────── Data mapping ─────────

    function buildElements(data) {
        var elements = [];
        (data.nodes || []).forEach(function (n) {
            var label = n.label || "Unknown";
            if (n.type === "root" && n.code) label += "\n" + n.code;
            if (n.qty) {
                label += "\nQty: " + n.qty;
                if (n.uom) label += " " + n.uom;
            }
            elements.push({
                group: "nodes",
                data: { id: n.id, label: label, type: n.type || "item", code: n.code || "" }
            });
        });
        (data.edges || []).forEach(function (e) {
            elements.push({
                group: "edges",
                data: { id: e.source + "_" + e.target, source: e.source, target: e.target }
            });
        });
        return elements;
    }

    // ───────── Stylesheet ─────────

    // Business Central / Fluent UI color palette
    // Nav blue:  #004578 / #002b50    Communication blue: #0078d4 / #005a9e
    // Neutrals:  #323130 (text)  #605e5c (secondary)  #a19f9d (tertiary)
    //            #c8c6c4 (borders)  #edebe9 (bg)  #f3f2f1 (lighter)  #faf9f8 (lightest)
    // Tints:     #deecf9 (light blue)  #c7e0f4 (lighter blue)

    function cyStyle() {
        return [
            {
                selector: "node",
                style: {
                    label: "data(label)", "text-wrap": "wrap", "text-valign": "center",
                    "text-halign": "center", "text-max-width": "180px",
                    "font-family": '"Segoe UI", Roboto, Arial, sans-serif',
                    "font-size": "11px", color: "#323130",
                    "background-color": "#ffffff", "border-color": "#c7e0f4", "border-width": 2,
                    shape: "roundrectangle", width: "label", height: "label", padding: "14px",
                    "transition-property": "border-width, border-color, opacity, background-color",
                    "transition-duration": "0.15s"
                }
            },
            {
                selector: 'node[type="root"]',
                style: {
                    "background-color": "#004578", "border-color": "#002b50", "border-width": 3,
                    color: "#ffffff", "font-size": "13px", "font-weight": "bold", padding: "18px"
                }
            },
            {
                selector: 'node[type="subassembly"]',
                style: {
                    "background-color": "#0078d4", "border-color": "#005a9e",
                    color: "#ffffff", "font-weight": "bold"
                }
            },
            {
                selector: 'node[type="resource"]',
                style: {
                    "background-color": "#f3f2f1", "border-color": "#a19f9d",
                    shape: "ellipse", color: "#605e5c"
                }
            },
            {
                selector: 'node[type="cycle"]',
                style: {
                    "background-color": "#fde7e9", "border-color": "#c50f1f",
                    "border-style": "dashed", "border-width": 3, color: "#a4262c",
                    "font-style": "italic"
                }
            },
            { selector: "node.collapsed", style: { "border-style": "dashed", "border-width": 3 } },
            { selector: "node.highlighted", style: { "border-width": 4, "border-color": "#0078d4" } },
            { selector: ".dimmed", style: { opacity: 0.25 } },
            {
                selector: "edge",
                style: {
                    width: 2, "line-color": "#c8c6c4", "target-arrow-color": "#a19f9d",
                    "target-arrow-shape": "triangle", "curve-style": "bezier", "arrow-scale": 1.2,
                    "transition-property": "line-color, target-arrow-color, width, opacity",
                    "transition-duration": "0.15s"
                }
            },
            {
                selector: "edge.highlighted",
                style: { "line-color": "#0078d4", "target-arrow-color": "#005a9e", width: 3 }
            }
        ];
    }

    // ───────── Layout ─────────

    function dagreOpts() {
        return {
            name: "dagre", rankDir: "TB", nodeSep: 60, edgeSep: 10, rankSep: 80,
            animate: true, animationDuration: 300, fit: true, padding: 50
        };
    }

    function runLayout() {
        if (cy) cy.elements(":visible").layout(dagreOpts()).run();
    }

    // ───────── Interactions ─────────

    function highlightNode(node) {
        var nbh = node.closedNeighborhood();
        cy.batch(function () {
            cy.elements().addClass("dimmed");
            nbh.removeClass("dimmed");
            node.addClass("highlighted");
            node.connectedEdges().addClass("highlighted");
        });
    }

    function unhighlightAll() {
        cy.batch(function () {
            cy.elements().removeClass("dimmed").removeClass("highlighted");
        });
    }

    function toggleCollapse(node) {
        var desc = node.successors();
        if (desc.length === 0) return;
        if (node.hasClass("collapsed")) {
            cy.batch(function () { desc.show(); node.removeClass("collapsed"); desc.nodes().removeClass("collapsed"); });
        } else {
            cy.batch(function () { desc.hide(); node.addClass("collapsed"); });
        }
        runLayout();
    }

    // ───────── Renderer interface ─────────

    return {
        render: function (container, jsonText, zoomCb) {
            onZoomChange = zoomCb;
            var data;
            try { data = JSON.parse(jsonText); } catch (e) {
                container.innerHTML = '<div class="error">Invalid JSON: ' + e.message + "</div>";
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnDiagramError", [e.message]);
                return;
            }
            if (cy) { cy.destroy(); cy = null; }

            cy = cytoscape({
                container: container, elements: buildElements(data), style: cyStyle(),
                layout: dagreOpts(), userZoomingEnabled: true, userPanningEnabled: true,
                boxSelectionEnabled: false, wheelSensitivity: 0.3, minZoom: 0.05, maxZoom: 6
            });

            cy.on("zoom", function () { if (onZoomChange) onZoomChange(); });
            cy.on("layoutstop", function () { if (onZoomChange) onZoomChange(); });
            cy.on("mouseover", "node", function (e) { highlightNode(e.target); });
            cy.on("mouseout", "node", function () { unhighlightAll(); });
            cy.on("dbltap", "node", function (e) { toggleCollapse(e.target); });
        },
        zoomIn: function () {
            if (!cy) return;
            var c = cy.container();
            cy.animate({ zoom: { level: cy.zoom() * 1.3, renderedPosition: { x: c.offsetWidth / 2, y: c.offsetHeight / 2 } } }, { duration: 200 });
        },
        zoomOut: function () {
            if (!cy) return;
            var c = cy.container();
            cy.animate({ zoom: { level: cy.zoom() / 1.3, renderedPosition: { x: c.offsetWidth / 2, y: c.offsetHeight / 2 } } }, { duration: 200 });
        },
        fit: function () {
            if (cy) cy.animate({ fit: { eles: cy.elements(":visible"), padding: 50 } }, { duration: 300 });
        },
        reset: function () { if (cy) { cy.zoom(1); cy.center(); } },
        getZoomLevel: function () { return cy ? cy.zoom() : 1; },
        expandAll: function () {
            if (!cy) return;
            cy.batch(function () { cy.elements().show(); cy.nodes().removeClass("collapsed"); });
            runLayout();
        },
        destroy: function () { if (cy) { cy.destroy(); cy = null; } },
        getHint: function () { return "Double-click a node to collapse / expand"; }
    };
})();
