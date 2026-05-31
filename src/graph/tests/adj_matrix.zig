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

test "AdjList dfsPath" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyMatrix(alloc);
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

    const path2 = try graph.dfsPath(&a, g);
    defer alloc.free(path2);

    const path3 = try graph.dfsPath(&a, null);
    defer alloc.free(path3);

    for (0..path1.len - 1) |i| {
        try std.testing.expect(try graph.edgeExists(path1[i].*, path1[i + 1].*));
    }
    try std.testing.expect(path1[path1.len - 1].id == d.id);

    for (0..path2.len - 1) |i| {
        try std.testing.expect(try graph.edgeExists(path2[i].*, path2[i + 1].*));
    }
    try std.testing.expect(path2[path2.len - 1].id == g.id);

    for (0..path3.len - 1) |i| {
        try std.testing.expect(try graph.edgeExists(path3[i].*, path3[i + 1].*));
    }
    try std.testing.expect(path3.len == graph._graph_impl.adjacency_matrix._nodes.items.len);
}

test "AdjList bfsPath" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyMatrix(alloc);
    defer graph.deinit();

    const DepthNode = struct {
        node: Node,
        depth: u32,
    };

    const a: DepthNode = .{ .node = graph.createNode(), .depth = 0 };
    const b: DepthNode = .{ .node = graph.createNode(), .depth = 1 };
    const c: DepthNode = .{ .node = graph.createNode(), .depth = 1 };
    const d: DepthNode = .{ .node = graph.createNode(), .depth = 2 };
    const e: DepthNode = .{ .node = graph.createNode(), .depth = 2 };
    const f: DepthNode = .{ .node = graph.createNode(), .depth = 2 };
    const g: DepthNode = .{ .node = graph.createNode(), .depth = 3 };

    try graph.addNode(&a.node);
    try graph.addNode(&b.node);
    try graph.addNode(&c.node);
    try graph.addNode(&d.node);
    try graph.addNode(&e.node);
    try graph.addNode(&f.node);
    try graph.addNode(&g.node);

    try graph.addDoubleEdge(&a.node, &b.node);
    try graph.addDoubleEdge(&a.node, &c.node);

    try graph.addDoubleEdge(&b.node, &d.node);
    try graph.addDoubleEdge(&b.node, &e.node);

    try graph.addDoubleEdge(&c.node, &e.node);
    try graph.addDoubleEdge(&c.node, &f.node);

    try graph.addDoubleEdge(&d.node, &e.node);

    try graph.addDoubleEdge(&e.node, &g.node);

    try graph.addDoubleEdge(&f.node, &g.node);

    const path1 = try graph.bfsPath(&a.node, d.node);
    defer alloc.free(path1);

    const path2 = try graph.bfsPath(&a.node, g.node);
    defer alloc.free(path2);

    const path3 = try graph.bfsPath(&a.node, null);
    defer alloc.free(path3);

    for (0..path1.len - 1) |i| {
        try std.testing.expect(try graph.edgeExists(path1[i].*, path1[i + 1].*));

        const depth_node_1: *const DepthNode = @fieldParentPtr("node", path1[i]);
        const depth_node_2: *const DepthNode = @fieldParentPtr("node", path1[i + 1]);
        try std.testing.expect(depth_node_2.depth > depth_node_1.depth);
    }
    try std.testing.expect(path1[path1.len - 1].id == d.node.id);

    for (0..path2.len - 1) |i| {
        try std.testing.expect(try graph.edgeExists(path2[i].*, path2[i + 1].*));

        const depth_node_1: *const DepthNode = @fieldParentPtr("node", path2[i]);
        const depth_node_2: *const DepthNode = @fieldParentPtr("node", path2[i + 1]);
        try std.testing.expect(depth_node_2.depth > depth_node_1.depth);
    }
    try std.testing.expect(path2[path2.len - 1].id == g.node.id);

    for (0..path3.len - 1) |i| {
        const depth_node_1: *const DepthNode = @fieldParentPtr("node", path3[i]);
        const depth_node_2: *const DepthNode = @fieldParentPtr("node", path3[i + 1]);
        try std.testing.expect(depth_node_2.depth >= depth_node_1.depth);
    }
    try std.testing.expect(path3.len == graph._graph_impl.adjacency_matrix._nodes.items.len);
}
