codeunit 50101 "Cytoscape BOM Renderer" implements "BOM Diagram Renderer"
{
    var
        MaxDepth: Integer;
        ProdBOMNotFoundLbl: Label 'Production BOM not found';
        ItemNotFoundLbl: Label 'Item not found';
        CycleLbl: Label '%1 (cycle)', Comment = '%1 = node label';

    procedure GetLibraryIdentifier(): Text
    begin
        exit('cytoscape');
    end;

    procedure BuildProductionBOMDiagram(ProdBOMNo: Code[20]): Text
    var
        ProdBOMHeader: Record "Production BOM Header";
        Nodes: JsonArray;
        Edges: JsonArray;
        Path: List of [Code[20]];
        NodeCounter: Integer;
    begin
        InitMaxDepth();

        if not ProdBOMHeader.Get(ProdBOMNo) then begin
            AddNode(Nodes, 'N1', ProdBOMNotFoundLbl, Format(ProdBOMNo), 'root');
            exit(BuildJson(Nodes, Edges));
        end;

        NodeCounter := 1;
        AddNode(Nodes, 'N1', ProdBOMHeader.Description, Format(ProdBOMNo), 'root');
        Path.Add(ProdBOMNo);
        TraverseProductionBOM(Nodes, Edges, ProdBOMNo, 'N1', NodeCounter, 0, Path);
        Path.RemoveAt(Path.Count);

        exit(BuildJson(Nodes, Edges));
    end;

    local procedure TraverseProductionBOM(var Nodes: JsonArray; var Edges: JsonArray; ProdBOMNo: Code[20]; ParentNodeId: Text; var NodeCounter: Integer; Depth: Integer; var Path: List of [Code[20]])
    var
        ProdBOMLine: Record "Production BOM Line";
        ProdBOMHeader: Record "Production BOM Header";
        Item: Record Item;
        VersionMgt: Codeunit "VersionManagement";
        ChildNodeId: Text;
        NodeLabel: Text;
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
                ChildNodeId := 'N' + Format(NodeCounter);

                case ProdBOMLine.Type of
                    ProdBOMLine.Type::Item:
                        begin
                            if Item.Get(ProdBOMLine."No.") then
                                NodeLabel := Item.Description
                            else
                                NodeLabel := ProdBOMLine."No.";

                            if Item.Get(ProdBOMLine."No.") and (Item."Production BOM No." <> '') then begin
                                TargetBOMNo := Item."Production BOM No.";
                                if Path.Contains(TargetBOMNo) then begin
                                    AddNode(Nodes, ChildNodeId, StrSubstNo(CycleLbl, NodeLabel), ProdBOMLine."No.", 'cycle');
                                    AddEdge(Edges, ParentNodeId, ChildNodeId,
                                        Format(ProdBOMLine."Quantity per"), Format(ProdBOMLine."Unit of Measure Code"));
                                end else begin
                                    AddNode(Nodes, ChildNodeId, NodeLabel, ProdBOMLine."No.", 'subassembly-item');
                                    AddEdge(Edges, ParentNodeId, ChildNodeId,
                                        Format(ProdBOMLine."Quantity per"), Format(ProdBOMLine."Unit of Measure Code"));
                                    Path.Add(TargetBOMNo);
                                    TraverseProductionBOM(Nodes, Edges, TargetBOMNo, ChildNodeId, NodeCounter, Depth + 1, Path);
                                    Path.RemoveAt(Path.Count);
                                end;
                            end else begin
                                AddNode(Nodes, ChildNodeId, NodeLabel, ProdBOMLine."No.", 'item');
                                AddEdge(Edges, ParentNodeId, ChildNodeId,
                                    Format(ProdBOMLine."Quantity per"), Format(ProdBOMLine."Unit of Measure Code"));
                            end;
                        end;
                    ProdBOMLine.Type::"Production BOM":
                        begin
                            if ProdBOMHeader.Get(ProdBOMLine."No.") then
                                NodeLabel := ProdBOMHeader.Description
                            else
                                NodeLabel := ProdBOMLine."No.";

                            TargetBOMNo := ProdBOMLine."No.";
                            if Path.Contains(TargetBOMNo) then begin
                                AddNode(Nodes, ChildNodeId, StrSubstNo(CycleLbl, NodeLabel), ProdBOMLine."No.", 'cycle');
                                AddEdge(Edges, ParentNodeId, ChildNodeId,
                                    Format(ProdBOMLine."Quantity per"), Format(ProdBOMLine."Unit of Measure Code"));
                            end else begin
                                AddNode(Nodes, ChildNodeId, NodeLabel, ProdBOMLine."No.", 'subassembly-bom');
                                AddEdge(Edges, ParentNodeId, ChildNodeId,
                                    Format(ProdBOMLine."Quantity per"), Format(ProdBOMLine."Unit of Measure Code"));
                                Path.Add(TargetBOMNo);
                                TraverseProductionBOM(Nodes, Edges, TargetBOMNo, ChildNodeId, NodeCounter, Depth + 1, Path);
                                Path.RemoveAt(Path.Count);
                            end;
                        end;
                end;
            until ProdBOMLine.Next() = 0;
    end;

    procedure BuildAssemblyBOMDiagram(ItemNo: Code[20]): Text
    var
        Item: Record Item;
        Nodes: JsonArray;
        Edges: JsonArray;
        Path: List of [Code[20]];
        NodeCounter: Integer;
    begin
        InitMaxDepth();

        if not Item.Get(ItemNo) then begin
            AddNode(Nodes, 'N1', ItemNotFoundLbl, Format(ItemNo), 'root');
            exit(BuildJson(Nodes, Edges));
        end;

        NodeCounter := 1;
        AddNode(Nodes, 'N1', Item.Description, Format(ItemNo), 'root');
        Path.Add(ItemNo);
        TraverseAssemblyBOM(Nodes, Edges, ItemNo, 'N1', NodeCounter, 0, Path);
        Path.RemoveAt(Path.Count);

        exit(BuildJson(Nodes, Edges));
    end;

    local procedure TraverseAssemblyBOM(var Nodes: JsonArray; var Edges: JsonArray; ItemNo: Code[20]; ParentNodeId: Text; var NodeCounter: Integer; Depth: Integer; var Path: List of [Code[20]])
    var
        BOMComponent: Record "BOM Component";
        BOMComponentChild: Record "BOM Component";
        Resource: Record Resource;
        ChildNodeId: Text;
        NodeLabel: Text;
    begin
        if Depth >= MaxDepth then
            exit;

        BOMComponent.SetRange("Parent Item No.", ItemNo);
        if BOMComponent.FindSet() then
            repeat
                NodeCounter += 1;
                ChildNodeId := 'N' + Format(NodeCounter);

                case BOMComponent.Type of
                    BOMComponent.Type::Item:
                        begin
                            NodeLabel := BOMComponent.Description;
                            if NodeLabel = '' then
                                NodeLabel := BOMComponent."No.";

                            BOMComponentChild.SetRange("Parent Item No.", BOMComponent."No.");
                            if not BOMComponentChild.IsEmpty() then begin
                                if Path.Contains(BOMComponent."No.") then begin
                                    AddNode(Nodes, ChildNodeId, StrSubstNo(CycleLbl, NodeLabel), BOMComponent."No.", 'cycle');
                                    AddEdge(Edges, ParentNodeId, ChildNodeId,
                                        Format(BOMComponent."Quantity per"), Format(BOMComponent."Unit of Measure Code"));
                                end else begin
                                    AddNode(Nodes, ChildNodeId, NodeLabel, BOMComponent."No.", 'subassembly-item');
                                    AddEdge(Edges, ParentNodeId, ChildNodeId,
                                        Format(BOMComponent."Quantity per"), Format(BOMComponent."Unit of Measure Code"));
                                    Path.Add(BOMComponent."No.");
                                    TraverseAssemblyBOM(Nodes, Edges, BOMComponent."No.", ChildNodeId, NodeCounter, Depth + 1, Path);
                                    Path.RemoveAt(Path.Count);
                                end;
                            end else begin
                                AddNode(Nodes, ChildNodeId, NodeLabel, BOMComponent."No.", 'item');
                                AddEdge(Edges, ParentNodeId, ChildNodeId,
                                    Format(BOMComponent."Quantity per"), Format(BOMComponent."Unit of Measure Code"));
                            end;
                        end;
                    BOMComponent.Type::Resource:
                        begin
                            if Resource.Get(BOMComponent."No.") then
                                NodeLabel := Resource.Name
                            else
                                NodeLabel := BOMComponent."No.";

                            AddNode(Nodes, ChildNodeId, NodeLabel, BOMComponent."No.", 'resource');
                            AddEdge(Edges, ParentNodeId, ChildNodeId,
                                Format(BOMComponent."Quantity per"), Format(BOMComponent."Unit of Measure Code"));
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

    local procedure AddNode(var Nodes: JsonArray; NodeId: Text; NodeLabel: Text; NodeCode: Text; NodeType: Text)
    var
        Node: JsonObject;
    begin
        Node.Add('id', NodeId);
        Node.Add('label', NodeLabel);
        Node.Add('code', NodeCode);
        Node.Add('type', NodeType);
        Nodes.Add(Node);
    end;

    local procedure AddEdge(var Edges: JsonArray; SourceId: Text; TargetId: Text; Qty: Text; UoM: Text)
    var
        Edge: JsonObject;
    begin
        Edge.Add('source', SourceId);
        Edge.Add('target', TargetId);
        if Qty <> '' then
            Edge.Add('qty', Qty);
        if UoM <> '' then
            Edge.Add('uom', UoM);
        Edges.Add(Edge);
    end;

    local procedure BuildJson(var Nodes: JsonArray; var Edges: JsonArray): Text
    var
        GraphData: JsonObject;
        ResultText: Text;
    begin
        GraphData.Add('nodes', Nodes);
        GraphData.Add('edges', Edges);
        GraphData.WriteTo(ResultText);
        exit(ResultText);
    end;
}
