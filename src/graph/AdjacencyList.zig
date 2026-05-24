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
    try self._nodes.append(self.alloc, node);
    try self._edges.put(self.alloc, node.*, .empty);
}

pub fn nodeExists(self: *const Self, node: Node) bool {
    return self._edges.contains(node);
}

pub fn removeNode(self: *Self, node: Node) !void {
    if (!self.nodeExists(node.*)) return error.NodeDoesNotExist;

    for (self._nodes.items, 0..) |n, i| {
        if (n.* == node) {
            _ = self._nodes.swapRemove(i);
            break;
        }
    }

    const current_list = self._edges.fetchRemove(node).?;
    current_list.value.deinit(self.alloc);

    const iter = self._edges.iterator();
    while (iter.next()) |other_list| {
        for (other_list.value_ptr.items, 0..) |n, i| {
            if (n.* == node) {
                _ = other_list.value_ptr.swapRemove(i);
                break;
            }
        }
    }
}

pub fn addEdge(self: *Self, src: Node, dest: Node) !void {
    if (!self.nodeExists(src) or !self.nodeExists(dest)) return error.NodeDoesNotExist;

    for (self._edges.get(src).?.items) |n| {
        if (n.* == dest) return error.EdgeAlreadyExists;
    }

    self._edges.get(src).?.append(self.alloc, dest);
}

pub fn addDoubleEdge(self: *Self, u: Node, v: Node) !void {
    if (!self.nodeExists(u) or !self.nodeExists(v)) return error.NodeDoesNotExist;

    for (self._edges.get(u).?.items) |n| {
        if (n.* == v) return error.EdgeAlreadyExists;
    }

    for (self._edges.get(v).?.items) |n| {
        if (n.* == u) return error.EdgeAlreadyExists;
    }

    self._edges.get(u).?.append(self.alloc, v);
    self._edges.get(v).?.append(self.alloc, u);
}

pub fn edgeExists(self: *const Self, src: Node, dest: Node) bool {
    for (self._edges.get(src).?.items) |n| {
        if (n.* == dest) return true;
    } else {
        return false;
    }
}

pub fn doubleEdgeExists(self: *const Self, u: Node, v: Node) bool {
    for (self._edges.get(u).?.items) |n| {
        if (n.* == v) break;
    } else {
        return false;
    }

    for (self._edges.get(v).?.items) |n| {
        if (n.* == u) break;
    } else {
        return false;
    }

    return true;
}

pub fn removeEdge(self: *Self, src: Node, dest: Node) !void {
    if (!self.nodeExists(src) or !self.nodeExists(dest)) return error.NodeDoesNotExist;

    for (self._edges.get(src).?.items, 0..) |n, i| {
        if (n.* == dest) _ = self._edges.get(src).?.swapRemove(i);
        break;
    } else {
        return error.EdgeDoesNotExist;
    }
}

pub fn removeDoubleEdge(self: *Self, u: Node, v: Node) !void {
    if (!self.nodeExists(u) or !self.nodeExists(v)) return error.NodeDoesNotExist;

    const u_idx: usize = undefined;
    for (self._edges.get(u).?.items, 0..) |n, i| {
        if (n.* == v) u_idx = i;
        break;
    } else {
        return error.EdgeDoesNotExist;
    }

    const v_idx: usize = undefined;
    for (self._edges.get(v).?.items, 0..) |n, i| {
        if (n.* == u) v_idx = i;
        break;
    } else {
        return error.EdgeDoesNotExist;
    }

    _ = self._edges.get(u).?.swapRemove(u_idx);
    _ = self._edges.get(v).?.swapRemove(v_idx);
}

pub fn dfsPath(self: *const Self, root: *const Node, target: ?Node) ![]*const Node {
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
    var path_list: std.ArrayList(*const Node) = .empty;
    defer path_list.deinit(self.alloc);

    const path_ctx: PathCtx = .{ .alloc = self.alloc, .path = &path_list };
    self.bfs(root, target, pathFn, &path_ctx);

    const path: []*const Node = path_list.toOwnedSlice(self.alloc);
    std.mem.reverse(*const Node, path);

    return path;
}

pub fn dfsRun(self: *const Self, root: *const Node, node_fn: *const fn (node: *const Node, ctx: *anyopaque) void, ctx: *anyopaque) !void {
    var visited: std.AutoHashMap(Node, {}) = .init(self.alloc);
    defer visited.deinit();

    self.dfs(root, null, node_fn, ctx, &visited);
}

pub fn bfsRun(self: *const Self, root: *const Node, node_fn: *const fn (node: *const Node, ctx: *anyopaque) void, ctx: *anyopaque) !void {
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

    for (self._edges.get(root.*).?.items) |neighbor| {
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

        for (self._edges.get(node.*).?.items) |neighbor| {
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
