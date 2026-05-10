page 50102 "BOM Diagram Setup"
{
    Caption = 'BOM Diagram Setup';
    PageType = Card;
    SourceTable = "BOM Diagram Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Diagram Library"; Rec."Diagram Library")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the JavaScript library used to render BOM diagrams. Extensible — additional libraries can be added by other extensions.';
                }
                field("Max Depth"; Rec."Max Depth")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many levels deep the BOM diagram is allowed to traverse before stopping. Cycles are detected and stopped regardless of this limit.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
