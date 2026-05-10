# BOM Voyage

Interactive multi-level BOM diagrams for Microsoft Dynamics 365 Business Central — for both **Production BOMs** and **Assembly BOMs**.

Diagrams are rendered inside BC through a Control Add-in with a pluggable rendering engine. Two engines ship out of the box:

- **Cytoscape.js** — interactive graph with pan/zoom, draggable nodes
- **Mermaid.js** — clean, declarative flowchart rendering

Other extensions can register additional engines by implementing the `BOM Diagram Renderer` interface and extending the `BOM Diagram Library` enum.

## Requirements

- Business Central **v28.0** or later (Cloud or OnPrem)
- Base Application dependency (already declared in `app.json`)
- Manufacturing and/or Assembly modules enabled (depending on which BOM type you want to visualize)

## Installation

### From source

1. Open the folder in VS Code with the **AL Language** extension installed.
2. Press `Ctrl+Shift+B` to compile, producing `BOM Voyage_1.0.0.0.app`.
3. Publish to your sandbox via `AL: Publish` (`F5`) or upload the `.app` to a SaaS environment from the Extension Management page.

### From a packaged `.app`

Upload `BOM Voyage_1.0.0.0.app` via **Extension Management → Manage → Upload Extension** and deploy.

## Configuration inside Business Central

After installation:

1. Use **Tell Me** (`Alt+Q`) and search for **BOM Diagram Setup**.
2. Set the following:

   | Field            | Description                                                                                       |
   | ---------------- | ------------------------------------------------------------------------------------------------- |
   | Diagram Library  | Rendering engine — `Cytoscape.js` or `Mermaid.js`. Switch any time; takes effect on next open.    |
   | Max Depth        | Maximum BOM levels to traverse (default `10`, range `1–50`). Cycles are detected independently.   |

The setup record is created automatically on first open with sensible defaults (Cytoscape, depth 10).

## Using the diagrams

Diagrams are launched from the **Item Card**:

- **Assembly → View Assembly BOM Diagram** — shows the multi-level Assembly BOM for the current item.
- **Production → View Production BOM Diagram** — shows the multi-level Production BOM assigned to the current item. If the item has no Production BOM, a message is shown.

Both diagrams can also be opened directly as standalone pages (`Assembly BOM Diagram`, `Production BOM Diagram`) by passing the relevant item or BOM number.

## Choosing a rendering engine

Both engines ship with BOM Voyage and can be swapped from the setup page at any time. They solve different problems:

| Aspect          | Cytoscape.js                                                                 | Mermaid.js                                                                  |
| --------------- | ---------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| Style           | Interactive graph — nodes can be dragged, panned, zoomed.                    | Declarative flowchart — laid out automatically, static once rendered.       |
| Best for        | Exploring large or deep BOMs, rearranging nodes, inspecting structure.       | Quick visual overview, screenshots, sharing a tidy snapshot of a BOM.       |
| Layouts         | Multiple algorithms (breadthfirst, dagre, cose, etc.) tunable at runtime.    | Single auto-layout per direction (TB/LR), fewer knobs but consistent look.  |
| Performance     | Handles hundreds of nodes comfortably with proper layout settings.           | Best on small-to-medium graphs; very large flowcharts can become cramped.   |
| Learning curve  | More API surface — useful if you plan to extend interactivity.               | Minimal — text-in, diagram-out.                                             |

Pick **Cytoscape.js** when users need to *work with* the BOM — drag things around, follow long chains, see a sprawling structure at a glance. Pick **Mermaid.js** when users mainly need to *read* the BOM, paste it into documentation, or want the cleanest default rendering with zero fiddling.

### Licenses

Both libraries are bundled with BOM Voyage and are distributed under permissive open-source licenses:

- **Cytoscape.js** — [MIT License](https://github.com/cytoscape/cytoscape.js/blob/master/LICENSE) © The Cytoscape Consortium
- **Mermaid.js** — [MIT License](https://github.com/mermaid-js/mermaid/blob/develop/LICENSE) © Knut Sveidqvist and contributors

The MIT license permits commercial use, modification, and redistribution provided the copyright and license notice are preserved. No attribution is required at runtime, but the original license texts are retained alongside the bundled scripts.

## Extending with a custom rendering engine

1. Create a codeunit that implements the `BOM Diagram Renderer` interface (`GetLibraryIdentifier`, `BuildProductionBOMDiagram`, `BuildAssemblyBOMDiagram`).
2. Use an `enumextension` on `BOM Diagram Library` to register your new value, mapping `Implementation` to your codeunit.
3. Add a corresponding case in `BOMDiagramControl.js` that handles the identifier returned by `GetLibraryIdentifier()` and renders the payload.

Once published, your engine appears in the **Diagram Library** dropdown on the setup page.

## Object ID range

`50100–50149` — change in `app.json` if it conflicts with your tenant's per-tenant range.

---

Written with <3 and Claude.
