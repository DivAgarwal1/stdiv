const std = @import("std");

const Node = @import("Node.zig");

const Self = @This();

alloc: std.mem.Allocator,
_nodes: std.ArrayList(*const Node),
_indices: std.ArrayList(?usize),
_edges: std.ArrayList(std.ArrayList(?i32)),

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
    if (self.nodeExists(node.*)) return error.NodeAlreadyExists;

    const needs_expansion = node.id >= self._indices.items.len;
    if (needs_expansion) {
        try self._indices.ensureTotalCapacity(self.alloc, @intCast(node.id + 1));
        self._indices.appendNTimesAssumeCapacity(null, @as(usize, @intCast(node.id + 1)) - self._indices.items.len);
    }
    self._indices.items[@intCast(node.id)] = self._nodes.items.len;

    try self._nodes.append(self.alloc, node);

    var new_row: std.ArrayList(?i32) = try .initCapacity(self.alloc, self._nodes.items.len - 1);
    new_row.appendNTimesAssumeCapacity(null, new_row.capacity);

    try self._edges.append(self.alloc, new_row);

    for (self._edges.items) |*list| {
        try list.append(self.alloc, null);
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

pub fn addEdge(self: *Self, src: Node, dest: *const Node, weight: i32) !void {
    if (!self.nodeExists(src) or !self.nodeExists(dest.*)) return error.NoSuchNode;

    const src_idx = self._indices.items[@intCast(src.id)].?;
    const dest_idx = self._indices.items[@intCast(dest.id)].?;

    if (self._edges.items[src_idx].items[dest_idx] != null) return error.EdgeAlreadyExists;

    self._edges.items[src_idx].items[dest_idx] = weight;
}

pub fn addDoubleEdge(self: *Self, u: *const Node, v: *const Node, weight: i32) !void {
    if (!self.nodeExists(u.*) or !self.nodeExists(v.*)) return error.NoSuchNode;

    const u_idx = self._indices.items[@intCast(u.id)].?;
    const v_idx = self._indices.items[@intCast(v.id)].?;

    if (self._edges.items[u_idx].items[v_idx] != null) return error.EdgeAlreadyExists;
    if (self._edges.items[v_idx].items[u_idx] != null) return error.EdgeAlreadyExists;

    self._edges.items[u_idx].items[v_idx] = weight;
    self._edges.items[v_idx].items[u_idx] = weight;
}

pub fn edgeExists(self: *const Self, src: Node, dest: Node) !bool {
    if (!self.nodeExists(src) or !self.nodeExists(dest)) return error.NoSuchNode;

    const src_idx = self._indices.items[@intCast(src.id)].?;
    const dest_idx = self._indices.items[@intCast(dest.id)].?;

    return self._edges.items[src_idx].items[dest_idx] != null;
}

pub fn edgeWeight(self: *const Self, src: Node, dest: Node) !?i32 {
    if (!self.nodeExists(src) or !self.nodeExists(dest)) return error.NoSuchNode;

    const src_idx = self._indices.items[@intCast(src.id)].?;
    const dest_idx = self._indices.items[@intCast(dest.id)].?;

    return self._edges.items[src_idx].items[dest_idx];
}

pub fn doubleEdgeExists(self: *const Self, u: Node, v: Node) !bool {
    if (!self.nodeExists(u) or !self.nodeExists(v)) return error.NoSuchNode;

    const u_idx = self._indices.items[@intCast(u.id)].?;
    const v_idx = self._indices.items[@intCast(v.id)].?;

    if (self._edges.items[u_idx].items[v_idx] == null) return false;
    if (self._edges.items[v_idx].items[u_idx] == null) return false;

    return true;
}

pub fn doubleEdgeWeight(self: *const Self, u: Node, v: Node) !?i32 {
    if (!self.nodeExists(u) or !self.nodeExists(v)) return error.NoSuchNode;

    const u_idx = self._indices.items[@intCast(u.id)].?;
    const v_idx = self._indices.items[@intCast(v.id)].?;

    if (self._edges.items[u_idx].items[v_idx] == null) return null;
    if (self._edges.items[v_idx].items[u_idx] == null) return null;

    return self._edges.items[u_idx].items[v_idx].?;
}

pub fn removeEdge(self: *Self, src: Node, dest: Node) !void {
    if (!self.nodeExists(src) or !self.nodeExists(dest)) return error.NoSuchNode;

    const src_idx = self._indices.items[@intCast(src.id)].?;
    const dest_idx = self._indices.items[@intCast(dest.id)].?;

    if (self._edges.items[src_idx].items[dest_idx] != null) {
        self._edges.items[src_idx].items[dest_idx] = null;
    } else {
        return error.NoSuchEdge;
    }
}

pub fn removeDoubleEdge(self: *Self, u: Node, v: Node) !void {
    if (!self.nodeExists(u) or !self.nodeExists(v)) return error.NoSuchNode;

    const u_idx = self._indices.items[@intCast(u.id)].?;
    const v_idx = self._indices.items[@intCast(v.id)].?;

    if (self._edges.items[u_idx].items[v_idx] != null and self._edges.items[v_idx].items[u_idx] != null and
        self._edges.items[u_idx].items[v_idx].? == self._edges.items[v_idx].items[u_idx].?)
    {
        self._edges.items[u_idx].items[v_idx] = null;
        self._edges.items[v_idx].items[u_idx] = null;
    } else {
        return error.NoSuchEdge;
    }
}

pub fn dfsPath(self: *const Self, root: *const Node, target: ?Node) ![]*const Node {
    if (!self.nodeExists(root.*)) return error.NoSuchNode;

    var visited: std.AutoHashMap(Node, void) = .init(self.alloc);
    defer visited.deinit();
    try visited.ensureTotalCapacity(@intCast(self._nodes.items.len));

    var parent: std.AutoHashMap(*const Node, *const Node) = .init(self.alloc);
    defer parent.deinit();
    try parent.ensureTotalCapacity(@intCast(self._nodes.items.len));

    var path_ctx: PathCtx = .{
        .alloc = self.alloc,
        .parent = &parent,
        .last_insert = root,
    };

    var collect_path: std.ArrayList(*const Node) = .empty;
    defer collect_path.deinit(self.alloc);
    try collect_path.ensureTotalCapacity(self.alloc, self._nodes.items.len);

    var collect_ctx: CollectCtx = .{
        .alloc = self.alloc,
        .path = &collect_path,
    };

    const res = if (target != null) blk: {
        break :blk self.dfs(
            root,
            root,
            target,
            pathFn,
            &path_ctx,
            &visited,
        );
    } else blk: {
        break :blk self.dfs(
            root,
            root,
            target,
            collectFn,
            &collect_ctx,
            &visited,
        );
    };

    if (target != null and !res) {
        return error.NoPath;
    }

    var path: []*const Node = undefined;

    if (target != null) {
        var path_list: std.ArrayList(*const Node) = .empty;
        var curr_node = path_ctx.last_insert;
        while (curr_node.id != root.id) {
            try path_list.append(self.alloc, curr_node);
            curr_node = parent.get(curr_node).?;
        }
        try path_list.append(self.alloc, root);
        path = try path_list.toOwnedSlice(self.alloc);
        std.mem.reverse(*const Node, path);
    } else {
        path = try collect_path.toOwnedSlice(self.alloc);
    }

    return path;
}

pub fn bfsPath(self: *const Self, root: *const Node, target: ?Node) ![]*const Node {
    if (!self.nodeExists(root.*)) return error.NoSuchNode;

    var parent: std.AutoHashMap(*const Node, *const Node) = .init(self.alloc);
    defer parent.deinit();
    try parent.ensureTotalCapacity(@intCast(self._nodes.items.len));

    var path_ctx: PathCtx = .{
        .alloc = self.alloc,
        .parent = &parent,
        .last_insert = root,
    };

    var collect_path: std.ArrayList(*const Node) = .empty;
    defer collect_path.deinit(self.alloc);
    try collect_path.ensureTotalCapacity(self.alloc, self._nodes.items.len);

    var collect_ctx: CollectCtx = .{
        .alloc = self.alloc,
        .path = &collect_path,
    };

    if (target != null) {
        try self.bfs(
            root,
            target,
            pathFn,
            &path_ctx,
        );
    } else {
        try self.bfs(
            root,
            target,
            collectFn,
            &collect_ctx,
        );
    }

    var path: []*const Node = undefined;

    if (target != null) {
        var path_list: std.ArrayList(*const Node) = .empty;
        var curr_node = path_ctx.last_insert;
        while (curr_node.id != root.id) {
            try path_list.append(self.alloc, curr_node);
            curr_node = parent.get(curr_node).?;
        }
        try path_list.append(self.alloc, root);

        path = try path_list.toOwnedSlice(self.alloc);
        std.mem.reverse(*const Node, path);
    } else {
        path = try collect_path.toOwnedSlice(self.alloc);
    }

    return path;
}

pub fn dfsRun(self: *const Self, root: *const Node, node_fn: *const fn (node: *const Node, parent: *const Node, ctx: *anyopaque) void, ctx: *anyopaque) !void {
    if (!self.nodeExists(root.*)) return error.NoSuchNode;

    var visited: std.AutoHashMap(Node, void) = .init(self.alloc);
    defer visited.deinit();
    try visited.ensureTotalCapacity(@intCast(self._nodes.items.len));

    _ = self.dfs(root, root, null, node_fn, ctx, &visited);
}

pub fn bfsRun(self: *const Self, root: *const Node, node_fn: *const fn (node: *const Node, parent: *const Node, ctx: *anyopaque) void, ctx: *anyopaque) !void {
    if (!self.nodeExists(root.*)) return error.NoSuchNode;

    try self.bfs(root, null, node_fn, ctx);
}

fn pathFn(node: *const Node, parent: *const Node, ctx: *anyopaque) void {
    const path_ctx: *PathCtx = @ptrCast(@alignCast(ctx));
    const parents: *std.AutoHashMap(*const Node, *const Node) = @ptrCast(path_ctx.parent);

    path_ctx.last_insert = node;
    parents.putAssumeCapacity(node, parent);
}

const PathCtx = struct {
    alloc: std.mem.Allocator,
    parent: *std.AutoHashMap(*const Node, *const Node),
    last_insert: *const Node,
};

fn collectFn(node: *const Node, parent: *const Node, ctx: *anyopaque) void {
    const collect_ctx: *CollectCtx = @ptrCast(@alignCast(ctx));
    const path: *std.ArrayList(*const Node) = collect_ctx.path;

    _ = parent;
    path.appendAssumeCapacity(node);
}

const CollectCtx = struct {
    alloc: std.mem.Allocator,
    path: *std.ArrayList(*const Node),
};

fn dfs(
    self: *const Self,
    node: *const Node,
    parent: *const Node,
    target: ?Node,
    node_fn: ?*const fn (node: *const Node, parent: *const Node, ctx: *anyopaque) void,
    ctx: ?*anyopaque,
    visited: *std.AutoHashMap(Node, void),
) bool {
    visited.putAssumeCapacity(node.*, {});
    if (node_fn) |func| func(node, parent, ctx.?);

    if (target) |t| {
        if (node.id == t.id) return true;
    }

    const root_idx = self._indices.items[@intCast(node.id)].?;

    for (self._edges.items[root_idx].items, 0..) |neighbor, i| {
        if (neighbor == null) continue;
        if (visited.contains(self._nodes.items[i].*)) continue;

        const res = self.dfs(self._nodes.items[i], node, target, node_fn, ctx, visited);
        if (res) return true;
    }

    return false;
}

fn bfs(
    self: *const Self,
    root: *const Node,
    target: ?Node,
    node_fn: ?*const fn (node: *const Node, parent: *const Node, ctx: *anyopaque) void,
    ctx: ?*anyopaque,
) !void {
    var deque: std.Deque(*const Node) = .empty;
    defer deque.deinit(self.alloc);

    var parent: std.AutoHashMap(Node, *const Node) = .init(self.alloc);
    defer parent.deinit();

    try parent.put(root.*, root);
    try deque.pushBack(self.alloc, root);

    while (deque.len > 0) {
        const node: *const Node = deque.popFront().?;

        if (node_fn) |func| func(node, parent.get(node.*).?, ctx.?);

        if (target) |t| {
            if (node.id == t.id) return;
        }

        const node_idx = self._indices.items[@intCast(node.id)].?;

        for (self._edges.items[node_idx].items, 0..) |neighbor, i| {
            if (neighbor == null) continue;
            if (parent.contains(self._nodes.items[i].*)) continue;

            try parent.put(self._nodes.items[i].*, node);
            try deque.pushBack(self.alloc, self._nodes.items[i]);
        }
    }

    if (target) |t| {
        if (!parent.contains(t)) {
            return error.NoPath;
        }
    }
}
