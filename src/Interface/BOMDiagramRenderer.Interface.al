interface "BOM Diagram Renderer"
{
    /// <summary>
    /// Returns the identifier used by the JavaScript control to select the rendering engine.
    /// Must match the switch-case in BOMDiagramControl.js (e.g. 'cytoscape', 'mermaid').
    /// </summary>
    procedure GetLibraryIdentifier(): Text;

    /// <summary>
    /// Builds the diagram payload for a Production BOM.
    /// The format is library-specific (JSON for Cytoscape, text for Mermaid).
    /// </summary>
    procedure BuildProductionBOMDiagram(ProdBOMNo: Code[20]): Text;

    /// <summary>
    /// Builds the diagram payload for an Assembly BOM.
    /// The format is library-specific (JSON for Cytoscape, text for Mermaid).
    /// </summary>
    procedure BuildAssemblyBOMDiagram(ItemNo: Code[20]): Text;
}
