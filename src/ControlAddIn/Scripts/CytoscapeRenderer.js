// ============================================================
//  CytoscapeRenderer — Cytoscape.js + dagre rendering engine
// ============================================================

var CytoscapeRenderer = (function () {
    var cy = null;
    var onZoomChange = null;
    var menuEl = null;

    // ───────── Data mapping ─────────

    function buildElements(data) {
        var elements = [];
        (data.nodes || []).forEach(function (n) {
            var label = n.label || "Unknown";
            if (n.type === "root" && n.code) label += "\n" + n.code;
            elements.push({
                group: "nodes",
                data: { id: n.id, label: label, type: n.type || "item", code: n.code || "" }
            });
        });
        (data.edges || []).forEach(function (e) {
            var edgeLabel = "";
            if (e.qty) {
                edgeLabel = "Qty: " + e.qty;
                if (e.uom) edgeLabel += " " + e.uom;
            }
            elements.push({
                group: "edges",
                data: {
                    id: e.source + "_" + e.target,
                    source: e.source,
                    target: e.target,
                    label: edgeLabel,
                    qty: e.qty || "",
                    uom: e.uom || ""
                }
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
                selector: 'node[type="subassembly-item"], node[type="subassembly"]',
                style: {
                    "background-color": "#0078d4", "border-color": "#005a9e",
                    color: "#ffffff", "font-weight": "bold"
                }
            },
            {
                selector: 'node[type="subassembly-bom"]',
                style: {
                    "background-color": "#ff8c00", "border-color": "#c75300",
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
                    label: "data(label)", "font-size": "10px", color: "#605e5c",
                    "text-background-color": "#ffffff", "text-background-opacity": 0.85,
                    "text-background-padding": "2px", "text-background-shape": "roundrectangle",
                    "text-rotation": "autorotate",
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

    // ───────── Context menu ─────────

    // Items can be JS-only ("hide-subtree", "expand-subtree", "copy-code") or
    // round-tripped to AL via OnNodeAction(code, type, action). Cycle and root
    // nodes get a reduced menu since there is nothing to navigate to.
    function menuItemsFor(node) {
        var t = node.data("type");
        var code = node.data("code");
        var items = [];
        if (t !== "root" && t !== "cycle" && code) {
            items.push({ label: "Open card", action: "open", al: true });
            items.push({ label: "Show where-used", action: "where-used", al: true });
            items.push({ separator: true });
        }
        items.push({ label: "Hide subtree", action: "hide-subtree" });
        items.push({ label: "Expand subtree", action: "expand-subtree" });
        if (code) items.push({ label: "Copy code", action: "copy-code" });
        return items;
    }

    function showContextMenu(node, clientX, clientY) {
        hideContextMenu();
        var items = menuItemsFor(node);
        menuEl = document.createElement("div");
        menuEl.className = "cy-ctx-menu";
        items.forEach(function (item) {
            if (item.separator) {
                var sep = document.createElement("div");
                sep.className = "cy-ctx-sep";
                menuEl.appendChild(sep);
                return;
            }
            var btn = document.createElement("button");
            btn.type = "button";
            btn.className = "cy-ctx-item";
            btn.textContent = item.label;
            btn.addEventListener("click", function (e) {
                e.stopPropagation();
                handleMenuAction(node, item);
                hideContextMenu();
            });
            menuEl.appendChild(btn);
        });
        document.body.appendChild(menuEl);

        // Clamp to viewport
        var rect = menuEl.getBoundingClientRect();
        var x = clientX, y = clientY;
        if (x + rect.width > window.innerWidth) x = window.innerWidth - rect.width - 4;
        if (y + rect.height > window.innerHeight) y = window.innerHeight - rect.height - 4;
        menuEl.style.left = x + "px";
        menuEl.style.top = y + "px";

        setTimeout(function () {
            document.addEventListener("click", hideContextMenu, { once: true });
            document.addEventListener("keydown", onMenuKeyDown);
        }, 0);
    }

    function onMenuKeyDown(e) {
        if (e.key === "Escape") hideContextMenu();
    }

    function hideContextMenu() {
        if (menuEl && menuEl.parentNode) menuEl.parentNode.removeChild(menuEl);
        menuEl = null;
        document.removeEventListener("keydown", onMenuKeyDown);
    }

    function handleMenuAction(node, item) {
        var code = node.data("code");
        var type = node.data("type");
        if (item.al) {
            try {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
                    "OnNodeAction", [code, type, item.action]);
            } catch (e) { /* outside BC harness */ }
            return;
        }
        switch (item.action) {
            case "hide-subtree":
                cy.batch(function () { node.successors().hide(); node.addClass("collapsed"); });
                runLayout();
                break;
            case "expand-subtree":
                cy.batch(function () { node.successors().show(); node.removeClass("collapsed"); node.successors().nodes().removeClass("collapsed"); });
                runLayout();
                break;
            case "copy-code":
                copyToClipboard(code);
                break;
        }
    }

    function copyToClipboard(text) {
        if (!text) return;
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).catch(function () { fallbackCopy(text); });
        } else {
            fallbackCopy(text);
        }
    }

    function fallbackCopy(text) {
        var ta = document.createElement("textarea");
        ta.value = text;
        ta.style.position = "fixed";
        ta.style.opacity = "0";
        document.body.appendChild(ta);
        ta.select();
        try { document.execCommand("copy"); } catch (e) { /* ignore */ }
        document.body.removeChild(ta);
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
            hideContextMenu();

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
            cy.on("cxttap", "node", function (e) {
                var oe = e.originalEvent;
                showContextMenu(e.target, oe.clientX, oe.clientY);
            });
            cy.on("tap", function (e) {
                if (e.target === cy) hideContextMenu();
            });
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
        destroy: function () { hideContextMenu(); if (cy) { cy.destroy(); cy = null; } },
        getHint: function () { return "Double-click to collapse · Right-click for actions"; },
        // Exposed for unit testing
        _internals: {
            buildElements: buildElements,
            menuItemsFor: menuItemsFor
        }
    };
})();
