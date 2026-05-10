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

    /// <summary>
    /// Opens the standard BC "Prod. BOM Where-Used" page (99000811) for the
    /// clicked item. That page handles its own filtering via SetItem and is the
    /// purpose-built view for this question.
    ///
    /// Resources and BOM nodes have no where-used view today; we return false so
    /// the caller can surface a friendly message instead of opening an empty page.
    /// </summary>
    procedure OpenWhereUsed(NodeCode: Text; NodeType: Text): Boolean
    var
        Item: Record Item;
        ProdBOMWhereUsed: Page "Prod. BOM Where-Used";
        RecordKey: Code[20];
    begin
        if NodeCode = '' then
            exit(false);

        RecordKey := CopyStr(NodeCode, 1, MaxStrLen(RecordKey));

        case NodeType of
            'item', 'subassembly-item':
                if Item.Get(RecordKey) then begin
                    ProdBOMWhereUsed.SetItem(Item, WorkDate());
                    ProdBOMWhereUsed.Run();
                    exit(true);
                end;
        end;
        exit(false);
    end;
}
