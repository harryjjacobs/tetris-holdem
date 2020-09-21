class_name GameData

const FILES = {
	"HIGH_SCORES": "user://high_scores.txt",
	"UNSUITED_LOOKUP": "user://unsuited_lookup.csv",
	"FLUSH_LOOKUP": "user://flush_lookup.csv"
}

static func write_high_score(score):
	var file = FileHelper.new(FILES.HIGH_SCORES, File.READ_WRITE, true)
	file.append_line(score)
	file.close()

# returns the stored highscores as an int array
# sorted ascending
static func read_high_scores():
	var file = FileHelper.new(FILES.HIGH_SCORES, File.READ)
	var scores = file.read_all_lines_typed()
	file.close()
	scores.sort()
	return scores

static func read_lookup_tables():
	var unsuited_file = FileHelper.new(FILES.UNSUITED_LOOKUP, File.READ)
	var flush_file = FileHelper.new(FILES.FLUSH_LOOKUP, File.READ)

	if !FileHelper.exists(FILES.UNSUITED_LOOKUP) || \
		!FileHelper.exists(FILES.FLUSH_LOOKUP):
		return false

	var unsuited_lookup = {}
	var flush_lookup = {}
	
	while !unsuited_file.eof_reached():
		var values = unsuited_file.get_csv_line()
		if values.size() == 2:
			unsuited_lookup[int(values[0])] = int(values[1])
	unsuited_file.close()

	while !flush_file.eof_reached():
		var values = flush_file.get_csv_line()
		if values.size() == 2:
			flush_lookup[int(values[0])] = int(values[1])
	flush_file.close()
	
	return {
		"unsuited_lookup": unsuited_lookup,
		"flush_lookup": flush_lookup
	}

static func write_lookup_tables(unsuited_lookup, flush_lookup):
	var unsuited_file = FileHelper.new(FILES.UNSUITED_LOOKUP, File.WRITE)
	var flush_file = FileHelper.new(FILES.FLUSH_LOOKUP, File.WRITE)

	for key in unsuited_lookup:
		unsuited_file.store_csv_line([str(key), str(unsuited_lookup[key])])
	unsuited_file.close()
		
	for key in flush_lookup:
		flush_file.store_csv_line([str(key), str(flush_lookup[key])])
	flush_file.close()

# wrapper around File with helper functions
class FileHelper:
	extends File
	func _init(file_name: String, mode = File.READ_WRITE, create_if_missing = false):
		match open(file_name, mode):
			ERR_FILE_NOT_FOUND:
				if create_if_missing:
					create_empty_file(file_name)
					return _init(file_name, mode, false)
					
	static func create_empty_file(file_name: String):
		var file = File.new()
		var success = file.open(file_name, File.WRITE)
		file.close()
		return success

	static func exists(file_name: String) -> bool:
		var file = File.new()
		return file.file_exists(file_name)

	func append_line(line):
		var pos = get_position()
		seek_end()
		store_line(str(line))
		seek(pos)

	func read_next_line(line_out):
		if eof_reached():
			return false
		line_out = get_line()

	func read_all_lines():
		var lines = []
		while !eof_reached():
			lines.push_back(get_line())
		return lines

	func read_all_lines_typed(skip_empty = true):
		var lines = []
		while !eof_reached():
			var line = get_line()
			if skip_empty && line.empty():
				continue
			lines.push_back(str2var(line))
		return lines
