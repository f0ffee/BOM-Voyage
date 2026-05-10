page 50101 "Assembly BOM Diagram"
{
    Caption = 'Assembly BOM Diagram';
    PageType = Card;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            usercontrol(BOMDiagram; BOMDiagramControl)
            {
                ApplicationArea = Assembly;

                trigger OnControlReady()
                begin
                    IsReady := true;
                    if ItemNo <> '' then
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
        ItemNo: Code[20];
        IsReady: Boolean;
        DiagramErrorLbl: Label 'Diagram rendering error: %1', Comment = '%1 = error message from the diagram engine';

    procedure SetItemNo(NewItemNo: Code[20])
    begin
        ItemNo := NewItemNo;
        if IsReady then
            RenderBOMDiagram();
    end;

    local procedure RenderBOMDiagram()
    var
        BOMDiagramMgt: Codeunit "BOM Diagram Mgt.";
        LibraryName: Text;
        DiagramData: Text;
    begin
        BOMDiagramMgt.GetAssemblyBOMDiagram(ItemNo, LibraryName, DiagramData);
        CurrPage.BOMDiagram.RenderDiagram(LibraryName, DiagramData);
    end;
}
