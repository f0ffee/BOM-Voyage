page 50100 "Production BOM Diagram"
{
    Caption = 'Production BOM Diagram';
    PageType = Card;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            usercontrol(BOMDiagram; BOMDiagramControl)
            {
                ApplicationArea = Manufacturing;

                trigger OnControlReady()
                begin
                    IsReady := true;
                    if BOMNo <> '' then
                        RenderBOMDiagram();
                end;

                trigger OnDiagramError(ErrorMessage: Text)
                begin
                    Message(DiagramErrorLbl, ErrorMessage);
                end;
            }
        }
    }

    var
        BOMNo: Code[20];
        IsReady: Boolean;
        DiagramErrorLbl: Label 'Diagram rendering error: %1', Comment = '%1 = error message from the diagram engine';

    procedure SetBOMNo(NewBOMNo: Code[20])
    begin
        BOMNo := NewBOMNo;
        if IsReady then
            RenderBOMDiagram();
    end;

    local procedure RenderBOMDiagram()
    var
        BOMDiagramMgt: Codeunit "BOM Diagram Mgt.";
        LibraryName: Text;
        DiagramData: Text;
    begin
        BOMDiagramMgt.GetProductionBOMDiagram(BOMNo, LibraryName, DiagramData);
        CurrPage.BOMDiagram.RenderDiagram(LibraryName, DiagramData);
    end;
}
