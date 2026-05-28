const std = @import("std");

const Graph = @import("../Graph.zig");
const Node = Graph.Node;

test "AdjList addNode" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyList(alloc);
    defer graph.deinit();

    const node1 = graph.createNode();
    const node2 = graph.createNode();
    try graph.addNode(&node1);
    try graph.addNode(&node2);

    if (graph.addNode(&node1)) |_| {
        return error.TestUnexpectedResult;
    } else |_| {}

    try std.testing.expect(graph._graph_impl.adjacency_list._nodes.items.len == 2);
    try std.testing.expect(graph._graph_impl.adjacency_list._nodes.items[0] == &node1);
    try std.testing.expect(graph._graph_impl.adjacency_list._nodes.items[1] == &node2);

    try std.testing.expect(graph._graph_impl.adjacency_list._edges.size == 2);

    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node1) != null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node1).?.items.len == 0);

    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node2) != null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node2).?.items.len == 0);
}

test "AdjList nodeExists" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyList(alloc);
    defer graph.deinit();

    const node = graph.createNode();
    try graph.addNode(&node);

    try std.testing.expect(graph.nodeExists(node));
    try std.testing.expect(!graph.nodeExists(.{ .id = 5 }));
}

test "AdjList removeNode simple" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyList(alloc);
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

    try std.testing.expect(graph._graph_impl.adjacency_list._nodes.items.len == 1);
    try std.testing.expect(graph._graph_impl.adjacency_list._nodes.items[0] == &node2);

    try std.testing.expect(graph._graph_impl.adjacency_list._edges.size == 1);

    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node1) == null);

    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node2) != null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node2).?.items.len == 0);
}

test "AdjList addEdge" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyList(alloc);
    defer graph.deinit();

    const node1 = graph.createNode();
    const node2 = graph.createNode();
    try graph.addNode(&node1);
    try graph.addNode(&node2);

    try graph.addEdge(node1, &node2);
    if (graph.addEdge(node1, &node2)) |_| {
        return error.TestUnexpectedResult;
    } else |_| {}

    try std.testing.expect(graph._graph_impl.adjacency_list._nodes.items.len == 2);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.size == 2);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node1) != null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node1).?.items.len == 1);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node1).?.items[0] == &node2);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node2) != null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node2).?.items.len == 0);
}

test "AdjList addDoubleEdge" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyList(alloc);
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

    try std.testing.expect(graph._graph_impl.adjacency_list._nodes.items.len == 2);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.size == 2);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node1) != null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node1).?.items.len == 1);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node1).?.items[0] == &node2);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node2) != null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node2).?.items.len == 1);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node2).?.items[0] == &node1);
}

test "AdjList edgeExists" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyList(alloc);
    defer graph.deinit();

    const node1 = graph.createNode();
    const node2 = graph.createNode();
    try graph.addNode(&node1);
    try graph.addNode(&node2);

    try graph.addEdge(node1, &node2);

    try std.testing.expect(try graph.edgeExists(node1, node2));
    try std.testing.expect(!try graph.edgeExists(node2, node1));
}

test "AdjList doubleEdgeExists" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyList(alloc);
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

test "AdjList removeEdge" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyList(alloc);
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

    try std.testing.expect(graph._graph_impl.adjacency_list._nodes.items.len == 3);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.size == 3);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node1) != null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node1).?.items.len == 1);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node1).?.items[0] == &node3);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node2) != null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node2).?.items.len == 0);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node3) != null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node3).?.items.len == 0);
}

test "AdjList removeDoubleEdge" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyList(alloc);
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

    try std.testing.expect(graph._graph_impl.adjacency_list._nodes.items.len == 3);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.size == 3);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node1) != null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node1).?.items.len == 1);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node1).?.items[0] == &node3);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node2) != null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node2).?.items.len == 0);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node3) != null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node3).?.items.len == 1);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node3).?.items[0] == &node1);
}

test "AdjList removeNode hard" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyList(alloc);
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

    try std.testing.expect(graph._graph_impl.adjacency_list._nodes.items.len == 2);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.size == 2);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node1) == null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node2) != null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node2).?.items.len == 1);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node2).?.items[0] == &node3);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node3) != null);
    try std.testing.expect(graph._graph_impl.adjacency_list._edges.getPtr(node3).?.items.len == 0);
}

test "AdjList dfsPath" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyList(alloc);
    defer graph.deinit();

    const a = graph.createNode();
    const b = graph.createNode();
    const c = graph.createNode();
    const d = graph.createNode();
    const e = graph.createNode();
    const f = graph.createNode();
    const g = graph.createNode();

    try graph.addNode(&a);
    try graph.addNode(&b);
    try graph.addNode(&c);
    try graph.addNode(&d);
    try graph.addNode(&e);
    try graph.addNode(&f);
    try graph.addNode(&g);

    try graph.addDoubleEdge(&a, &b);
    try graph.addDoubleEdge(&a, &c);

    try graph.addDoubleEdge(&b, &d);
    try graph.addDoubleEdge(&b, &e);

    try graph.addDoubleEdge(&c, &e);
    try graph.addDoubleEdge(&c, &f);

    try graph.addDoubleEdge(&d, &e);

    try graph.addDoubleEdge(&e, &g);

    try graph.addDoubleEdge(&f, &g);

    const path1 = try graph.dfsPath(&a, d);
    defer alloc.free(path1);

    const path2 = try graph.dfsPath(&a, null);
    defer alloc.free(path2);

    std.debug.print("Path1:\n", .{});
    for (path1, 0..) |node, i| {
        std.debug.print("{d}: {d}\n", .{ i, node.id });
    }

    std.debug.print("Path2:\n", .{});
    for (path2, 0..) |node, i| {
        std.debug.print("{d}: {d}\n", .{ i, node.id });
    }
}
