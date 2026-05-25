const std = @import("std");

const Node = @import("Node.zig");
const Deque = @import("../util/deque.zig").Deque(*const Node);

const Self = @This();

alloc: std.mem.Allocator,
_nodes: std.ArrayList(*const Node),
_indices: std.ArrayList(?usize),
_edges: std.ArrayList(std.ArrayList(bool)),

pub fn init(alloc: std.mem.Allocator) Self {
    return .{ .alloc = alloc, ._nodes = .empty, ._indices = .empty, ._edges = .empty };
}

pub fn deinit(self: *Self) void {
    self._nodes.deinit(self.alloc);

    self._indices.deinit(self.alloc);

    for (self._edges.items) |*list| {
        list.deinit(self.alloc);
    }
    self._edges.deinit(self.alloc);
}

pub fn addNode(self: *Self, node: *const Node) !void {
    const needs_expansion = node.id >= self._indices.items.len;
    if (needs_expansion) {
        try self._indices.ensureTotalCapacity(self.alloc, @intCast(node.id + 1));
        self._indices.appendNTimesAssumeCapacity(null, @as(usize, @intCast(node.id + 1)) - self._indices.items.len);
    }
    self._indices.items[@intCast(node.id)] = self._nodes.items.len;

    try self._nodes.append(self.alloc, node);

    var new_row: std.ArrayList(bool) = try .initCapacity(self.alloc, self._nodes.items.len);
    new_row.appendNTimesAssumeCapacity(false, new_row.capacity);

    try self._edges.append(self.alloc, new_row);

    for (self._edges.items) |*list| {
        try list.append(self.alloc, false);
    }
}

pub fn nodeExists(self: *const Self, node: Node) bool {
    if (node.id >= self._indices.items.len) return false;

    return self._indices.items[@intCast(node.id)] != null;
}

pub fn removeNode(self: *Self, node: Node) !void {
    if (!self.nodeExists(node)) return error.NoSuchNode;

    const node_idx = self._indices.items[@intCast(node.id)].?;

    self._indices.items[@intCast(node.id)] = null;

    var removed_list = self._edges.swapRemove(node_idx);
    removed_list.deinit(self.alloc);
    for (self._edges.items) |*list| {
        _ = list.swapRemove(node_idx);
    }

    _ = self._nodes.swapRemove(node_idx);

    if (node_idx < self._nodes.items.len) {
        self._indices.items[@intCast(self._nodes.items[node_idx].id)] = node_idx;
    }
}

pub fn addEdge(self: *Self, src: Node, dest: *const Node) !void {
    if (!self.nodeExists(src) or !self.nodeExists(dest.*)) return error.NoSuchNode;

    const src_idx = self._indices.items[@intCast(src.id)].?;
    const dest_idx = self._indices.items[@intCast(dest.id)].?;

    if (self._edges.items[src_idx].items[dest_idx]) return error.EdgeAlreadyExists;

    self._edges.items[src_idx].items[dest_idx] = true;
}

pub fn addDoubleEdge(self: *Self, u: *const Node, v: *const Node) !void {
    if (!self.nodeExists(u.*) or !self.nodeExists(v.*)) return error.NoSuchNode;

    const u_idx = self._indices.items[@intCast(u.id)].?;
    const v_idx = self._indices.items[@intCast(v.id)].?;

    if (self._edges.items[u_idx].items[v_idx]) return error.EdgeAlreadyExists;
    if (self._edges.items[v_idx].items[u_idx]) return error.EdgeAlreadyExists;

    self._edges.items[u_idx].items[v_idx] = true;
    self._edges.items[v_idx].items[u_idx] = true;
}

pub fn edgeExists(self: *const Self, src: Node, dest: Node) !bool {
    if (!self.nodeExists(src) or !self.nodeExists(dest)) return error.NoSuchNode;

    const src_idx = self._indices.items[@intCast(src.id)].?;
    const dest_idx = self._indices.items[@intCast(dest.id)].?;

    return self._edges.items[src_idx].items[dest_idx];
}

pub fn doubleEdgeExists(self: *const Self, u: Node, v: Node) !bool {
    if (!self.nodeExists(u) or !self.nodeExists(v)) return error.NoSuchNode;

    const u_idx = self._indices.items[@intCast(u.id)].?;
    const v_idx = self._indices.items[@intCast(v.id)].?;

    if (!self._edges.items[u_idx].items[v_idx]) return false;
    if (!self._edges.items[v_idx].items[u_idx]) return false;

    return true;
}

pub fn removeEdge(self: *Self, src: Node, dest: Node) !void {
    if (!self.nodeExists(src) or !self.nodeExists(dest)) return error.NoSuchNode;

    const src_idx = self._indices.items[@intCast(src.id)].?;
    const dest_idx = self._indices.items[@intCast(dest.id)].?;

    if (self._edges.items[src_idx].items[dest_idx]) {
        self._edges.items[src_idx].items[dest_idx] = false;
    } else {
        return error.NoSuchEdge;
    }
}

pub fn removeDoubleEdge(self: *Self, u: Node, v: Node) !void {
    if (!self.nodeExists(u) or !self.nodeExists(v)) return error.NoSuchNode;

    const u_idx = self._indices.items[@intCast(u.id)].?;
    const v_idx = self._indices.items[@intCast(v.id)].?;

    if (self._edges.items[u_idx].items[v_idx] and self._edges.items[v_idx].items[u_idx]) {
        self._edges.items[u_idx].items[v_idx] = false;
        self._edges.items[v_idx].items[u_idx] = false;
    } else {
        return error.NoSuchEdge;
    }
}

pub fn dfsPath(self: *const Self, root: *const Node, target: ?Node) ![]*const Node {
    if (!self.nodeExists(root.*)) return error.NoSuchNode;

    var path_list: std.ArrayList(*const Node) = .empty;
    defer path_list.deinit(self.alloc);

    var visited: std.AutoHashMap(Node, {}) = .init(self.alloc);
    defer visited.deinit();

    const path_ctx: PathCtx = .{ .alloc = self.alloc, .path = &path_list };
    self.dfs(root, target, pathFn, &path_ctx, &visited);

    if (target) |t| {
        if (!visited.contains(t)) {
            return error.NoPath;
        }
    }

    const path: []*const Node = path_list.toOwnedSlice(self.alloc);
    std.mem.reverse(*const Node, path);

    return path;
}

pub fn bfsPath(self: *const Self, root: *const Node, target: ?Node) ![]*const Node {
    if (!self.nodeExists(root.*)) return error.NoSuchNode;

    var path_list: std.ArrayList(*const Node) = .empty;
    defer path_list.deinit(self.alloc);

    const path_ctx: PathCtx = .{ .alloc = self.alloc, .path = &path_list };
    self.bfs(root, target, pathFn, &path_ctx);

    const path: []*const Node = path_list.toOwnedSlice(self.alloc);
    std.mem.reverse(*const Node, path);

    return path;
}

pub fn dfsRun(self: *const Self, root: *const Node, node_fn: *const fn (node: *const Node, ctx: *anyopaque) void, ctx: *anyopaque) !void {
    if (!self.nodeExists(root.*)) return error.NoSuchNode;

    var visited: std.AutoHashMap(Node, {}) = .init(self.alloc);
    defer visited.deinit();

    self.dfs(root, null, node_fn, ctx, &visited);
}

pub fn bfsRun(self: *const Self, root: *const Node, node_fn: *const fn (node: *const Node, ctx: *anyopaque) void, ctx: *anyopaque) !void {
    if (!self.nodeExists(root.*)) return error.NoSuchNode;

    self.bfs(root, null, node_fn, ctx);
}

fn pathFn(node: *const Node, ctx: *anyopaque) void {
    const path_ctx: *PathCtx = @ptrCast(ctx);
    const path: *std.ArrayList(*const Node) = @ptrCast(path_ctx.path);

    path.append(path_ctx.alloc, node);
}

const PathCtx = struct {
    alloc: std.mem.Allocator,
    path: *std.ArrayList(*const Node),
};

fn dfs(self: *const Self, root: *const Node, target: ?Node, node_fn: *const fn (node: *const Node, ctx: *anyopaque) void, ctx: *anyopaque, visited: *std.AutoHashMap(Node, void)) !void {
    visited.put(root.*, {});
    node_fn(root, ctx);

    if (target) |t| {
        if (*root == t) return;
    }

    const root_idx = self._indices.items[@intCast(root.id)].?;

    for (self._edges.items[root_idx].items, 0..) |neighbor, i| {
        if (!neighbor) continue;
        if (visited.contains(self._nodes.items[i].*)) continue;

        self.dfs(self._nodes.items[i], target, node_fn, ctx, visited);
    }
}

fn bfs(self: *const Self, root: *const Node, target: ?Node, node_fn: *const fn (node: *const Node, ctx: *anyopaque) void, ctx: *anyopaque) !void {
    var deque: Deque = .empty;
    defer deque.deinit(self.alloc);

    var visited: std.AutoHashMap(Node, void) = .init(self.alloc);
    defer deque.deinit(self.alloc);

    deque.pushBack(self.alloc, root);

    while (deque.len > 0) {
        const node: *const Node = deque.popFront().?;

        visited.put(node.*, {});
        node_fn(node, ctx);

        if (target) |t| {
            if (node.* == t) return;
        }

        const root_idx = self._indices.items[@intCast(node.id)].?;

        for (self._edges.items[root_idx].items, 0..) |neighbor, i| {
            if (!neighbor) continue;
            if (visited.contains(self._nodes.items[i].*)) continue;

            deque.pushBack(self.alloc, self._nodes.items[i]);
        }
    }

    if (target) |t| {
        if (!visited.contains(t)) {
            return error.NoPath;
        }
    }
}
