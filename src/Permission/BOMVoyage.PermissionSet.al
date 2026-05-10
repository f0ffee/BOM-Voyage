permissionset 50100 "BOM Voyage"
{
    Caption = 'BOM Voyage';
    Assignable = true;

    Permissions =
        tabledata "BOM Voyage Setup" = RIMD,
        table "BOM Voyage Setup" = X,
        page "Assembly BOM Diagram" = X,
        page "Production BOM Diagram" = X,
        page "BOM Voyage Setup" = X,
        codeunit "BOM Diagram Mgt." = X,
        codeunit "BOM Diagram Navigation" = X,
        codeunit "Cytoscape BOM Renderer" = X,
        codeunit "Mermaid BOM Renderer" = X;
}
