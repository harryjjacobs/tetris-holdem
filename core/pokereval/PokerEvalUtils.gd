class_name PokerEvalUtils

static func combinations(s, m):
	if m == 1:
		var res = []
		for a in s:
			res.push_back([a])
		return res
	if m == s.size():
		return [s]
	var res = []
	for a in combinations(m - 1, s.slice(1, s.size() - 1)):
		res.push_back(s.slice(0, 1) + a)
	return res + combinations(m, s.slice(1, s.size() - 1))
