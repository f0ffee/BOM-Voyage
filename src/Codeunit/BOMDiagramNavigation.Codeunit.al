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
        Code20: Code[20];
    begin
        if NodeCode = '' then
            exit(false);

        Code20 := CopyStr(NodeCode, 1, MaxStrLen(Code20));

        case NodeType of
            'item', 'subassembly-item':
                if Item.Get(Code20) then begin
                    Page.Run(Page::"Item Card", Item);
                    exit(true);
                end;
            'subassembly-bom':
                if ProdBOMHeader.Get(Code20) then begin
                    Page.Run(Page::"Production BOM", ProdBOMHeader);
                    exit(true);
                end;
            'resource':
                if Resource.Get(Code20) then begin
                    Page.Run(Page::"Resource Card", Resource);
                    exit(true);
                end;
        end;
        exit(false);
    end;

    /// <summary>
    /// Opens the where-used list for a clicked diagram node.
    /// Currently only Items have a built-in where-used view; resources and BOMs
    /// fall back to false so the caller can show a friendly message.
    /// </summary>
    procedure OpenWhereUsed(NodeCode: Text; NodeType: Text): Boolean
    var
        Item: Record Item;
        Code20: Code[20];
    begin
        if NodeCode = '' then
            exit(false);

        Code20 := CopyStr(NodeCode, 1, MaxStrLen(Code20));

        case NodeType of
            'item', 'subassembly-item':
                if Item.Get(Code20) then begin
                    Page.Run(Page::"Where-Used List", Item);
                    exit(true);
                end;
        end;
        exit(false);
    end;
}
