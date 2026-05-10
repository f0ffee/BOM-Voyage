// ============================================================
//  MermaidRenderer — Mermaid.js rendering engine with pan & zoom
// ============================================================

var MermaidRenderer = (function () {
    var initialized = false;
    var renderCount = 0;
    var scale = 1;
    var panX = 0;
    var panY = 0;
    var isPanning = false;
    var startPanX = 0;
    var startPanY = 0;
    var viewport = null;
    var canvas = null;
    var onZoomChange = null;

    function initMermaid() {
        if (initialized) return;
        mermaid.initialize({
            startOnLoad: false,
            theme: "base",
            themeVariables: {
                primaryColor: "#deecf9",
                primaryTextColor: "#323130",
                primaryBorderColor: "#c7e0f4",
                lineColor: "#a19f9d",
                secondaryColor: "#f3f2f1",
                tertiaryColor: "#eff6fc",
                fontFamily: '"Segoe UI", Roboto, Arial, sans-serif',
                fontSize: "13px",
                edgeLabelBackground: "#ffffff"
            },
            flowchart: {
                useMaxWidth: false, htmlLabels: true,
                curve: "basis", nodeSpacing: 40, rankSpacing: 60
            },
            securityLevel: "loose"
        });
        initialized = true;
    }

    function applyTransform() {
        if (canvas)
            canvas.style.transform = "translate(" + panX + "px, " + panY + "px) scale(" + scale + ")";
        if (onZoomChange) onZoomChange();
    }

    function setupPanZoom(vp) {
        viewport = vp;

        vp.addEventListener("wheel", function (e) {
            e.preventDefault();
            var rect = vp.getBoundingClientRect();
            var mx = e.clientX - rect.left;
            var my = e.clientY - rect.top;
            var old = scale;
            var factor = e.deltaY > 0 ? 0.9 : 1.1;
            scale = Math.max(0.1, Math.min(5, scale * factor));
            panX = mx - (mx - panX) * (scale / old);
            panY = my - (my - panY) * (scale / old);
            applyTransform();
        }, { passive: false });

        vp.addEventListener("mousedown", function (e) {
            if (e.button !== 0) return;
            isPanning = true;
            startPanX = e.clientX - panX;
            startPanY = e.clientY - panY;
            vp.style.cursor = "grabbing";
            e.preventDefault();
        });

        document.addEventListener("mousemove", function (e) {
            if (!isPanning) return;
            panX = e.clientX - startPanX;
            panY = e.clientY - startPanY;
            applyTransform();
        });

        document.addEventListener("mouseup", function () {
            if (isPanning) {
                isPanning = false;
                if (viewport) viewport.style.cursor = "grab";
            }
        });
    }

    return {
        render: function (container, mermaidText, zoomCb) {
            onZoomChange = zoomCb;
            initMermaid();
            scale = 1; panX = 0; panY = 0;

            renderCount++;
            var thisRender = renderCount;
            var diagramId = "mermaid-svg-" + thisRender;

            container.className = "mermaid-viewport";
            container.style.cursor = "grab";
            container.innerHTML = "";

            canvas = document.createElement("div");
            canvas.className = "mermaid-canvas";
            container.appendChild(canvas);
            canvas.innerHTML = '<div class="loading">Rendering diagram...</div>';

            setupPanZoom(container);

            mermaid.render(diagramId, mermaidText).then(function (result) {
                if (thisRender !== renderCount) return;
                canvas.innerHTML = result.svg;
                setTimeout(function () {
                    if (thisRender === renderCount) MermaidRenderer.fit();
                }, 120);
            }).catch(function (error) {
                if (thisRender !== renderCount) return;
                var msg = error && error.message ? error.message : String(error);
                canvas.innerHTML = '<div class="error">Rendering error: ' + msg + "</div>";
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnDiagramError", [msg]);
            });
        },

        zoomIn: function () {
            if (!viewport) return;
            var r = viewport.getBoundingClientRect();
            var cx = r.width / 2, cy2 = r.height / 2, old = scale;
            scale = Math.min(5, scale * 1.3);
            panX = cx - (cx - panX) * (scale / old);
            panY = cy2 - (cy2 - panY) * (scale / old);
            applyTransform();
        },

        zoomOut: function () {
            if (!viewport) return;
            var r = viewport.getBoundingClientRect();
            var cx = r.width / 2, cy2 = r.height / 2, old = scale;
            scale = Math.max(0.1, scale / 1.3);
            panX = cx - (cx - panX) * (scale / old);
            panY = cy2 - (cy2 - panY) * (scale / old);
            applyTransform();
        },

        fit: function () {
            if (!viewport || !canvas) return;
            var svg = canvas.querySelector("svg");
            if (!svg) return;
            var vpR = viewport.getBoundingClientRect();
            var svgR = svg.getBoundingClientRect();
            var natW = svgR.width / scale;
            var natH = svgR.height / scale;
            var pad = 40;
            scale = Math.min((vpR.width - pad) / natW, (vpR.height - pad) / natH, 2);
            scale = Math.max(scale, 0.1);
            panX = (vpR.width - natW * scale) / 2;
            panY = (vpR.height - natH * scale) / 2;
            applyTransform();
        },

        reset: function () { scale = 1; panX = 0; panY = 0; applyTransform(); },
        getZoomLevel: function () { return scale; },
        expandAll: function () { /* no-op for Mermaid */ },
        destroy: function () { viewport = null; canvas = null; },
        getHint: function () { return "Scroll to zoom · Drag to pan"; }
    };
})();
