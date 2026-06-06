const std = @import("std");

pub const Node = @import("Node.zig");

const AdjacencyList = @import("AdjacencyList.zig");
const AdjacencyMatrix = @import("AdjacencyMatrix.zig");

const Self = @This();

const GraphImpl = union(enum) {
    adjacency_list: AdjacencyList,
    adjacency_matrix: AdjacencyMatrix,
};

_curr_node_id: i32 = -1,
_graph_impl: GraphImpl,

pub fn initAdjacencyList(alloc: std.mem.Allocator) Self {
    return .{ ._graph_impl = .{ .adjacency_list = .init(alloc) } };
}

pub fn initAdjacencyMatrix(alloc: std.mem.Allocator) Self {
    return .{ ._graph_impl = .{ .adjacency_matrix = .init(alloc) } };
}

pub fn deinit(self: *Self) void {
    switch (self._graph_impl) {
        inline else => |*impl| impl.deinit(),
    }
}

pub fn addNode(self: *Self, node: *const Node) !void {
    switch (self._graph_impl) {
        inline else => |*impl| try impl.addNode(node),
    }
}

pub fn nodeExists(self: *const Self, node: Node) bool {
    return switch (self._graph_impl) {
        inline else => |*impl| impl.nodeExists(node),
    };
}

pub fn removeNode(self: *Self, node: Node) !void {
    switch (self._graph_impl) {
        inline else => |*impl| try impl.removeNode(node),
    }
}

pub fn addEdge(self: *Self, src: Node, dest: *const Node, weight: i32) !void {
    switch (self._graph_impl) {
        inline else => |*impl| try impl.addEdge(src, dest, weight),
    }
}

pub fn addDoubleEdge(self: *Self, u: *const Node, v: *const Node, weight: i32) !void {
    switch (self._graph_impl) {
        inline else => |*impl| try impl.addDoubleEdge(u, v, weight),
    }
}

pub fn edgeExists(self: *const Self, src: Node, dest: Node) !bool {
    return switch (self._graph_impl) {
        inline else => |*impl| try impl.edgeExists(src, dest),
    };
}

pub fn edgeWeight(self: *const Self, src: Node, dest: Node) !?i32 {
    return switch (self._graph_impl) {
        inline else => |*impl| try impl.edgeWeight(src, dest),
    };
}

pub fn doubleEdgeExists(self: *const Self, u: Node, v: Node) !bool {
    return switch (self._graph_impl) {
        inline else => |*impl| try impl.doubleEdgeExists(u, v),
    };
}

pub fn doubleEdgeWeight(self: *const Self, u: Node, v: Node) !?i32 {
    return switch (self._graph_impl) {
        inline else => |*impl| try impl.doubleEdgeWeight(u, v),
    };
}

pub fn removeEdge(self: *Self, src: Node, dest: Node) !void {
    switch (self._graph_impl) {
        inline else => |*impl| try impl.removeEdge(src, dest),
    }
}

pub fn removeDoubleEdge(self: *Self, u: Node, v: Node) !void {
    switch (self._graph_impl) {
        inline else => |*impl| try impl.removeDoubleEdge(u, v),
    }
}

pub fn dfsPath(self: *const Self, root: *const Node, target: ?Node) ![]*const Node {
    return switch (self._graph_impl) {
        inline else => |*impl| impl.dfsPath(root, target),
    };
}

pub fn bfsPath(self: *const Self, root: *const Node, target: ?Node) ![]*const Node {
    return switch (self._graph_impl) {
        inline else => |*impl| impl.bfsPath(root, target),
    };
}

pub fn dfsRun(self: *const Self, root: *const Node, node_fn: *const fn (node: *const Node, parent: *const Node, ctx: *anyopaque) void, ctx: *anyopaque) !void {
    switch (self._graph_impl) {
        inline else => |*impl| try impl.dfsRun(root, node_fn, ctx),
    }
}

pub fn bfsRun(self: *const Self, root: *const Node, node_fn: *const fn (node: *const Node, parent: *const Node, ctx: *anyopaque) void, ctx: *anyopaque) !void {
    switch (self._graph_impl) {
        inline else => |*impl| try impl.bfsRun(root, node_fn, ctx),
    }
}

pub fn createNode(self: *Self) Node {
    self._curr_node_id += 1;
    return .{ .id = self._curr_node_id };
}
