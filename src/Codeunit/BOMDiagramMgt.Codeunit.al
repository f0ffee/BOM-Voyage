codeunit 50100 "BOM Diagram Mgt."
{
    /// <summary>
    /// Reads the setup, resolves the chosen library via the interface enum,
    /// and returns the library identifier + diagram payload for Production BOM.
    /// </summary>
    procedure GetProductionBOMDiagram(ProdBOMNo: Code[20]; var LibraryName: Text; var DiagramData: Text)
    var
        Renderer: Interface "BOM Diagram Renderer";
    begin
        Renderer := GetRenderer();
        LibraryName := Renderer.GetLibraryIdentifier();
        DiagramData := Renderer.BuildProductionBOMDiagram(ProdBOMNo);
    end;

    /// <summary>
    /// Reads the setup, resolves the chosen library via the interface enum,
    /// and returns the library identifier + diagram payload for Assembly BOM.
    /// </summary>
    procedure GetAssemblyBOMDiagram(ItemNo: Code[20]; var LibraryName: Text; var DiagramData: Text)
    var
        Renderer: Interface "BOM Diagram Renderer";
    begin
        Renderer := GetRenderer();
        LibraryName := Renderer.GetLibraryIdentifier();
        DiagramData := Renderer.BuildAssemblyBOMDiagram(ItemNo);
    end;

    local procedure GetRenderer(): Interface "BOM Diagram Renderer"
    var
        Setup: Record "BOM Diagram Setup";
    begin
        Setup.GetSetup();
        exit(Setup."Diagram Library");
    end;
}
