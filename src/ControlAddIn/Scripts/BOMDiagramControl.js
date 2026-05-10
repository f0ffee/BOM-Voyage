// ============================================================
//  BOMDiagramControl.js — main orchestrator
//  Routes to the active renderer (CytoscapeRenderer / MermaidRenderer)
// ============================================================

var activeRenderer = null;

function buildUI(hint) {
    var root = document.getElementById("controlAddIn");
    root.innerHTML = "";

    var toolbar = document.createElement("div");
    toolbar.id = "diagram-toolbar";
    toolbar.innerHTML =
        '<div class="toolbar-group">' +
        '  <button id="btn-zoom-in" title="Zoom In">&#43;</button>' +
        '  <button id="btn-zoom-out" title="Zoom Out">&minus;</button>' +
        '  <button id="btn-fit" title="Fit to View">Fit</button>' +
        '  <button id="btn-reset" title="Reset to 100 %">1 : 1</button>' +
        '  <span id="zoom-level">100 %</span>' +
        "</div>" +
        '<div class="toolbar-group">' +
        '  <button id="btn-expand" title="Expand All Collapsed Nodes">Expand All</button>' +
        "</div>" +
        '<div class="toolbar-group legend">' +
        '  <span class="legend-item"><span class="legend-dot root"></span>Root</span>' +
        '  <span class="legend-item"><span class="legend-dot subasm"></span>Sub-asm.</span>' +
        '  <span class="legend-item"><span class="legend-dot item"></span>Item</span>' +
        '  <span class="legend-item"><span class="legend-dot resource"></span>Resource</span>' +
        "</div>" +
        '<span class="toolbar-hint">' + (hint || "") + "</span>";
    root.appendChild(toolbar);

    var content = document.createElement("div");
    content.id = "diagram-content";
    root.appendChild(content);

    document.getElementById("btn-zoom-in").addEventListener("click", function () {
        if (activeRenderer) { activeRenderer.zoomIn(); updateZoomLabel(); }
    });
    document.getElementById("btn-zoom-out").addEventListener("click", function () {
        if (activeRenderer) { activeRenderer.zoomOut(); updateZoomLabel(); }
    });
    document.getElementById("btn-fit").addEventListener("click", function () {
        if (activeRenderer) activeRenderer.fit();
    });
    document.getElementById("btn-reset").addEventListener("click", function () {
        if (activeRenderer) { activeRenderer.reset(); updateZoomLabel(); }
    });
    document.getElementById("btn-expand").addEventListener("click", function () {
        if (activeRenderer && activeRenderer.expandAll) activeRenderer.expandAll();
    });
}

function updateZoomLabel() {
    var el = document.getElementById("zoom-level");
    if (el && activeRenderer) el.textContent = Math.round(activeRenderer.getZoomLevel() * 100) + " %";
}

function RenderDiagram(libraryName, diagramData) {
    if (activeRenderer) {
        activeRenderer.destroy();
        activeRenderer = null;
    }

    var lib = libraryName.toLowerCase().trim();

    switch (lib) {
        case "cytoscape":
            activeRenderer = CytoscapeRenderer;
            break;
        case "mermaid":
            activeRenderer = MermaidRenderer;
            break;
        default:
            document.getElementById("controlAddIn").innerHTML =
                '<div class="error">Unknown diagram library: ' + libraryName + "</div>";
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnDiagramError",
                ["Unknown library: " + libraryName]);
            return;
    }

    buildUI(activeRenderer.getHint());

    var container = document.getElementById("diagram-content");
    activeRenderer.render(container, diagramData, updateZoomLabel);
}
