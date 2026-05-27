const std = @import("std");

const Node = @import("Node.zig");
const Deque = @import("../util/deque.zig").Deque(*const Node);

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
    var path_list: std.ArrayList(*const Node) = .empty;
    defer path_list.deinit(self.alloc);

    var visited: std.AutoHashMap(Node, void) = .init(self.alloc);
    defer visited.deinit();

    try path_list.ensureTotalCapacity(self.alloc, self._nodes.items.len);
    try visited.ensureTotalCapacity(@intCast(self._nodes.items.len));

    var path_ctx: PathCtx = .{ .alloc = self.alloc, .path = &path_list };
    self.dfs(root, target, pathFn, &path_ctx, &visited);

    if (target) |t| {
        if (!visited.contains(t)) {
            return error.NoPath;
        }
    }

    const path: []*const Node = try path_list.toOwnedSlice(self.alloc);
    // std.mem.reverse(*const Node, path);

    return path;
}

pub fn bfsPath(self: *const Self, root: *const Node, target: ?Node) ![]*const Node {
    var path_list: std.ArrayList(*const Node) = .empty;
    defer path_list.deinit(self.alloc);

    var path_ctx: PathCtx = .{ .alloc = self.alloc, .path = &path_list };
    self.bfs(root, target, pathFn, &path_ctx);

    const path: []*const Node = path_list.toOwnedSlice(self.alloc);
    std.mem.reverse(*const Node, path);

    return path;
}

pub fn dfsRun(self: *const Self, root: *const Node, node_fn: *const fn (node: *const Node, ctx: *anyopaque) void, ctx: *anyopaque) void {
    var visited: std.AutoHashMap(Node, {}) = .init(self.alloc);
    defer visited.deinit();

    self.dfs(root, null, node_fn, ctx, &visited);
}

pub fn bfsRun(self: *const Self, root: *const Node, node_fn: *const fn (node: *const Node, ctx: *anyopaque) void, ctx: *anyopaque) !void {
    try self.bfs(root, null, node_fn, ctx);
}

fn pathFn(node: *const Node, ctx: *anyopaque) void {
    const path_ctx: *PathCtx = @ptrCast(@alignCast(ctx));
    const path: *std.ArrayList(*const Node) = @ptrCast(path_ctx.path);

    path.appendAssumeCapacity(node);
}

const PathCtx = struct {
    alloc: std.mem.Allocator,
    path: *std.ArrayList(*const Node),
};

fn dfs(self: *const Self, root: *const Node, target: ?Node, node_fn: *const fn (node: *const Node, ctx: *anyopaque) void, ctx: *anyopaque, visited: *std.AutoHashMap(Node, void)) void {
    visited.putAssumeCapacity(root.*, {});
    node_fn(root, ctx);

    std.debug.print("Dfs running on {d}\n", .{root.id});

    if (target) |t| {
        if (root.id == t.id) return;
    }

    for (self._edges.getPtr(root.*).?.items) |neighbor| {
        if (visited.contains(neighbor.*)) continue;

        self.dfs(neighbor, target, node_fn, ctx, visited);
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

        for (self._edges.getPtr(node.*).?.items) |neighbor| {
            if (visited.contains(neighbor.*)) continue;

            deque.pushBack(self.alloc, neighbor);
        }
    }

    if (target) |t| {
        if (!visited.contains(t)) {
            return error.NoPath;
        }
    }
}
