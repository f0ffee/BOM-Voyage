table 50100 "BOM Voyage Setup"
{
    Caption = 'BOM Voyage Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Diagram Library"; Enum "BOM Diagram Library")
        {
            Caption = 'Diagram Library';
        }
        field(20; "Max Depth"; Integer)
        {
            Caption = 'Max Depth';
            InitValue = 10;
            MinValue = 1;
            MaxValue = 50;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetSetup()
    begin
        if not Get() then begin
            Init();
            "Diagram Library" := "Diagram Library"::Cytoscape;
            "Max Depth" := 10;
            Insert();
        end;
        if "Max Depth" <= 0 then
            "Max Depth" := 10;
    end;
}
