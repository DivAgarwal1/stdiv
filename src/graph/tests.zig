const std = @import("std");

const Graph = @import("Graph.zig");
const Node = Graph.Node;

test "AdjList addNode" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyList(alloc);
    defer graph.deinit();

    const node = graph.createNode();
    try graph.addNode(&node);

    try std.testing.expect(graph._graph_impl.adjacency_list._nodes.items.len == 1);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.size == 1);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.get(node) != null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.get(node).?.items.len == 0);
}

test "AdjList nodeExists" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyList(alloc);

    const node = graph.createNode();
    try graph.addNode(&node);
}
