const std = @import("std");

const Node = @import("Node.zig");

const Self = @This();

alloc: std.mem.Allocator,
_nodes: std.ArrayList(*const Node),
/// Each source node is mapped to a list of destination nodes
_edges: std.AutoHashMapUnmanaged(Node, std.ArrayList(*const Node)),

pub fn init(alloc: std.mem.Allocator) Self {
    return .{ .alloc = alloc, ._nodes = .empty, ._edges = .empty };
}

pub fn deinit(self: *Self) void {
    self._nodes.deinit(self.alloc);

    var iter = self._edges.iterator();
    while (iter.next()) |list| {
        list.value_ptr.deinit(self.alloc);
    }
    self._edges.deinit(self.alloc);
}

pub fn addNode(self: *Self, node: *const Node) !void {
    if (self.nodeExists(node.*)) return error.NodeAlreadyExists;

    try self._nodes.append(self.alloc, node);
    try self._edges.put(self.alloc, node.*, .empty);
}

pub fn nodeExists(self: *const Self, node: Node) bool {
    return self._edges.contains(node);
}

pub fn removeNode(self: *Self, node: Node) !void {
    if (!self.nodeExists(node)) return error.NoSuchNode;

    for (self._nodes.items, 0..) |n, i| {
        if (n.id == node.id) {
            _ = self._nodes.swapRemove(i);
            break;
        }
    }

    var current_list = self._edges.fetchRemove(node).?;
    current_list.value.deinit(self.alloc);

    var iter = self._edges.iterator();
    while (iter.next()) |other_list| {
        for (other_list.value_ptr.items, 0..) |n, i| {
            if (n.id == node.id) {
                _ = other_list.value_ptr.swapRemove(i);
                break;
            }
        }
    }
}

pub fn addEdge(self: *Self, src: Node, dest: *const Node) !void {
    if (!self.nodeExists(src) or !self.nodeExists(dest.*)) return error.NoSuchNode;

    for (self._edges.getPtr(src).?.items) |n| {
        if (n.id == dest.id) return error.EdgeAlreadyExists;
    }

    try self._edges.getPtr(src).?.append(self.alloc, dest);
}

pub fn addDoubleEdge(self: *Self, u: *const Node, v: *const Node) !void {
    if (!self.nodeExists(u.*) or !self.nodeExists(v.*)) return error.NoSuchNode;

    for (self._edges.getPtr(u.*).?.items) |n| {
        if (n.id == v.id) return error.EdgeAlreadyExists;
    }

    for (self._edges.getPtr(v.*).?.items) |n| {
        if (n.id == u.id) return error.EdgeAlreadyExists;
    }

    try self._edges.getPtr(u.*).?.append(self.alloc, v);
    try self._edges.getPtr(v.*).?.append(self.alloc, u);
}

pub fn edgeExists(self: *const Self, src: Node, dest: Node) !bool {
    if (!self.nodeExists(src) or !self.nodeExists(dest)) return error.NoSuchNode;

    for (self._edges.getPtr(src).?.items) |n| {
        if (n.id == dest.id) return true;
    } else {
        return false;
    }
}

pub fn doubleEdgeExists(self: *const Self, u: Node, v: Node) !bool {
    if (!self.nodeExists(u) or !self.nodeExists(v)) return error.NoSuchNode;

    for (self._edges.getPtr(u).?.items) |n| {
        if (n.id == v.id) break;
    } else {
        return false;
    }

    for (self._edges.getPtr(v).?.items) |n| {
        if (n.id == u.id) break;
    } else {
        return false;
    }

    return true;
}

pub fn removeEdge(self: *Self, src: Node, dest: Node) !void {
    if (!self.nodeExists(src) or !self.nodeExists(dest)) return error.NoSuchNode;

    for (self._edges.getPtr(src).?.items, 0..) |n, i| {
        if (n.id == dest.id) _ = self._edges.getPtr(src).?.swapRemove(i);
        break;
    } else {
        return error.NoSuchEdge;
    }
}

pub fn removeDoubleEdge(self: *Self, u: Node, v: Node) !void {
    if (!self.nodeExists(u) or !self.nodeExists(v)) return error.NoSuchNode;

    var u_idx: usize = undefined;
    for (self._edges.getPtr(u).?.items, 0..) |n, i| {
        if (n.id == v.id) u_idx = i;
        break;
    } else {
        return error.NoSuchEdge;
    }

    var v_idx: usize = undefined;
    for (self._edges.getPtr(v).?.items, 0..) |n, i| {
        if (n.id == u.id) v_idx = i;
        break;
    } else {
        return error.NoSuchEdge;
    }

    _ = self._edges.getPtr(u).?.swapRemove(u_idx);
    _ = self._edges.getPtr(v).?.swapRemove(v_idx);
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

pub fn dfsRun(self: *const Self, root: *const Node, node_fn: *const fn (node: *const Node, ctx: *anyopaque) void, ctx: *anyopaque) void {
    var visited: std.AutoHashMap(Node, {}) = .init(self.alloc);
    defer visited.deinit();

    self.dfs(root, null, node_fn, null, ctx, &visited);
}

pub fn bfsRun(self: *const Self, root: *const Node, node_fn: *const fn (node: *const Node, ctx: *anyopaque) void, ctx: *anyopaque) !void {
    try self.bfs(root, null, node_fn, ctx);
}

fn pathFn(node: *const Node, parent: *const Node, ctx: *anyopaque) void {
    const path_ctx: *PathCtx = @ptrCast(@alignCast(ctx));
    const parents: *std.AutoHashMap(*const Node, *const Node) = path_ctx.parent;

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

    for (self._edges.getPtr(node.*).?.items) |neighbor| {
        if (visited.contains(neighbor.*)) continue;

        const res = self.dfs(neighbor, node, target, node_fn, ctx, visited);
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

        for (self._edges.getPtr(node.*).?.items) |neighbor| {
            if (parent.contains(neighbor.*)) continue;

            try parent.put(neighbor.*, node);
            try deque.pushBack(self.alloc, neighbor);
        }
    }

    if (target) |t| {
        if (!parent.contains(t)) {
            return error.NoPath;
        }
    }
}
