const std = @import("std");

const Graph = @import("../Graph.zig");
const Node = Graph.Node;

fn checkRowEmpty(row: []bool) bool {
    for (row) |value| {
        if (value) return false;
    } else return true;
}

fn checkMatEmpty(mat: []std.ArrayList(bool)) bool {
    for (mat) |*row| {
        if (!checkRowEmpty(row.items)) return false;
    } else return true;
}

test "AdjMat addNode" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyMatrix(alloc);
    defer graph.deinit();

    const node1 = graph.createNode();
    const node2 = graph.createNode();
    try graph.addNode(&node1);
    try graph.addNode(&node2);

    if (graph.addNode(&node1)) |_| {
        return error.TestUnexpectedResult;
    } else |_| {}

    try std.testing.expect(graph._graph_impl.adjacency_matrix._nodes.items.len == 2);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._nodes.items[0] == &node1);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._nodes.items[1] == &node2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items.len == 2);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items.len == 2);

    try std.testing.expect(checkMatEmpty(graph._graph_impl.adjacency_matrix._edges.items));
}

test "AdjMat nodeExists" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyMatrix(alloc);
    defer graph.deinit();

    const node = graph.createNode();
    try graph.addNode(&node);

    try std.testing.expect(graph.nodeExists(node));
    try std.testing.expect(!graph.nodeExists(.{ .id = 5 }));
}

test "AdjMat removeNode simple" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyMatrix(alloc);
    defer graph.deinit();

    const node1 = graph.createNode();
    const node2 = graph.createNode();
    try graph.addNode(&node1);
    try graph.addNode(&node2);

    try std.testing.expect(graph.nodeExists(node1));
    try std.testing.expect(graph.nodeExists(node2));

    if (graph.removeNode(.{ .id = 5 })) |_| {
        return error.TestUnexpectedResult;
    } else |_| {}
    try graph.removeNode(node1);

    try std.testing.expect(!graph.nodeExists(node1));
    try std.testing.expect(graph.nodeExists(node2));

    try std.testing.expect(graph._graph_impl.adjacency_matrix._nodes.items.len == 1);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._nodes.items[0] == &node2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items.len == 1);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items.len == 1);

    try std.testing.expect(checkMatEmpty(graph._graph_impl.adjacency_matrix._edges.items));
}

test "AdjMat addEdge" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyMatrix(alloc);
    defer graph.deinit();

    const node1 = graph.createNode();
    const node2 = graph.createNode();
    try graph.addNode(&node1);
    try graph.addNode(&node2);

    try graph.addEdge(node1, &node2);
    if (graph.addEdge(node1, &node2)) |_| {
        return error.TestUnexpectedResult;
    } else |_| {}

    try std.testing.expect(graph._graph_impl.adjacency_matrix._nodes.items.len == 2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items.len == 2);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items.len == 2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items[1]);
}

test "AdjMat addDoubleEdge" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyMatrix(alloc);
    defer graph.deinit();

    const node1 = graph.createNode();
    const node2 = graph.createNode();
    try graph.addNode(&node1);
    try graph.addNode(&node2);

    try graph.addDoubleEdge(&node1, &node2);
    if (graph.addEdge(node1, &node2)) |_| {
        return error.TestUnexpectedResult;
    } else |_| {}
    if (graph.addEdge(node2, &node1)) |_| {
        return error.TestUnexpectedResult;
    } else |_| {}
    if (graph.addDoubleEdge(&node1, &node2)) |_| {
        return error.TestUnexpectedResult;
    } else |_| {}
    if (graph.addDoubleEdge(&node2, &node1)) |_| {
        return error.TestUnexpectedResult;
    } else |_| {}

    try std.testing.expect(graph._graph_impl.adjacency_matrix._nodes.items.len == 2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items.len == 2);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items.len == 2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items[1]);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[1].items[0]);
}

test "AdjMat edgeExists" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyMatrix(alloc);
    defer graph.deinit();

    const node1 = graph.createNode();
    const node2 = graph.createNode();
    try graph.addNode(&node1);
    try graph.addNode(&node2);

    try graph.addEdge(node1, &node2);

    try std.testing.expect(try graph.edgeExists(node1, node2));
    try std.testing.expect(!try graph.edgeExists(node2, node1));
}

test "AdjMat doubleEdgeExists" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyMatrix(alloc);
    defer graph.deinit();

    const node1 = graph.createNode();
    const node2 = graph.createNode();
    const node3 = graph.createNode();
    try graph.addNode(&node1);
    try graph.addNode(&node2);
    try graph.addNode(&node3);

    try graph.addDoubleEdge(&node1, &node2);
    try graph.addEdge(node1, &node3);
    try graph.addEdge(node3, &node2);

    try std.testing.expect(try graph.doubleEdgeExists(node1, node2));
    try std.testing.expect(try graph.doubleEdgeExists(node2, node1));
    try std.testing.expect(!try graph.doubleEdgeExists(node1, node3));
    try std.testing.expect(!try graph.doubleEdgeExists(node3, node1));
    try std.testing.expect(!try graph.doubleEdgeExists(node2, node3));
    try std.testing.expect(!try graph.doubleEdgeExists(node3, node2));

    try std.testing.expect(try graph.edgeExists(node1, node3));
    try std.testing.expect(try graph.edgeExists(node3, node2));
}

test "AdjMat removeEdge" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyMatrix(alloc);
    defer graph.deinit();

    const node1 = graph.createNode();
    const node2 = graph.createNode();
    const node3 = graph.createNode();
    try graph.addNode(&node1);
    try graph.addNode(&node2);
    try graph.addNode(&node3);

    if (graph.removeEdge(node1, node2)) |_| {
        return error.TestUnexpectedResult;
    } else |_| {}
    try graph.addEdge(node1, &node2);
    try graph.addEdge(node1, &node3);
    try graph.removeEdge(node1, node2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._nodes.items.len == 3);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items.len == 3);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items.len == 3);

    try std.testing.expect(!graph._graph_impl.adjacency_matrix._edges.items[0].items[1]);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items[2]);
}

test "AdjMat removeDoubleEdge" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyMatrix(alloc);
    defer graph.deinit();

    const node1 = graph.createNode();
    const node2 = graph.createNode();
    const node3 = graph.createNode();
    try graph.addNode(&node1);
    try graph.addNode(&node2);
    try graph.addNode(&node3);

    if (graph.removeDoubleEdge(node1, node2)) |_| {
        return error.TestUnexpectedResult;
    } else |_| {}
    try graph.addDoubleEdge(&node1, &node2);
    try graph.addDoubleEdge(&node1, &node3);
    try graph.removeDoubleEdge(node1, node2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._nodes.items.len == 3);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items.len == 3);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items.len == 3);

    try std.testing.expect(!graph._graph_impl.adjacency_matrix._edges.items[0].items[1]);
    try std.testing.expect(!graph._graph_impl.adjacency_matrix._edges.items[1].items[0]);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items[2]);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[2].items[0]);
}

test "AdjMat removeNode hard" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyMatrix(alloc);
    defer graph.deinit();

    const node1 = graph.createNode();
    const node2 = graph.createNode();
    const node3 = graph.createNode();
    try graph.addNode(&node1);
    try graph.addNode(&node2);
    try graph.addNode(&node3);

    try graph.addDoubleEdge(&node1, &node2);
    try graph.addDoubleEdge(&node1, &node3);
    try graph.addEdge(node2, &node3);

    try graph.removeNode(node1);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._nodes.items.len == 2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items.len == 2);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items.len == 2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[1].items[0]);
    graph._graph_impl.adjacency_matrix._edges.items[1].items[0] = false;
    try std.testing.expect(checkMatEmpty(graph._graph_impl.adjacency_matrix._edges.items));
}
