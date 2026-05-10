codeunit 50102 "Mermaid BOM Renderer" implements "BOM Diagram Renderer"
{
    var
        MaxDepth: Integer;
        ProdBOMNotFoundLbl: Label 'Production BOM not found';
        ItemNotFoundLbl: Label 'Item not found';
        QtyLbl: Label 'Qty: %1', Comment = '%1 = quantity per';
        QtyUomLbl: Label 'Qty: %1 %2', Comment = '%1 = quantity per, %2 = unit of measure';
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

        Diagram.AppendLine('graph TD');

        if not ProdBOMHeader.Get(ProdBOMNo) then begin
            EmitNode(Diagram, 'N1', ProdBOMNotFoundLbl, '', 'root');
            exit(Diagram.ToText());
        end;

        NodeCounter := 1;
        EmitNode(Diagram, 'N1', ProdBOMHeader.Description + '<br/>' + Format(ProdBOMNo), Format(ProdBOMNo), 'root');
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
        QtyText: Text;
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
                QtyText := FormatQty(Format(ProdBOMLine."Quantity per"), Format(ProdBOMLine."Unit of Measure Code"));

                case ProdBOMLine.Type of
                    ProdBOMLine.Type::Item:
                        begin
                            if Item.Get(ProdBOMLine."No.") then
                                Lbl := Item.Description
                            else
                                Lbl := ProdBOMLine."No.";

                            if Item.Get(ProdBOMLine."No.") and (Item."Production BOM No." <> '') then begin
                                TargetBOMNo := Item."Production BOM No.";
                                if Path.Contains(TargetBOMNo) then begin
                                    EmitNode(Diagram, ChildId, StrSubstNo(CycleLbl, Lbl), ProdBOMLine."No.", 'cycle');
                                    EmitEdge(Diagram, ParentNodeId, ChildId, QtyText);
                                end else begin
                                    EmitNode(Diagram, ChildId, Lbl, ProdBOMLine."No.", 'subassembly-item');
                                    EmitEdge(Diagram, ParentNodeId, ChildId, QtyText);
                                    Path.Add(TargetBOMNo);
                                    TraverseProductionBOM(Diagram, TargetBOMNo, ChildId, NodeCounter, Depth + 1, Path);
                                    Path.RemoveAt(Path.Count);
                                end;
                            end else begin
                                EmitNode(Diagram, ChildId, Lbl, ProdBOMLine."No.", 'item');
                                EmitEdge(Diagram, ParentNodeId, ChildId, QtyText);
                            end;
                        end;
                    ProdBOMLine.Type::"Production BOM":
                        begin
                            if ProdBOMHeader.Get(ProdBOMLine."No.") then
                                Lbl := ProdBOMHeader.Description
                            else
                                Lbl := ProdBOMLine."No.";

                            TargetBOMNo := ProdBOMLine."No.";
                            if Path.Contains(TargetBOMNo) then begin
                                EmitNode(Diagram, ChildId, StrSubstNo(CycleLbl, Lbl), ProdBOMLine."No.", 'cycle');
                                EmitEdge(Diagram, ParentNodeId, ChildId, QtyText);
                            end else begin
                                EmitNode(Diagram, ChildId, Lbl, ProdBOMLine."No.", 'subassembly-bom');
                                EmitEdge(Diagram, ParentNodeId, ChildId, QtyText);
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

        Diagram.AppendLine('graph TD');

        if not Item.Get(ItemNo) then begin
            EmitNode(Diagram, 'N1', ItemNotFoundLbl, '', 'root');
            exit(Diagram.ToText());
        end;

        NodeCounter := 1;
        EmitNode(Diagram, 'N1', Item.Description + '<br/>' + Format(ItemNo), Format(ItemNo), 'root');
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
        QtyText: Text;
    begin
        if Depth >= MaxDepth then
            exit;

        BOMComponent.SetRange("Parent Item No.", ItemNo);
        if BOMComponent.FindSet() then
            repeat
                NodeCounter += 1;
                ChildId := 'N' + Format(NodeCounter);
                QtyText := FormatQty(Format(BOMComponent."Quantity per"), Format(BOMComponent."Unit of Measure Code"));

                case BOMComponent.Type of
                    BOMComponent.Type::Item:
                        begin
                            Lbl := BOMComponent.Description;
                            if Lbl = '' then
                                Lbl := BOMComponent."No.";

                            BOMComponentChild.SetRange("Parent Item No.", BOMComponent."No.");
                            if not BOMComponentChild.IsEmpty() then begin
                                if Path.Contains(BOMComponent."No.") then begin
                                    EmitNode(Diagram, ChildId, StrSubstNo(CycleLbl, Lbl), BOMComponent."No.", 'cycle');
                                    EmitEdge(Diagram, ParentNodeId, ChildId, QtyText);
                                end else begin
                                    EmitNode(Diagram, ChildId, Lbl, BOMComponent."No.", 'subassembly-item');
                                    EmitEdge(Diagram, ParentNodeId, ChildId, QtyText);
                                    Path.Add(BOMComponent."No.");
                                    TraverseAssemblyBOM(Diagram, BOMComponent."No.", ChildId, NodeCounter, Depth + 1, Path);
                                    Path.RemoveAt(Path.Count);
                                end;
                            end else begin
                                EmitNode(Diagram, ChildId, Lbl, BOMComponent."No.", 'item');
                                EmitEdge(Diagram, ParentNodeId, ChildId, QtyText);
                            end;
                        end;
                    BOMComponent.Type::Resource:
                        begin
                            if Resource.Get(BOMComponent."No.") then
                                Lbl := Resource.Name
                            else
                                Lbl := BOMComponent."No.";

                            EmitNode(Diagram, ChildId, Lbl, BOMComponent."No.", 'resource');
                            EmitEdge(Diagram, ParentNodeId, ChildId, QtyText);
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

    local procedure FormatQty(QtyPer: Text; UoM: Text): Text
    begin
        if UoM = '' then
            exit(StrSubstNo(QtyLbl, QtyPer));
        exit(StrSubstNo(QtyUomLbl, QtyPer, UoM));
    end;

    /// <summary>
    /// Emits one node line with inline `style` and a `click` handler bound to the
    /// global JS bridge `onNodeClick(code, type)`. The inline style form (rather
    /// than `:::class` shorthand against a top-level classDef block) is used
    /// because Mermaid 11 does not propagate classDef `color:` through htmlLabels,
    /// leaving labels white-on-white. Inline `style ID color:...` does propagate.
    /// Cycle and root nodes do not receive a click handler.
    /// </summary>
    local procedure EmitNode(var Diagram: TextBuilder; NodeId: Text; NodeLabel: Text; NodeCode: Text; NodeType: Text)
    begin
        Diagram.AppendLine('    ' + NodeId + '["' + Esc(NodeLabel) + '"]');
        Diagram.AppendLine('    style ' + NodeId + ' ' + StyleFor(NodeType));
        if (NodeType <> 'root') and (NodeType <> 'cycle') and (NodeCode <> '') then
            Diagram.AppendLine('    click ' + NodeId + ' call onNodeClick("' + EscArg(NodeCode) + '", "' + NodeType + '")');
    end;

    /// <summary>
    /// Emits an edge with optional label. Uses the `A -- "text" --> B` form
    /// because Mermaid 11 reliably renders edge labels in this syntax, while
    /// `A -->|text| B` and `A -->|"text"| B` both have rendering bugs with
    /// htmlLabels=true (label silently disappears).
    /// </summary>
    local procedure EmitEdge(var Diagram: TextBuilder; ParentNodeId: Text; ChildNodeId: Text; EdgeLabel: Text)
    begin
        if EdgeLabel = '' then
            Diagram.AppendLine('    ' + ParentNodeId + ' --> ' + ChildNodeId)
        else
            Diagram.AppendLine('    ' + ParentNodeId + ' -- "' + Esc(EdgeLabel) + '" --> ' + ChildNodeId);
    end;

    local procedure StyleFor(NodeType: Text): Text
    begin
        case NodeType of
            'root':
                exit('fill:#004578,color:#fff,stroke:#002b50,stroke-width:2px');
            'subassembly-item':
                exit('fill:#0078d4,color:#fff,stroke:#005a9e,stroke-width:2px');
            'subassembly-bom':
                exit('fill:#ff8c00,color:#fff,stroke:#c75300,stroke-width:2px');
            'resource':
                exit('fill:#f3f2f1,color:#605e5c,stroke:#a19f9d,stroke-width:2px');
            'cycle':
                exit('fill:#fde7e9,color:#a4262c,stroke:#c50f1f,stroke-width:3px,stroke-dasharray:5 5');
            else
                exit('fill:#fff,color:#323130,stroke:#c7e0f4,stroke-width:2px');
        end;
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

    local procedure EscArg(InputText: Text): Text
    begin
        InputText := InputText.Replace('\', '\\');
        InputText := InputText.Replace('"', '\"');
        exit(InputText);
    end;
}
