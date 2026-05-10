codeunit 50102 "Mermaid BOM Renderer" implements "BOM Diagram Renderer"
{
    var
        MaxDepth: Integer;
        ProdBOMNotFoundLbl: Label 'Production BOM not found';
        ItemNotFoundLbl: Label 'Item not found';
        QtyLbl: Label 'Qty: %1', Comment = '%1 = quantity per';
        CycleLbl: Label '%1 (cycle)', Comment = '%1 = node label';

    procedure GetLibraryIdentifier(): Text
    begin
        exit('mermaid');
    end;

    procedure BuildProductionBOMDiagram(ProdBOMNo: Code[20]): Text
    var
        ProdBOMHeader: Record "Production BOM Header";
        Diagram: TextBuilder;
        Path: List of [Code[20]];
        NodeCounter: Integer;
    begin
        InitMaxDepth();

        if not ProdBOMHeader.Get(ProdBOMNo) then begin
            Diagram.AppendLine('graph TD');
            Diagram.AppendLine('    N1["' + Esc(ProdBOMNotFoundLbl) + '"]');
            exit(Diagram.ToText());
        end;

        NodeCounter := 1;
        Diagram.AppendLine('graph TD');
        Diagram.AppendLine('    N1["' + Esc(ProdBOMHeader.Description) + '<br/>' + Esc(Format(ProdBOMNo)) + '"]');
        Diagram.AppendLine('    style N1 fill:#004578,color:#fff,stroke:#002b50,stroke-width:2px');
        Path.Add(ProdBOMNo);
        TraverseProductionBOM(Diagram, ProdBOMNo, 'N1', NodeCounter, 0, Path);
        Path.RemoveAt(Path.Count);

        exit(Diagram.ToText());
    end;

    local procedure TraverseProductionBOM(var Diagram: TextBuilder; ProdBOMNo: Code[20]; ParentNodeId: Text; var NodeCounter: Integer; Depth: Integer; var Path: List of [Code[20]])
    var
        ProdBOMLine: Record "Production BOM Line";
        ProdBOMHeader: Record "Production BOM Header";
        Item: Record Item;
        VersionMgt: Codeunit "VersionManagement";
        ChildId: Text;
        Lbl: Text;
        ActiveVersionCode: Code[20];
        TargetBOMNo: Code[20];
    begin
        if Depth >= MaxDepth then
            exit;

        ActiveVersionCode := VersionMgt.GetBOMVersion(ProdBOMNo, WorkDate(), true);

        ProdBOMLine.SetRange("Production BOM No.", ProdBOMNo);
        ProdBOMLine.SetRange("Version Code", ActiveVersionCode);
        if ProdBOMLine.FindSet() then
            repeat
                NodeCounter += 1;
                ChildId := 'N' + Format(NodeCounter);

                case ProdBOMLine.Type of
                    ProdBOMLine.Type::Item:
                        begin
                            if Item.Get(ProdBOMLine."No.") then
                                Lbl := Esc(Item.Description)
                            else
                                Lbl := Esc(ProdBOMLine."No.");

                            if Item.Get(ProdBOMLine."No.") and (Item."Production BOM No." <> '') then begin
                                TargetBOMNo := Item."Production BOM No.";
                                if Path.Contains(TargetBOMNo) then begin
                                    Lbl := StrSubstNo(CycleLbl, Lbl) + '<br/>' + StrSubstNo(QtyLbl, Format(ProdBOMLine."Quantity per"));
                                    Diagram.AppendLine('    ' + ChildId + '["' + Lbl + '"]');
                                    Diagram.AppendLine('    ' + ParentNodeId + ' --> ' + ChildId);
                                    Diagram.AppendLine('    style ' + ChildId + ' fill:#fde7e9,color:#a4262c,stroke:#c50f1f,stroke-width:3px,stroke-dasharray:5 5');
                                end else begin
                                    Lbl += '<br/>' + StrSubstNo(QtyLbl, Format(ProdBOMLine."Quantity per"));
                                    Diagram.AppendLine('    ' + ChildId + '["' + Lbl + '"]');
                                    Diagram.AppendLine('    ' + ParentNodeId + ' --> ' + ChildId);
                                    Diagram.AppendLine('    style ' + ChildId + ' fill:#0078d4,color:#fff,stroke:#005a9e,stroke-width:2px');
                                    Path.Add(TargetBOMNo);
                                    TraverseProductionBOM(Diagram, TargetBOMNo, ChildId, NodeCounter, Depth + 1, Path);
                                    Path.RemoveAt(Path.Count);
                                end;
                            end else begin
                                Lbl += '<br/>' + StrSubstNo(QtyLbl, Format(ProdBOMLine."Quantity per"));
                                Diagram.AppendLine('    ' + ChildId + '["' + Lbl + '"]');
                                Diagram.AppendLine('    ' + ParentNodeId + ' --> ' + ChildId);
                            end;
                        end;
                    ProdBOMLine.Type::"Production BOM":
                        begin
                            if ProdBOMHeader.Get(ProdBOMLine."No.") then
                                Lbl := Esc(ProdBOMHeader.Description)
                            else
                                Lbl := Esc(ProdBOMLine."No.");

                            TargetBOMNo := ProdBOMLine."No.";
                            if Path.Contains(TargetBOMNo) then begin
                                Lbl := StrSubstNo(CycleLbl, Lbl) + '<br/>' + StrSubstNo(QtyLbl, Format(ProdBOMLine."Quantity per"));
                                Diagram.AppendLine('    ' + ChildId + '["' + Lbl + '"]');
                                Diagram.AppendLine('    ' + ParentNodeId + ' --> ' + ChildId);
                                Diagram.AppendLine('    style ' + ChildId + ' fill:#fde7e9,color:#a4262c,stroke:#c50f1f,stroke-width:3px,stroke-dasharray:5 5');
                            end else begin
                                Lbl += '<br/>' + StrSubstNo(QtyLbl, Format(ProdBOMLine."Quantity per"));
                                Diagram.AppendLine('    ' + ChildId + '["' + Lbl + '"]');
                                Diagram.AppendLine('    ' + ParentNodeId + ' --> ' + ChildId);
                                Diagram.AppendLine('    style ' + ChildId + ' fill:#FF9800,color:#fff');
                                Path.Add(TargetBOMNo);
                                TraverseProductionBOM(Diagram, TargetBOMNo, ChildId, NodeCounter, Depth + 1, Path);
                                Path.RemoveAt(Path.Count);
                            end;
                        end;
                end;
            until ProdBOMLine.Next() = 0;
    end;

    procedure BuildAssemblyBOMDiagram(ItemNo: Code[20]): Text
    var
        Item: Record Item;
        Diagram: TextBuilder;
        Path: List of [Code[20]];
        NodeCounter: Integer;
    begin
        InitMaxDepth();

        if not Item.Get(ItemNo) then begin
            Diagram.AppendLine('graph TD');
            Diagram.AppendLine('    N1["' + Esc(ItemNotFoundLbl) + '"]');
            exit(Diagram.ToText());
        end;

        NodeCounter := 1;
        Diagram.AppendLine('graph TD');
        Diagram.AppendLine('    N1["' + Esc(Item.Description) + '<br/>' + Esc(Format(ItemNo)) + '"]');
        Diagram.AppendLine('    style N1 fill:#004578,color:#fff,stroke:#002b50,stroke-width:2px');
        Path.Add(ItemNo);
        TraverseAssemblyBOM(Diagram, ItemNo, 'N1', NodeCounter, 0, Path);
        Path.RemoveAt(Path.Count);

        exit(Diagram.ToText());
    end;

    local procedure TraverseAssemblyBOM(var Diagram: TextBuilder; ItemNo: Code[20]; ParentNodeId: Text; var NodeCounter: Integer; Depth: Integer; var Path: List of [Code[20]])
    var
        BOMComponent: Record "BOM Component";
        BOMComponentChild: Record "BOM Component";
        Resource: Record Resource;
        ChildId: Text;
        Lbl: Text;
    begin
        if Depth >= MaxDepth then
            exit;

        BOMComponent.SetRange("Parent Item No.", ItemNo);
        if BOMComponent.FindSet() then
            repeat
                NodeCounter += 1;
                ChildId := 'N' + Format(NodeCounter);

                case BOMComponent.Type of
                    BOMComponent.Type::Item:
                        begin
                            Lbl := Esc(BOMComponent.Description);
                            if Lbl = '' then
                                Lbl := Esc(BOMComponent."No.");

                            BOMComponentChild.SetRange("Parent Item No.", BOMComponent."No.");
                            if not BOMComponentChild.IsEmpty() then begin
                                if Path.Contains(BOMComponent."No.") then begin
                                    Lbl := StrSubstNo(CycleLbl, Lbl) + '<br/>' + StrSubstNo(QtyLbl, Format(BOMComponent."Quantity per"));
                                    Diagram.AppendLine('    ' + ChildId + '["' + Lbl + '"]');
                                    Diagram.AppendLine('    ' + ParentNodeId + ' --> ' + ChildId);
                                    Diagram.AppendLine('    style ' + ChildId + ' fill:#fde7e9,color:#a4262c,stroke:#c50f1f,stroke-width:3px,stroke-dasharray:5 5');
                                end else begin
                                    Lbl += '<br/>' + StrSubstNo(QtyLbl, Format(BOMComponent."Quantity per"));
                                    Diagram.AppendLine('    ' + ChildId + '["' + Lbl + '"]');
                                    Diagram.AppendLine('    ' + ParentNodeId + ' --> ' + ChildId);
                                    Diagram.AppendLine('    style ' + ChildId + ' fill:#0078d4,color:#fff,stroke:#005a9e,stroke-width:2px');
                                    Path.Add(BOMComponent."No.");
                                    TraverseAssemblyBOM(Diagram, BOMComponent."No.", ChildId, NodeCounter, Depth + 1, Path);
                                    Path.RemoveAt(Path.Count);
                                end;
                            end else begin
                                Lbl += '<br/>' + StrSubstNo(QtyLbl, Format(BOMComponent."Quantity per"));
                                Diagram.AppendLine('    ' + ChildId + '["' + Lbl + '"]');
                                Diagram.AppendLine('    ' + ParentNodeId + ' --> ' + ChildId);
                            end;
                        end;
                    BOMComponent.Type::Resource:
                        begin
                            if Resource.Get(BOMComponent."No.") then
                                Lbl := Esc(Resource.Name)
                            else
                                Lbl := Esc(BOMComponent."No.");
                            Lbl += '<br/>' + StrSubstNo(QtyLbl, Format(BOMComponent."Quantity per"));

                            Diagram.AppendLine('    ' + ChildId + '(["' + Lbl + '"])');
                            Diagram.AppendLine('    ' + ParentNodeId + ' --> ' + ChildId);
                            Diagram.AppendLine('    style ' + ChildId + ' fill:#f3f2f1,color:#605e5c,stroke:#a19f9d');
                        end;
                end;
            until BOMComponent.Next() = 0;
    end;

    local procedure InitMaxDepth()
    var
        Setup: Record "BOM Diagram Setup";
    begin
        Setup.GetSetup();
        MaxDepth := Setup."Max Depth";
    end;

    /// <summary>
    /// Escapes characters that would break Mermaid label syntax or HTML rendering.
    /// HTML entities (&amp; &lt; &gt;) for the htmlLabels=true rendering layer,
    /// Mermaid #-codes (#quot; #91; #93; #40; #41;) for the syntax layer, since
    /// Mermaid pre-processes those before parsing the flowchart.
    /// </summary>
    local procedure Esc(InputText: Text): Text
    begin
        InputText := InputText.Replace('&', '&amp;');
        InputText := InputText.Replace('<', '&lt;');
        InputText := InputText.Replace('>', '&gt;');
        InputText := InputText.Replace('"', '#quot;');
        InputText := InputText.Replace('[', '#91;');
        InputText := InputText.Replace(']', '#93;');
        InputText := InputText.Replace('(', '#40;');
        InputText := InputText.Replace(')', '#41;');
        exit(InputText);
    end;
}
