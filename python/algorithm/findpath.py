graph = {'A':['D','C'],
'B':['C'],
'C':['D'],
'D':['A']}

def find_path(graph, start, end, path=[]):
        path = path + [start]
        if start == end:
            return path
        if not graph.has_key(start):
            return None
        for node in graph[start]:
            if node not in path:
                newpath = find_path(graph, node, end, path)
                if newpath: return newpath
        return None

def find_all_path(graph, start, end, path=[]):
	path = path + [start]
	if start == end:
		return [path]
	if not graph.has_key(start):
		return []
	paths = []
	for node in graph[start]:
		if node not in path:
			newpaths = find_all_path(graph, node, end, path)
			for newpath in newpaths:
				paths.append(newpath)
	return paths


print find_path(graph, 'A', 'D')
print find_all_path(graph,'A','D')
