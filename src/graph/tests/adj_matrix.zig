const std = @import("std");

const Graph = @import("../Graph.zig");
const Node = Graph.Node;

fn checkRowEmpty(row: []?i32) bool {
    for (row) |value| {
        if (value != null) return false;
    } else return true;
}

fn checkMatEmpty(mat: []std.ArrayList(?i32)) bool {
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

    try graph.addEdge(node1, &node2, 1);
    if (graph.addEdge(node1, &node2, 1)) |_| {
        return error.TestUnexpectedResult;
    } else |_| {}

    try std.testing.expect(graph._graph_impl.adjacency_matrix._nodes.items.len == 2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items.len == 2);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items.len == 2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items[1] != null);
}

test "AdjMat addDoubleEdge" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyMatrix(alloc);
    defer graph.deinit();

    const node1 = graph.createNode();
    const node2 = graph.createNode();
    try graph.addNode(&node1);
    try graph.addNode(&node2);

    try graph.addDoubleEdge(&node1, &node2, 1);
    if (graph.addEdge(node1, &node2, 1)) |_| {
        return error.TestUnexpectedResult;
    } else |_| {}
    if (graph.addEdge(node2, &node1, 1)) |_| {
        return error.TestUnexpectedResult;
    } else |_| {}
    if (graph.addDoubleEdge(&node1, &node2, 1)) |_| {
        return error.TestUnexpectedResult;
    } else |_| {}
    if (graph.addDoubleEdge(&node2, &node1, 1)) |_| {
        return error.TestUnexpectedResult;
    } else |_| {}

    try std.testing.expect(graph._graph_impl.adjacency_matrix._nodes.items.len == 2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items.len == 2);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items.len == 2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items[1] != null);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[1].items[0] != null);
}

test "AdjMat edgeExists" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyMatrix(alloc);
    defer graph.deinit();

    const node1 = graph.createNode();
    const node2 = graph.createNode();
    try graph.addNode(&node1);
    try graph.addNode(&node2);

    try graph.addEdge(node1, &node2, 1);

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

    try graph.addDoubleEdge(&node1, &node2, 1);
    try graph.addEdge(node1, &node3, 1);
    try graph.addEdge(node3, &node2, 1);

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
    try graph.addEdge(node1, &node2, 1);
    try graph.addEdge(node1, &node3, 1);
    try graph.removeEdge(node1, node2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._nodes.items.len == 3);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items.len == 3);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items.len == 3);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items[1] == null);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items[2] != null);
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
    try graph.addDoubleEdge(&node1, &node2, 1);
    try graph.addDoubleEdge(&node1, &node3, 1);
    try graph.removeDoubleEdge(node1, node2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._nodes.items.len == 3);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items.len == 3);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items.len == 3);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items[1] == null);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[1].items[0] == null);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items[2] != null);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[2].items[0] != null);
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

    try graph.addDoubleEdge(&node1, &node2, 1);
    try graph.addDoubleEdge(&node1, &node3, 1);
    try graph.addEdge(node2, &node3, 1);

    try graph.removeNode(node1);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._nodes.items.len == 2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items.len == 2);
    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[0].items.len == 2);

    try std.testing.expect(graph._graph_impl.adjacency_matrix._edges.items[1].items[0] != null);
    graph._graph_impl.adjacency_matrix._edges.items[1].items[0] = null;
    try std.testing.expect(checkMatEmpty(graph._graph_impl.adjacency_matrix._edges.items));
}

test "AdjMat dfsPath" {
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

    try graph.addDoubleEdge(&a, &b, 1);
    try graph.addDoubleEdge(&a, &c, 1);

    try graph.addDoubleEdge(&b, &d, 1);
    try graph.addDoubleEdge(&b, &e, 1);

    try graph.addDoubleEdge(&c, &e, 1);
    try graph.addDoubleEdge(&c, &f, 1);

    try graph.addDoubleEdge(&d, &e, 1);

    try graph.addDoubleEdge(&e, &g, 1);

    try graph.addDoubleEdge(&f, &g, 1);

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

test "AdjMat bfsPath" {
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

    try graph.addDoubleEdge(&a.node, &b.node, 1);
    try graph.addDoubleEdge(&a.node, &c.node, 1);

    try graph.addDoubleEdge(&b.node, &d.node, 1);
    try graph.addDoubleEdge(&b.node, &e.node, 1);

    try graph.addDoubleEdge(&c.node, &e.node, 1);
    try graph.addDoubleEdge(&c.node, &f.node, 1);

    try graph.addDoubleEdge(&d.node, &e.node, 1);

    try graph.addDoubleEdge(&e.node, &g.node, 1);

    try graph.addDoubleEdge(&f.node, &g.node, 1);

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

test "AdjMat dfsRun" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyMatrix(alloc);
    defer graph.deinit();

    const City = struct {
        node: Node,
        population: u32,
    };

    const populations = [_]u32{ 100, 124, 43, 546, 44, 23, 657 };

    const a: City = .{ .node = graph.createNode(), .population = populations[0] };
    const b: City = .{ .node = graph.createNode(), .population = populations[1] };
    const c: City = .{ .node = graph.createNode(), .population = populations[2] };
    const d: City = .{ .node = graph.createNode(), .population = populations[3] };
    const e: City = .{ .node = graph.createNode(), .population = populations[4] };
    const f: City = .{ .node = graph.createNode(), .population = populations[5] };
    const g: City = .{ .node = graph.createNode(), .population = populations[6] };

    try graph.addNode(&a.node);
    try graph.addNode(&b.node);
    try graph.addNode(&c.node);
    try graph.addNode(&d.node);
    try graph.addNode(&e.node);
    try graph.addNode(&f.node);
    try graph.addNode(&g.node);

    try graph.addDoubleEdge(&a.node, &b.node, 1);
    try graph.addDoubleEdge(&a.node, &c.node, 1);

    try graph.addDoubleEdge(&b.node, &d.node, 1);
    try graph.addDoubleEdge(&b.node, &e.node, 1);

    try graph.addDoubleEdge(&c.node, &e.node, 1);
    try graph.addDoubleEdge(&c.node, &f.node, 1);

    try graph.addDoubleEdge(&d.node, &e.node, 1);

    try graph.addDoubleEdge(&e.node, &g.node, 1);

    try graph.addDoubleEdge(&f.node, &g.node, 1);

    const AddCtx = struct {
        to_add: u32,

        fn addFn(node: *const Node, parent: *const Node, ctx: *anyopaque) void {
            _ = parent;

            const add_ctx: *@This() = @ptrCast(@alignCast(ctx));
            const city: *City = @constCast(@fieldParentPtr("node", node));

            city.population += add_ctx.to_add;
        }
    };
    var ctx: AddCtx = .{ .to_add = 24 };

    try graph.dfsRun(&a.node, AddCtx.addFn, &ctx);
    try graph.dfsRun(&d.node, AddCtx.addFn, &ctx);
    try graph.dfsRun(&f.node, AddCtx.addFn, &ctx);

    try std.testing.expectEqual(a.population, populations[0] + 3 * 24);
    try std.testing.expectEqual(b.population, populations[1] + 3 * 24);
    try std.testing.expectEqual(c.population, populations[2] + 3 * 24);
    try std.testing.expectEqual(d.population, populations[3] + 3 * 24);
    try std.testing.expectEqual(e.population, populations[4] + 3 * 24);
    try std.testing.expectEqual(f.population, populations[5] + 3 * 24);
    try std.testing.expectEqual(g.population, populations[6] + 3 * 24);
}

test "AdjMat bfsRun" {
    const alloc = std.testing.allocator;

    var graph: Graph = .initAdjacencyMatrix(alloc);
    defer graph.deinit();

    const City = struct {
        node: Node,
        population: u32,
    };

    const populations = [_]u32{ 100, 124, 43, 546, 44, 23, 657 };

    const a: City = .{ .node = graph.createNode(), .population = populations[0] };
    const b: City = .{ .node = graph.createNode(), .population = populations[1] };
    const c: City = .{ .node = graph.createNode(), .population = populations[2] };
    const d: City = .{ .node = graph.createNode(), .population = populations[3] };
    const e: City = .{ .node = graph.createNode(), .population = populations[4] };
    const f: City = .{ .node = graph.createNode(), .population = populations[5] };
    const g: City = .{ .node = graph.createNode(), .population = populations[6] };

    try graph.addNode(&a.node);
    try graph.addNode(&b.node);
    try graph.addNode(&c.node);
    try graph.addNode(&d.node);
    try graph.addNode(&e.node);
    try graph.addNode(&f.node);
    try graph.addNode(&g.node);

    try graph.addDoubleEdge(&a.node, &b.node, 1);
    try graph.addDoubleEdge(&a.node, &c.node, 1);

    try graph.addDoubleEdge(&b.node, &d.node, 1);
    try graph.addDoubleEdge(&b.node, &e.node, 1);

    try graph.addDoubleEdge(&c.node, &e.node, 1);
    try graph.addDoubleEdge(&c.node, &f.node, 1);

    try graph.addDoubleEdge(&d.node, &e.node, 1);

    try graph.addDoubleEdge(&e.node, &g.node, 1);

    try graph.addDoubleEdge(&f.node, &g.node, 1);

    const AddCtx = struct {
        to_add: u32,

        fn addFn(node: *const Node, parent: *const Node, ctx: *anyopaque) void {
            _ = parent;

            const add_ctx: *@This() = @ptrCast(@alignCast(ctx));
            const city: *City = @constCast(@fieldParentPtr("node", node));

            city.population += add_ctx.to_add;
        }
    };
    var ctx: AddCtx = .{ .to_add = 24 };

    try graph.bfsRun(&a.node, AddCtx.addFn, &ctx);
    try graph.bfsRun(&d.node, AddCtx.addFn, &ctx);
    try graph.bfsRun(&f.node, AddCtx.addFn, &ctx);

    try std.testing.expectEqual(a.population, populations[0] + 3 * 24);
    try std.testing.expectEqual(b.population, populations[1] + 3 * 24);
    try std.testing.expectEqual(c.population, populations[2] + 3 * 24);
    try std.testing.expectEqual(d.population, populations[3] + 3 * 24);
    try std.testing.expectEqual(e.population, populations[4] + 3 * 24);
    try std.testing.expectEqual(f.population, populations[5] + 3 * 24);
    try std.testing.expectEqual(g.population, populations[6] + 3 * 24);
}
