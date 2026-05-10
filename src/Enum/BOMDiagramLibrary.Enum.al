enum 50100 "BOM Diagram Library" implements "BOM Diagram Renderer"
{
    Extensible = true;
    Caption = 'BOM Diagram Library';

    value(0; Cytoscape)
    {
        Caption = 'Cytoscape.js';
        Implementation = "BOM Diagram Renderer" = "Cytoscape BOM Renderer";
    }
    value(1; Mermaid)
    {
        Caption = 'Mermaid.js';
        Implementation = "BOM Diagram Renderer" = "Mermaid BOM Renderer";
    }
}
