pageextension 50101 "Item Card BOM Diagram" extends "Item Card"
{
    actions
    {
        addlast(Assembly)
        {
            action(ViewAssemblyBOMDiagram)
            {
                ApplicationArea = Assembly;
                Caption = 'View Assembly BOM Diagram';
                Image = AssemblyBOM;
                ToolTip = 'View a visual diagram of this item''s Assembly BOM structure.';

                trigger OnAction()
                var
                    AssemblyBOMDiagramPage: Page "Assembly BOM Diagram";
                begin
                    AssemblyBOMDiagramPage.SetItemNo(Rec."No.");
                    AssemblyBOMDiagramPage.Run();
                end;
            }
        }
        addlast(Production)
        {
            action(ViewProductionBOMDiagram)
            {
                ApplicationArea = Manufacturing;
                Caption = 'View Production BOM Diagram';
                Image = BOM;
                ToolTip = 'View a visual diagram of this item''s Production BOM structure.';

                trigger OnAction()
                var
                    ProdBOMDiagramPage: Page "Production BOM Diagram";
                    NoProdBOMLbl: Label 'This item has no Production BOM assigned.';
                begin
                    if Rec."Production BOM No." = '' then begin
                        Message(NoProdBOMLbl);
                        exit;
                    end;
                    ProdBOMDiagramPage.SetBOMNo(Rec."Production BOM No.");
                    ProdBOMDiagramPage.Run();
                end;
            }
        }
    }
}
