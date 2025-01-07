import 'package:course_query/gemini_helper.dart';
import 'package:course_query/manual_form.dart';
import 'package:course_query/request_chunk.dart';
import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = SupabaseClient(
    const String.fromEnvironment("SUPABASE_URL"),
    const String.fromEnvironment("SUPABASE_KEY"),
  );

  final requestChunks = <RequestChunk>[];
  final inputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Course Query"),
        actions: [
          IconButton(
              onPressed: () async {
                final request = (await showDialog(
                        context: context,
                        useRootNavigator: false,
                        builder: (context) => const ManualFormWidget()))
                    as Map<String, dynamic>?;
                if (request != null) {
                  _submitRequest(
                      request, "Request #${requestChunks.length + 1}");
                }
              },
              icon: const Icon(Icons.edit_note))
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: requestChunks
                    .expand((e) => [
                          _requestChunkWidget(e),
                          if (e != requestChunks.last) const Divider(),
                        ])
                    .toList(),
              ),
            ),
          )),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: inputController,
              decoration: const InputDecoration(hintText: "Enter query..."),
              onSubmitted: (value) async {
                setState(() {
                  inputController.clear();
                });
                showDialog(
                    context: context,
                    useRootNavigator: false,
                    builder: (context) => const PopScope(
                          canPop: false,
                          child: AlertDialog(
                            title: Text("Asking Gemini"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                              ],
                            ),
                          ),
                        ));
                try {
                  final data = await getQueryData(value);
                  Navigator.of(context).pop();
                  await _submitRequest(data, value);
                } on Exception {
                  Navigator.of(context).pop();
                  showDialog(
                      context: context,
                      useRootNavigator: false,
                      builder: (context) => const AlertDialog(
                            title: Text("Gemini Not Available"),
                            content: Center(
                              child: Icon(Icons.not_interested),
                            ),
                          ));
                  return;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRequest(Map<String, dynamic> request, String name) async {
    final type = DataType.fromKey(request["projection_type"]);
    final response = await supabase.rpc("query_section_data", params: request);
    final list = List<Map<String, dynamic>>.from(response);
    final chunk = RequestChunk(
        name, type, list.length <= 20 ? list : list.sublist(0, 20));
    setState(() {
      requestChunks.insert(0, chunk);
    });
    _requestChunkDialog(chunk);
  }

  Widget _requestChunkWidget(RequestChunk chunk) => ElevatedButton(
        onPressed: () => _requestChunkDialog(chunk),
        child: Text(chunk.request),
      );

  void _requestChunkDialog(RequestChunk chunk) => showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => AlertDialog(
            title: Text("${chunk.dataType.name} Info"),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: chunk.response
                      .expand((e) => [
                            _mapChunkResponseEntry(e, chunk.dataType),
                            if (e != chunk.response.last) const Divider()
                          ])
                      .toList(),
                ),
              ),
            ),
          ));

  Widget _mapChunkResponseEntry(Map<String, dynamic> entry, DataType type) {
    switch (type) {
      case DataType.course:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              entry["c_code"],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(entry["c_name"]),
            Text(
              entry["c_description"],
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            Text(
              "Credits: ${entry["c_credits"]}",
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        );
      case DataType.section:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "${entry["c_code"]}-${entry["s_code"]}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (entry["m_start_time"] != null)
              Text(
                  "${entry["m_start_time"]}-${entry["m_end_time"]} ${entry["m_days"]} ${entry["m_room"] ?? ""}"),
            Text(
              "${entry["p_name"] ?? "Unknown Professor"}",
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        );
      case DataType.professor:
        return Text(
          "${entry["p_name"] ?? "Unknown Professor"}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        );
      case DataType.courseRequisites:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              entry["c_code"],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text("Prerequisites: ${entry["c_prerequisites"]}"),
            Text(
              "Co-requisites: ${entry["c_corequisites"]}",
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        );
      case DataType.none:
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: entry.entries
                .where((e) => e.key != "total_similarity" && e.value != null)
                .map((e) => Text(e.value.toString()))
                .toList());
    }
  }
}
