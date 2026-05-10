permissionset 50100 "BOM Voyage"
{
    Caption = 'BOM Voyage';
    Assignable = true;

    Permissions =
        tabledata "BOM Diagram Setup" = RIMD,
        table "BOM Diagram Setup" = X,
        page "Assembly BOM Diagram" = X,
        page "Production BOM Diagram" = X,
        page "BOM Diagram Setup" = X,
        codeunit "BOM Diagram Mgt." = X,
        codeunit "BOM Diagram Navigation" = X,
        codeunit "Cytoscape BOM Renderer" = X,
        codeunit "Mermaid BOM Renderer" = X;
}
