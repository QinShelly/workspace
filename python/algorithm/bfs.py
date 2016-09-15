graph = {'A':set(['B','C']),
'B':set(['A','D','E']),
'C':set(['A','F']),
'D':set(['B']),
'E':set(['B','F']),
'F':set(['C','E'])}

def find_path_dfs(graph, start, end, path=[]):
        path = path + [start]
        if start == end:
            return path
        if not graph.has_key(start):
            return None
        for node in graph[start]:
            if node not in path:
                newpath = find_path_dfs(graph, node, end, path)
                if newpath: return newpath
        return None

def find_all_path_dfs(graph, start, end, path=[]):
	path = path + [start]
	if start == end:
		return [path]
	if not graph.has_key(start):
		return []
	paths = []
	for node in graph[start]:
		if node not in path:
			newpaths = find_all_path_dfs(graph, node, end, path)
			for newpath in newpaths:
				paths.append(newpath)
	return paths

print find_path_dfs(graph, 'A', 'D')
print find_all_path_dfs(graph,'A','D')

def dfs_iterative(graph,start):
	visited, stack = set(),[start]
	while stack:
		vertex = stack.pop()
		print vertex
		if vertex not in visited:
			visited.add(vertex)
			stack.extend(graph[vertex] - visited)
		print stack
	return visited

print dfs_iterative(graph, 'A')

def dfs_recursive(graph, start, visited=None):
	#print start
	#print visited
	if visited is None:
		visited = set()
	visited.add(start)
	for next in graph[start] - visited:
		dfs_recursive(graph,next, visited)
	return visited

print dfs_recursive(graph, 'A')

def dfs_paths_iterative(graph, start, goal):
	stack = [(start, [start])]
	while stack:
		(vertex, path) = stack.pop()
		for next in graph[vertex] - set(path):
			if next == goal:
				yield path + [next]
			else:
				stack.append((next, path + [next]))
print list(dfs_paths_iterative(graph, 'A', 'F'))

def dfs_paths_recursive(graph, start, goal, path=None):
	if path is None:
		path == [start]
	if start = goal:
		yield path
	for next in graph[start] - set(path):
		yield from dfs_paths_recursive(graph, next, goal, path + [next])
print list(dfs_paths_recursive(graph, 'A', 'F')