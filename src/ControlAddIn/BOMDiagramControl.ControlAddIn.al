controladdin BOMDiagramControl
{
    RequestedHeight = 600;
    RequestedWidth = 900;
    MinimumHeight = 300;
    MinimumWidth = 400;
    MaximumHeight = 1200;
    MaximumWidth = 1920;
    VerticalStretch = true;
    HorizontalStretch = true;

    Scripts =
        'https://cdn.jsdelivr.net/npm/cytoscape@3/dist/cytoscape.min.js',
        'https://cdn.jsdelivr.net/npm/dagre@0.8.5/dist/dagre.min.js',
        'https://cdn.jsdelivr.net/npm/cytoscape-dagre@2/cytoscape-dagre.js',
        'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js',
        'src/ControlAddIn/Scripts/CytoscapeRenderer.js',
        'src/ControlAddIn/Scripts/MermaidRenderer.js',
        'src/ControlAddIn/Scripts/BOMDiagramControl.js';
    StyleSheets = 'src/ControlAddIn/Scripts/BOMDiagramControl.css';
    StartupScript = 'src/ControlAddIn/Scripts/Startup.js';

    event OnControlReady();
    event OnDiagramError(ErrorMessage: Text);
    event OnNodeClick(NodeCode: Text; NodeType: Text);
    event OnNodeAction(NodeCode: Text; NodeType: Text; ActionCode: Text);

    procedure RenderDiagram(LibraryName: Text; DiagramData: Text);
}
