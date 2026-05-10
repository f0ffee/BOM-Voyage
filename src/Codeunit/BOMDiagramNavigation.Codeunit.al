codeunit 50103 "BOM Diagram Navigation"
{
    /// <summary>
    /// Opens the appropriate card page for a clicked diagram node.
    /// Returns false when there is nothing to open (root, cycle, unknown record).
    /// </summary>
    procedure OpenNodeCard(NodeCode: Text; NodeType: Text): Boolean
    var
        Item: Record Item;
        Resource: Record Resource;
        ProdBOMHeader: Record "Production BOM Header";
        RecordKey: Code[20];
    begin
        if NodeCode = '' then
            exit(false);

        RecordKey := CopyStr(NodeCode, 1, MaxStrLen(RecordKey));

        case NodeType of
            'item', 'subassembly-item':
                if Item.Get(RecordKey) then begin
                    Page.Run(Page::"Item Card", Item);
                    exit(true);
                end;
            'subassembly-bom':
                if ProdBOMHeader.Get(RecordKey) then begin
                    Page.Run(Page::"Production BOM", ProdBOMHeader);
                    exit(true);
                end;
            'resource':
                if Resource.Get(RecordKey) then begin
                    Page.Run(Page::"Resource Card", Resource);
                    exit(true);
                end;
        end;
        exit(false);
    end;

    procedure OpenWhereUsed(NodeCode: Text; NodeType: Text; DiagramContext: Text): Boolean
    var
        Item: Record Item;
        BOMComp: Record "BOM Component";
        ProdBOMWhereUsed: Page "Prod. BOM Where-Used";
        RecordKey: Code[20];
    begin
        if NodeCode = '' then
            exit(false);

        RecordKey := CopyStr(NodeCode, 1, MaxStrLen(RecordKey));

        case NodeType of
            'item', 'subassembly-item':
                if Item.Get(RecordKey) then begin
                    if DiagramContext = 'assembly' then begin
                        BOMComp.SetRange(Type, BOMComp.Type::Item);
                        BOMComp.SetRange("No.", RecordKey);
                        Page.Run(Page::"Where-Used List", BOMComp);
                    end else begin
                        ProdBOMWhereUsed.SetItem(Item, WorkDate());
                        ProdBOMWhereUsed.Run();
                    end;
                    exit(true);
                end;
        end;
        exit(false);
    end;
}
