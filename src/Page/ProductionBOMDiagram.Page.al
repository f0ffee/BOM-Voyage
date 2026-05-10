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

                trigger OnNodeClick(NodeCode: Text; NodeType: Text)
                begin
                    OpenNodeCard(NodeCode, NodeType);
                end;

                trigger OnNodeAction(NodeCode: Text; NodeType: Text; ActionCode: Text)
                begin
                    HandleNodeAction(NodeCode, NodeType, ActionCode);
                end;
            }
        }
    }

    var
        BOMNo: Code[20];
        IsReady: Boolean;
        DiagramErrorLbl: Label 'Diagram rendering error: %1', Comment = '%1 = error message from the diagram engine';
        UnknownActionLbl: Label 'Unknown diagram action: %1', Comment = '%1 = action code';
        NoTargetLbl: Label 'Nothing to open for this node.';

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

    local procedure OpenNodeCard(NodeCode: Text; NodeType: Text)
    var
        NavigationMgt: Codeunit "BOM Diagram Navigation";
    begin
        if not NavigationMgt.OpenNodeCard(NodeCode, NodeType) then
            Message(NoTargetLbl);
    end;

    local procedure HandleNodeAction(NodeCode: Text; NodeType: Text; ActionCode: Text)
    var
        NavigationMgt: Codeunit "BOM Diagram Navigation";
    begin
        case ActionCode of
            'open':
                OpenNodeCard(NodeCode, NodeType);
            'where-used':
                if not NavigationMgt.OpenWhereUsed(NodeCode, NodeType, 'production') then
                    Message(NoTargetLbl);
            else
                Message(UnknownActionLbl, ActionCode);
        end;
    end;
}
