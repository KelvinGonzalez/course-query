enum DataType {
  course("course", "Course"),
  section("section", "Section"),
  professor("professor", "Professor"),
  courseRequisites("course_requisites", "Course Requisites"),
  none("none", "Field");

  final String key;
  final String name;

  const DataType(this.key, this.name);

  static DataType fromKey(String key) =>
      values.where((e) => e.key == key).firstOrNull ?? DataType.none;
}

class RequestChunk {
  final String request;
  final DataType dataType;
  final List<Map<String, dynamic>> response;

  const RequestChunk(this.request, this.dataType, this.response);
}
